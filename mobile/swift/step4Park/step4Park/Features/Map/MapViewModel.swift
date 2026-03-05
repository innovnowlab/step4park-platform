import SwiftUI
import MapKit
import CoreLocation
import Combine

@MainActor
final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Search
    @Published var query: String = ""
    @Published var results: [PlaceResult] = []

    // Map selection uses a Hashable id
    @Published var selectedItemID: UUID?

    // Map camera
    @Published var position: MapCameraPosition = .automatic

    // UI
    @Published var isSatellite: Bool = false
    @Published var isSheetPresented: Bool = false

    // Errors
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    // Location
    @Published var userCoordinate: CLLocationCoordinate2D?

    // Demo parking spots (replace with your real backend/capteurs)
    @Published var demoParkingSpots: [ParkingSpot] = []

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // Small demo dataset near Paris center
        demoParkingSpots = [
            ParkingSpot(title: "S4P-001", coordinate: .init(latitude: 48.8570, longitude: 2.3524), status: .available),
            ParkingSpot(title: "S4P-002", coordinate: .init(latitude: 48.8566, longitude: 2.3530), status: .occupied),
            ParkingSpot(title: "S4P-003", coordinate: .init(latitude: 48.8562, longitude: 2.3516), status: .almostAvailable),
            ParkingSpot(title: "S4P-EV",  coordinate: .init(latitude: 48.8569, longitude: 2.3512), status: .ev)
        ]
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func centerOnUser() {
        guard let c = userCoordinate else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            position = .region(MKCoordinateRegion(
                center: c,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    func clearResults() {
        results = []
        selectedItemID = nil
    }

    func select(_ place: PlaceResult) {
        guard let c = place.coordinate else { return }
        selectedItemID = place.id
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

        let center = userCoordinate ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = region

        MKLocalSearch(request: request).start { [weak self] response, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }

                let items = response?.mapItems ?? []
                self.results = items.map { PlaceResult(item: $0) }

                if let first = self.results.first, first.coordinate != nil {
                    self.select(first)
                }
            }
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        userCoordinate = loc.coordinate

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
