
import SwiftUI
import MapKit
import CoreLocation
import UIKit
import Combine

@MainActor
final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Search
    @Published var query: String = ""
    @Published var results: [PlaceResult] = []
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

    // Saved parking
    @Published var savedParking: SavedParkingLocation?
    @Published var savedParkingImage: UIImage?

    // Demo parking spots (replace with backend / capteurs)
    @Published var demoParkingSpots: [ParkingSpot] = []

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        loadSavedParking()

        demoParkingSpots = [
            ParkingSpot(title: "S4P-001", coordinate: .init(latitude: 48.8570, longitude: 2.3524), status: .available),
            ParkingSpot(title: "S4P-002", coordinate: .init(latitude: 48.8566, longitude: 2.3530), status: .occupied),
            ParkingSpot(title: "S4P-003", coordinate: .init(latitude: 48.8562, longitude: 2.3516), status: .almostAvailable),
            ParkingSpot(title: "S4P-EV", coordinate: .init(latitude: 48.8569, longitude: 2.3512), status: .ev)
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

    // MARK: - Parking

    func parkCurrentLocation() {
        guard let current = userCoordinate else {
            errorMessage = "Position actuelle indisponible."
            showError = true
            return
        }

        Task {
            let address = await reverseGeocodeAddress(for: current)
            let parking = SavedParkingLocation(
                latitude: current.latitude,
                longitude: current.longitude,
                address: address
            )
            saveParking(parking)
        }
    }

    func moveSavedParkingToCurrentPosition() {
        guard let current = userCoordinate else {
            errorMessage = "Position actuelle indisponible."
            showError = true
            return
        }

        Task {
            let address = await reverseGeocodeAddress(for: current)
            var parking = savedParking ?? SavedParkingLocation(
                latitude: current.latitude,
                longitude: current.longitude,
                address: address
            )
            parking.latitude = current.latitude
            parking.longitude = current.longitude
            parking.address = address
            saveParking(parking)
        }
    }

    func updateParkingNote(_ note: String) {
        guard var parking = savedParking else { return }
        parking.note = note
        saveParking(parking, reloadImage: false)
    }

    func saveParkingPhoto(_ data: Data) async {
        guard var parking = savedParking else { return }
        ParkingStorage.deleteImage(named: parking.photoFilename)

        guard let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.82) else {
            errorMessage = "Impossible de lire la photo sélectionnée."
            showError = true
            return
        }

        do {
            let fileName = try ParkingStorage.saveImageData(jpeg)
            parking.photoFilename = fileName
            saveParking(parking)
        } catch {
            errorMessage = "Impossible d'enregistrer la photo."
            showError = true
        }
    }

    func deleteSavedParking() {
        ParkingStorage.deleteImage(named: savedParking?.photoFilename)
        savedParking = nil
        savedParkingImage = nil
        ParkingStorage.saveParking(nil)
    }

    func openDirectionsToSavedParking() {
        guard let savedParking else { return }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: savedParking.coordinate))
        item.name = "Stationnement"
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    var elapsedParkingText: String {
        guard let createdAt = savedParking?.createdAt else { return "—" }
        let components = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: createdAt, to: Date())

        if let month = components.month, month > 0 {
            return month == 1 ? "depuis 1 mois" : "depuis \(month) mois"
        }
        if let day = components.day, day > 0 {
            return day == 1 ? "depuis 1 jour" : "depuis \(day) jours"
        }
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "depuis 1 heure" : "depuis \(hour) heures"
        }

        let minute = max(components.minute ?? 0, 1)
        return minute == 1 ? "depuis 1 minute" : "depuis \(minute) minutes"
    }

    private func loadSavedParking() {
        savedParking = ParkingStorage.loadParking()
        loadSavedParkingImage()
    }

    private func saveParking(_ parking: SavedParkingLocation, reloadImage: Bool = true) {
        savedParking = parking
        ParkingStorage.saveParking(parking)
        if reloadImage {
            loadSavedParkingImage()
        }
    }

    private func loadSavedParkingImage() {
        if let data = ParkingStorage.imageData(for: savedParking?.photoFilename),
           let image = UIImage(data: data) {
            savedParkingImage = image
        } else {
            savedParkingImage = nil
        }
    }

    private func reverseGeocodeAddress(for coordinate: CLLocationCoordinate2D) async -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let parts = [placemark.name, placemark.locality, placemark.administrativeArea]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                if !parts.isEmpty {
                    return parts.joined(separator: ", ")
                }
            }
        } catch {
            // fallback below
        }

        return "\(String(format: "%.5f", coordinate.latitude)), \(String(format: "%.5f", coordinate.longitude))"
    }

    // MARK: - CLLocationManagerDelegate

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
