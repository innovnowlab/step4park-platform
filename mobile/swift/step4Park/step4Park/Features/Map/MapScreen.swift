import SwiftUI
import MapKit
import CoreLocation

/// Apple Plans–like Map screen (Liquid Glass + bottom search panel + public parking on map)
struct MapScreen: View {
    @StateObject private var vm = MapViewModel()
    @StateObject private var nearbyParkingVM = NearbyParkingMapViewModel()

    enum SheetLevel: Hashable { case collapsed, medium, large }
    @State private var sheetLevel: SheetLevel = .collapsed

    @FocusState private var isSearchFocused: Bool
    @State private var detailSpot: ParkingSpot?

    private let collapsedPanelHeight: CGFloat = 96

    var body: some View {
        ZStack {
            mapLayer

            WeatherPollutionWidgetView(source: vm)
                .padding(.top, 70)
                .padding(.leading, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack {
                HStack {
                    Spacer()
                    FloatingControlsView(
                        isSatellite: vm.isSatellite,
                        onCenter: {
                            vm.centerOnUser()
                            nearbyParkingVM.forceReload(userCoordinate: vm.userCoordinate)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                sheetLevel = .collapsed
                                isSearchFocused = false
                            }
                        },
                        onToggleStyle: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                vm.isSatellite.toggle()
                            }
                        }
                    )
                }
                Spacer()
            }
            .padding(.top, 70)
            .padding(.trailing, 12)

            if nearbyParkingVM.isLoading {
                ProgressView()
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 126)
            }

            if let selectedSpot = nearbyParkingVM.selectedSpot {
                parkingSelectionCard(selectedSpot)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 120)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $vm.isSheetPresented, onDismiss: {
            vm.isSheetPresented = true
        }) {
            SearchPanelView(
                vm: vm,
                sheetLevel: $sheetLevel,
                isSearchFocused: _isSearchFocused
            )
            .presentationDetents([.height(collapsedPanelHeight), .medium, .large], selection: detentBinding)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
            .presentationBackground(.ultraThinMaterial)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled(true)
        }
        .sheet(item: $detailSpot) { spot in
            ParkingSpotDetailView(spot: spot)
        }
        .onAppear {
            vm.requestLocation()
            vm.isSheetPresented = true
        }
        .onChange(of: vm.selectedItemID) { _, newValue in
            if newValue != nil {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
            }
        }
        .onChange(of: vm.userCoordinate?.latitude) { _, _ in
            nearbyParkingVM.loadIfNeeded(userCoordinate: vm.userCoordinate)
        }
        .onChange(of: vm.userCoordinate?.longitude) { _, _ in
            nearbyParkingVM.loadIfNeeded(userCoordinate: vm.userCoordinate)
        }
        .alert("Erreur", isPresented: $vm.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage)
        }
    }

    private var mapLayer: some View {
        MapReader { _ in
            Map(position: $vm.position, selection: $vm.selectedItemID) {
                UserAnnotation()

                ForEach(vm.results) { place in
                    if let coordinate = place.coordinate {
                        Marker(place.title, coordinate: coordinate)
                            .tag(place.id)
                    }
                }

                ForEach(nearbyParkingVM.spots) { spot in
                    Annotation(spot.address.isEmpty ? "Parking" : spot.address, coordinate: spot.coordinate) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                nearbyParkingVM.select(spot)
                            }
                        } label: {
                            PublicParkingMapMarkerView(
                                spot: spot,
                                isSelected: nearbyParkingVM.selectedSpot?.id == spot.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let savedParking = vm.savedParking {
                    Annotation("Stationnement", coordinate: savedParking.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 18, height: 18)

                            Image(systemName: "car.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 2))
                        .shadow(radius: 5, y: 3)
                    }
                }
            }
            .mapStyle(vm.isSatellite ? .imagery(elevation: .realistic) : .standard(elevation: .realistic))
            .ignoresSafeArea()
            .simultaneousGesture(
                TapGesture().onEnded {
                    if nearbyParkingVM.selectedSpot != nil {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            nearbyParkingVM.clearSelection()
                        }
                    }
                }
            )
        }
    }

    private func parkingSelectionCard(_ spot: ParkingSpot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.blue.opacity(0.14))
                        .frame(width: 44, height: 44)

                    Image(systemName: "car.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.address.isEmpty ? "Parking" : spot.address)
                        .font(.headline)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(spot.parkingType.title)
                        Text("•")
                        Text(spot.parkingAccess.title)

                        if let distance = spot.distance {
                            Text("•")
                            Text(distance < 1000
                                 ? "\(Int(distance)) m"
                                 : String(format: "%.1f km", distance / 1000))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        nearbyParkingVM.clearSelection()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 6) {
                if let capacity = spot.capacity {
                    infoLine(title: "Capacité", value: "\(capacity) places")
                }

                if spot.hasCharging || spot.hasDisabled || spot.hasCamera {
                    HStack(spacing: 10) {
                        if spot.hasCharging {
                            tag("Recharge", systemName: "bolt.fill")
                        }
                        if spot.hasDisabled {
                            tag("PMR", systemName: "figure.roll")
                        }
                        if spot.hasCamera {
                            tag("Surveillé", systemName: "camera.fill")
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    parkOnPublicSpot(spot)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                        Text("Me garer ici")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(.white)

                Button {
                    detailSpot = spot
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                        Text("Détails")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                )
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(radius: 12, y: 6)
    }

    private func parkOnPublicSpot(_ spot: ParkingSpot) {
        let parking = SavedParkingLocation(
            latitude: spot.coordinate.latitude,
            longitude: spot.coordinate.longitude,
            address: spot.address.isEmpty ? "Parking" : spot.address
        )

        vm.savedParking = parking
        ParkingStorage.saveParking(parking)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            nearbyParkingVM.clearSelection()
        }
    }

    private func tag(_ title: String, systemName: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
            Text(title)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule())
    }

    private func infoLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    private var detentBinding: Binding<PresentationDetent> {
        Binding(
            get: {
                switch sheetLevel {
                case .collapsed: return .height(collapsedPanelHeight)
                case .medium: return .medium
                case .large: return .large
                }
            },
            set: { newValue in
                if newValue == .large {
                    sheetLevel = .large
                } else if newValue == .medium {
                    sheetLevel = .medium
                } else {
                    sheetLevel = .collapsed
                    DispatchQueue.main.async {
                        isSearchFocused = false
                    }
                }
            }
        )
    }
}

#Preview {
    MapScreen()
}
