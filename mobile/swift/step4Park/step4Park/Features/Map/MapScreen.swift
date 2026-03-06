import SwiftUI
import MapKit

/// Apple Plans–like Map screen (Liquid Glass + bottom search panel)
struct MapScreen: View {
    @StateObject private var vm = MapViewModel()

    enum SheetLevel: Hashable { case collapsed, medium, large }
    @State private var sheetLevel: SheetLevel = .collapsed

    @FocusState private var isSearchFocused: Bool

    // Keep a minimal visible strip (Apple Plans feel)
    private let collapsedHeight: CGFloat = 0.14

    var body: some View {
        ZStack {
            mapLayer

            // Weather + Pollution (top-left)
            WeatherPollutionWidgetView(source: vm)
                .padding(.top, 70)
                .padding(.leading, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Floating controls (top-right)
            VStack {
                HStack {
                    Spacer()
                    FloatingControlsView(
                        isSatellite: vm.isSatellite,
                        onCenter: {
                            vm.centerOnUser()
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
        }
        .sheet(isPresented: $vm.isSheetPresented, onDismiss: {
            // Keep the panel always present
            vm.isSheetPresented = true
        }) {
            SearchPanelView(
                vm: vm,
                sheetLevel: $sheetLevel,
                isSearchFocused: _isSearchFocused
            )
            .presentationDetents([.height(65), .medium, .large], selection: detentBinding)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
            .presentationBackground(.ultraThinMaterial)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium)) // keep map usable
            .interactiveDismissDisabled(true)
        }
        .onAppear {
            vm.requestLocation()
            vm.isSheetPresented = true
        }
        .onChange(of: vm.selectedItemID) { _, newValue in
            // Selecting a place should open the panel a bit
            if newValue != nil {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
            }
        }
        .alert("Erreur", isPresented: $vm.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage)
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        MapReader { _ in
            Map(position: $vm.position, selection: $vm.selectedItemID) {
                UserAnnotation()

                ForEach(vm.results) { place in
                    if let c = place.coordinate {
                        Marker(place.title, coordinate: c)
                            .tag(place.id)
                    }
                }

                // Parking demo markers (optional)
                ForEach(vm.demoParkingSpots) { spot in
                    Annotation(spot.title, coordinate: spot.coordinate) {
                        ParkingSpotMarkerView(status: spot.status)
                    }
                }
            }
            .mapStyle(vm.isSatellite ? .imagery(elevation: .realistic) : .standard(elevation: .realistic))
            .ignoresSafeArea()
        }
    }

    // MARK: - Detents

    private var detentBinding: Binding<PresentationDetent> {
        Binding(
            get: {
                switch sheetLevel {
                case .collapsed: return .fraction(collapsedHeight)
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
                    // when collapsed, keep it compact
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
