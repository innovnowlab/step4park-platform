import SwiftUI
import MapKit

/// Apple Plans–like Map screen (Liquid Glass + bottom search panel)
struct MapScreen: View {
    @StateObject private var vm = MapViewModel()

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

                if let savedParking = vm.savedParking {
                    Annotation("Stationnement", coordinate: savedParking.coordinate) {
                        ZStack {
                            Circle().fill(Color.blue)
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
