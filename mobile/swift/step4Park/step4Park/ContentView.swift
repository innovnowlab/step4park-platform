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

// MARK: - Root Apple Maps-like View

struct ContentView: View {
    @StateObject private var vm = AppleMapsLikeViewModel()

    var body: some View {
        ZStack {
            // 1) Map full screen
            Map(position: $vm.position, selection: $vm.selectedItem) {
                // User location
                UserAnnotation()

                // Search results pins
                ForEach(vm.results, id: \.self) { item in
                    Marker(item.name ?? "Place", coordinate: item.placemark.coordinate)
                        .tag(item)
                }
            }
            .mapControls {
                // keep minimal; we build our own buttons
            }
            .mapStyle(vm.isSatellite ? .imagery(elevation: .realistic) : .standard(elevation: .realistic))
            .ignoresSafeArea()

            // 2) Top overlay (header)
            VStack(spacing: 12) {
                headerBar
                Spacer()
            }
            .padding(.top, 8)
            .padding(.horizontal, 14)

            // 3) Floating controls (right side)
            VStack(spacing: 10) {
                Spacer()
                HStack {
                    Spacer()
                    floatingControls
                }
            }
            .padding(.trailing, 14)
            .padding(.bottom, 140) // keep above bottom sheet
        }
        .safeAreaInset(edge: .bottom) {
            bottomSheet
                .frame(maxWidth: .infinity)
                .frame(height: 300) // tu peux ajuster
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
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
    }

    // MARK: - Header (Apple Maps-like)

    private var headerBar: some View {
        HStack(spacing: 10) {
            // Search “Liquid Glass”
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))

                TextField("Rechercher des lieux", text: $vm.query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit { vm.search() }

                if !vm.query.isEmpty {
                    Button {
                        vm.query = ""
                        vm.results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(0.75)
                    }
                    .buttonStyle(.plain)
                }

                // “Voice” button like Apple Maps
                Button {
                    // placeholder
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(radius: 10, y: 6)

            // Profile/Account button (right)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)
        }
    }

    // MARK: - Floating controls

    private var floatingControls: some View {
        VStack(spacing: 10) {
            // Center on user location
            Button {
                vm.centerOnUser()
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

            // Toggle map style
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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

    // MARK: - Bottom sheet

    private var bottomSheet: some View {
        VStack(spacing: 14) {
            // Mini handle + title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.results.isEmpty ? "Suggestions" : "Résultats")
                        .font(.headline)
                    Text(vm.results.isEmpty ? "Cherche une adresse, un lieu, une ville…" : "\(vm.results.count) lieu(x) trouvé(s)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Divider().opacity(0.4)

            // List
            if vm.results.isEmpty {
                suggestionsView
            } else {
                resultsList
            }

            Spacer(minLength: 10)
        }
    }

    private var suggestionsView: some View {
        VStack(spacing: 10) {
            suggestionRow(icon: "car.fill", title: "Parking proche", subtitle: "Trouver un parking près de toi") {
                vm.query = "Parking"
                vm.search()
            }
            suggestionRow(icon: "bolt.car.fill", title: "Recharge", subtitle: "Bornes de recharge électrique") {
                vm.query = "Borne de recharge"
                vm.search()
            }
            suggestionRow(icon: "fork.knife", title: "Restaurants", subtitle: "Où manger autour de moi") {
                vm.query = "Restaurant"
                vm.search()
            }
        }
        .padding(.horizontal, 16)
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

    private var resultsList: some View {
        List {
            ForEach(vm.results, id: \.self) { item in
                Button {
                    vm.select(item)
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

        // Search around user if possible; otherwise default region
        let center = lastUserCoordinate ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522) // Paris fallback 🇫🇷
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.show(error: error.localizedDescription)
                    return
                }
                let items = response?.mapItems ?? []
                self?.results = items
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
