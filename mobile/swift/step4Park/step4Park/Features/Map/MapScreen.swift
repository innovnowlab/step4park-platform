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
        }
        .sheet(isPresented: $vm.isSheetPresented, onDismiss: {
            vm.isSheetPresented = true
        }) {
            SearchPanelView(
                vm: vm,
                nearbyParkingVM: nearbyParkingVM,
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
        .onChange(of: nearbyParkingVM.selectedSpot?.id) { _, newValue in
            if newValue != nil {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                    sheetLevel = .large
                }
            }
        }
        .onChange(of: nearbyParkingVM.selectedSpot?.id) { _, newValue in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                    sheetLevel = (newValue != nil) ? .large : .medium
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
                                sheetLevel = .large
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
