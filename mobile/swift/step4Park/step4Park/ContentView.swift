//
//  ContentView.swift
//  step4Park
//
//  Created by Anis Ziadi on 23/02/2026.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine


// MARK: - ContentView (Apple Maps-like, Search in Bottom Panel)

struct ContentView: View {
    @StateObject private var vm = AppleMapsLikeViewModel()

    private enum SheetLevel: Hashable {
        case collapsed, medium, large
    }

    @State private var sheetLevel: SheetLevel = .collapsed

    // Always-visible collapsed panel height
    private let collapsedFraction: CGFloat = 0.18

    var body: some View {
        ZStack {
            mapLayer

            // Floating controls (right side)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingControls
                }
            }
            .padding(.trailing, 14)
            .padding(.bottom, 140)
        }
       .sheet(isPresented: $vm.isSheetPresented, onDismiss: {
    vm.isSheetPresented = true
        }) {
    bottomSheet
        .presentationDetents([.fraction(collapsedFraction), .medium, .large], selection: sheetDetentBinding)
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .presentationCornerRadius(24)
        .presentationBackgroundInteraction(.enabled(upThrough: .medium)) // ✅ IMPORTANT: Map interactive
        .interactiveDismissDisabled(true)
}
        .onAppear {
            vm.requestLocation()
            vm.isSheetPresented = true
        }
        .alert("Erreur", isPresented: $vm.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage)
        }
        // When selection changes, mimic Apple Plans behavior
        .onChange(of: vm.selectedItem) { _, newValue in
            if newValue != nil {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
            }
        }
    }

    // MARK: - Map Layer

    private var mapLayer: some View {
    MapReader { proxy in
        Map(position: $vm.position, selection: $vm.selectedItem) {
            UserAnnotation()

            ForEach(vm.results, id: \.self) { item in
                Marker(item.name ?? "Place", coordinate: item.placemark.coordinate)
                    .tag(item)
            }
        }
        .mapStyle(vm.isSatellite ? .imagery(elevation: .realistic) : .standard(elevation: .realistic))
        .ignoresSafeArea()

        // ✅ Tap “dans le vide” -> collapse (sans casser pinch/zoom)
        .onTapGesture { screenPoint in
            // Laisse MapKit gérer un tap sur un marker.
            // Si après le runloop aucun marker n’est sélectionné => tap dans le vide.
            DispatchQueue.main.async {
                if vm.selectedItem == nil {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        sheetLevel = .collapsed
                    }
                }
            }
        }
    }
}

    // MARK: - Floating Controls

    private var floatingControls: some View {
        VStack(spacing: 10) {
            Button {
                vm.centerOnUser()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .collapsed
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(radius: 10, y: 6)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    vm.isSatellite.toggle()
                }
            } label: {
                Image(systemName: vm.isSatellite ? "map.fill" : "globe.europe.africa.fill")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(radius: 10, y: 6)
        }
    }

    // MARK: - Bottom Sheet (Search lives here)

    private var bottomSheet: some View {
        VStack(spacing: 10) {

            // ✅ Collapsed: Search bar only (Apple Plans vibe)
            // ✅ Medium/Large: Search bar + content
            searchBarRow
                .padding(.horizontal, 16)
                .padding(.top, 12)

            if sheetLevel != .collapsed {
                Divider().opacity(0.35)

                headerRow
                    .padding(.horizontal, 16)

                if vm.results.isEmpty {
                    suggestionsView
                        .padding(.horizontal, 16)
                } else {
                    resultsList
                }
            }

            Spacer(minLength: 10)
        }
        .onChange(of: vm.query) { _, newValue in
            // Optional: if user starts typing while collapsed, open to medium
            if sheetLevel == .collapsed, newValue.count >= 2 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
            }
        }
    }

    // MARK: - Search Bar Row

    private var searchBarRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))

                TextField("Rechercher un lieu, une adresse…", text: $vm.query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit {
                        vm.search()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            sheetLevel = .medium
                        }
                    }

                if !vm.query.isEmpty {
                    Button {
                        vm.query = ""
                        vm.results = []
                        vm.selectedItem = nil
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            sheetLevel = .collapsed
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(0.75)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    // Placeholder mic action
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )

            // Small button to expand quickly (nice UX)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = (sheetLevel == .collapsed ? .medium : .collapsed)
                }
            } label: {
                Image(systemName: sheetLevel == .collapsed ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 40, height: 40)
            }
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
            .buttonStyle(.plain)
        }
    }

    // MARK: - Header Row (only when expanded)

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.results.isEmpty ? "Suggestions" : "Résultats")
                    .font(.headline)

                Text(vm.results.isEmpty ? "Essaye : parking, restaurant, borne…" : "\(vm.results.count) lieu(x) trouvé(s)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                vm.search()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(10)
            }
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .buttonStyle(.plain)
        }
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        VStack(spacing: 10) {
            suggestionRow(icon: "car.fill", title: "Parking proche", subtitle: "Trouver un parking près de toi") {
                vm.query = "Parking"
                vm.search()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
            }
            suggestionRow(icon: "bolt.car.fill", title: "Recharge", subtitle: "Bornes de recharge électrique") {
                vm.query = "Borne de recharge"
                vm.search()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
            }
            suggestionRow(icon: "fork.knife", title: "Restaurants", subtitle: "Où manger autour de moi") {
                vm.query = "Restaurant"
                vm.search()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
            }
        }
    }

    private func suggestionRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline).fontWeight(.semibold)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            ForEach(vm.results, id: \.self) { item in
                Button {
                    vm.select(item)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        sheetLevel = .medium
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name ?? "Sans nom")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if let subtitle = item.placemark.title {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Detent binding

    private var sheetDetentBinding: Binding<PresentationDetent> {
        Binding(
            get: {
                switch sheetLevel {
                case .collapsed: return .fraction(collapsedFraction)
                case .medium:    return .medium
                case .large:     return .large
                }
            },
            set: { newValue in
                if newValue == .large {
                    sheetLevel = .large
                } else if newValue == .medium {
                    sheetLevel = .medium
                } else {
                    sheetLevel = .collapsed
                }
            }
        )
    }
}

// MARK: - ViewModel (Map + Search + Location)

final class AppleMapsLikeViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var query: String = ""
    @Published var results: [MKMapItem] = []
    @Published var selectedItem: MKMapItem?

    @Published var isSatellite: Bool = false
    @Published var isSheetPresented: Bool = false

    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    @Published var position: MapCameraPosition = .automatic

    private let locationManager = CLLocationManager()
    private var lastUserCoordinate: CLLocationCoordinate2D?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func centerOnUser() {
        guard let c = lastUserCoordinate else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            position = .region(MKCoordinateRegion(
                center: c,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    func select(_ item: MKMapItem) {
        selectedItem = item
        let c = item.placemark.coordinate
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            position = .region(MKCoordinateRegion(
                center: c,
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            ))
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func search() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Search around user if possible; otherwise Paris fallback 🇫🇷
        let center = lastUserCoordinate ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = region

        MKLocalSearch(request: request).start { [weak self] response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.show(error: error.localizedDescription)
                    return
                }
                let items = response?.mapItems ?? []
                self?.results = items

                // Optional: auto-select first result
                if let first = items.first {
                    self?.select(first)
                }
            }
        }
    }

    private func show(error: String) {
        errorMessage = error
        showError = true
    }

    // MARK: CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        lastUserCoordinate = loc.coordinate

        // Set initial camera once
        if case .automatic = position {
            position = .region(MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        show(error: error.localizedDescription)
    }
}

#Preview {
    ContentView()
}
