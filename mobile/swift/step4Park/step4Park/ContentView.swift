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

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var vm = AppleMapsLikeViewModel()

    private enum SheetLevel: Hashable { case collapsed, medium, large }
    @State private var sheetLevel: SheetLevel = .collapsed

    // ✅ Focus state for search
    @FocusState private var isSearchFocused: Bool

    // Panel height when collapsed (still visible)
    private let collapsedFraction: CGFloat = 0.08

    var body: some View {
        ZStack {
            mapLayer

            // Floating controls (right)
            VStack {
                HStack {
                    Spacer()
                    floatingControls
                }
                Spacer()
            }
            .padding(.top, 70)      // espace sous la Dynamic Island / notch
            .padding(.trailing, 12) // marge droite
        }
        .sheet(isPresented: $vm.isSheetPresented, onDismiss: {
            vm.isSheetPresented = true
        }) {
            bottomSheet
                .presentationDetents([.fraction(collapsedFraction), .medium, .large], selection: sheetDetentBinding)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
                .presentationBackground(.ultraThinMaterial)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium)) // ✅ Map interactive in collapsed/medium
                .interactiveDismissDisabled(true) // ✅ never disappears
        }
        .onAppear {
            vm.requestLocation()
            vm.isSheetPresented = true
        }
        .onChange(of: vm.selectedItem) { _, newValue in
            if newValue != nil {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
            }
        }
        .alert("Erreur", isPresented: $vm.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage)
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $vm.position, selection: $vm.selectedItem) {
            UserAnnotation()

            ForEach(vm.results, id: \.self) { item in
                Marker(item.name ?? "Place", coordinate: item.placemark.coordinate)
                    .tag(item)
            }
        }
        .mapStyle(vm.isSatellite ? .imagery(elevation: .realistic) : .standard(elevation: .realistic))
        .ignoresSafeArea()
    }

    // MARK: - Floating Controls (compact)

    private var floatingControls: some View {
        VStack(spacing: 8) {
            compactFloatingButton(systemName: "location.fill") {
                vm.centerOnUser()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .collapsed
                }
            }

            compactFloatingButton(systemName: vm.isSatellite ? "map.fill" : "globe.europe.africa.fill") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    vm.isSatellite.toggle()
                }
            }
        }
    }

    @ViewBuilder
    private func compactFloatingButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 34, height: 34)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(radius: 5, y: 3)
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Sheet

    private var bottomSheet: some View {
        VStack(spacing: 10) {

            // ✅ Collapsed & NOT focused => ultra compact search pill
            // ✅ Otherwise => full search row
            if sheetLevel == .collapsed && !isSearchFocused {
                compactSearchPillRow
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            } else {
                expandedSearchRow
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
            }

            // Expanded content only when not collapsed
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

            Spacer(minLength: 8)
        }
        .onChange(of: isSearchFocused) { _, focused in
            // If user leaves focus while collapsed, keep it compact
            if !focused, sheetLevel == .collapsed {
                // no-op, view switches automatically
            }
        }
    }

    // MARK: - Compact pill (collapsed idle)

    private var compactSearchPillRow: some View {
        HStack(spacing: 10) {

            // Search pill -> tap to expand + focus
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isSearchFocused = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))

                    Text(vm.query.isEmpty ? "Rechercher" : vm.query)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(vm.query.isEmpty ? .secondary : .primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8)     // ✅ smaller
                .padding(.horizontal, 12) // ✅ smaller
            }
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            )
            .buttonStyle(.plain)

            // Profile circle next to it
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                print("Profil tapped")
            } label: {
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34) // ✅ smaller
            }
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
            .shadow(radius: 5, y: 3)
            .buttonStyle(.plain)
        }
    }

    // MARK: - Expanded search row (when active)

    private var expandedSearchRow: some View {
        HStack(spacing: 10) {

            // Full search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))

                TextField("Rechercher un lieu, une adresse…", text: $vm.query)
                    .focused($isSearchFocused)
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
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(0.75)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

            // Profile circle (normal size)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                print("Profil tapped")
            } label: {
                Image(systemName: "person.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 40, height: 40)
            }
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
            .shadow(radius: 7, y: 4)
            .buttonStyle(.plain)
        }
    }

    // MARK: - Header row (only expanded)

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
                    // When collapsing, remove focus to go back to compact pill
                    DispatchQueue.main.async { isSearchFocused = false }
                }
            }
        )
    }
}

// MARK: - ViewModel

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

        let center = lastUserCoordinate ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522) // Paris fallback 🇫🇷
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = region

        MKLocalSearch(request: request).start { [weak self] response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                    return
                }
                self?.results = response?.mapItems ?? []
                if let first = self?.results.first {
                    self?.select(first)
                }
            }
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        lastUserCoordinate = loc.coordinate

        if case .automatic = position {
            position = .region(MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

#Preview {
    ContentView()
}
