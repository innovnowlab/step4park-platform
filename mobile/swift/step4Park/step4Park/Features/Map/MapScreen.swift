import SwiftUI
import MapKit
import CoreLocation

struct MapScreen: View {
    @StateObject private var vm = MapViewModel()
    @StateObject private var nearbyParkingVM = NearbyParkingMapViewModel()

    enum SheetLevel: Hashable { case collapsed, medium, large }
    @State private var sheetLevel: SheetLevel = .collapsed

    @FocusState private var isSearchFocused: Bool
    @State private var latestTouchPoint: CGPoint?

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
                        },
                        onRefresh: {
                            nearbyParkingVM.forceReload(userCoordinate: vm.userCoordinate)
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
            nearbyParkingVM.forceReload(userCoordinate: vm.userCoordinate)
        }
        .onChange(of: vm.selectedItemID) { _, newValue in
            if newValue != nil {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
            }
        }
        .onChange(of: nearbyParkingVM.selectedSpot?.id) { _, newValue in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                sheetLevel = (newValue != nil) ? .large : .medium
            }
        }
        .onChange(of: vm.showAddPublicParkingPrompt) { _, isShown in
            if isShown {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
            }
        }
        .onChange(of: vm.mapRefreshTrigger) { _, _ in
            nearbyParkingVM.forceReload(userCoordinate: vm.userCoordinate)
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
        MapReader { proxy in
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
                                isSelected: nearbyParkingVM.selectedSpot?.id == spot.id,
                                isParked: vm.isCurrentlyParked(on: spot),
                                isOccupied: spot.status == .occupied && !vm.isCurrentlyParked(on: spot)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let dropped = vm.pendingDroppedPinCoordinate {
                    Annotation("Nouvelle place", coordinate: dropped) {
                        ZStack(alignment: .bottom) {
                            Circle()
                                .fill(Color.blue.opacity(0.92))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Image(systemName: "plus")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 12, weight: .bold))
                                }

                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color.blue.opacity(0.92))
                                .frame(width: 8, height: 10)
                                .offset(y: 6)
                        }
                        .shadow(radius: 6, y: 3)
                    }
                }
            }
            .mapStyle(vm.isSatellite ? .imagery(elevation: .realistic) : .standard(elevation: .realistic))
            .ignoresSafeArea()
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        latestTouchPoint = value.location
                    }
                    .onEnded { _ in
                        latestTouchPoint = nil
                    }
            )
            .simultaneousGesture(
                TapGesture().onEnded {
                    if nearbyParkingVM.selectedSpot != nil {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            nearbyParkingVM.clearSelection()
                        }
                    }
                }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.6)
                    .onEnded { _ in
                        guard let point = latestTouchPoint,
                              let coordinate = proxy.convert(point, from: .local) else { return }

                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        vm.proposeParkingAtCoordinate(coordinate)
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
