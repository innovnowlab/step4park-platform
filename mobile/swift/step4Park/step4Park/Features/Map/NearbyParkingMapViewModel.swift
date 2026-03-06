import Foundation
import CoreLocation
import Combine

@MainActor
final class NearbyParkingMapViewModel: ObservableObject {
    @Published var spots: [ParkingSpot] = []
    @Published var selectedSpot: ParkingSpot?
    @Published var isLoading: Bool = false

    private var lastLoadedLocation: CLLocation?
    private let reloadDistanceThreshold: CLLocationDistance = 120
    private let searchRadius: CLLocationDistance = 700

    func loadIfNeeded(userCoordinate: CLLocationCoordinate2D?) {
        guard let userCoordinate else { return }

        let location = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)

        if let lastLoadedLocation,
           location.distance(from: lastLoadedLocation) < reloadDistanceThreshold,
           !spots.isEmpty {
            return
        }

        lastLoadedLocation = location
        loadNearbyParking(from: location)
    }

    func forceReload(userCoordinate: CLLocationCoordinate2D?) {
        guard let userCoordinate else { return }
        let location = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        lastLoadedLocation = location
        loadNearbyParking(from: location)
    }

    private func loadNearbyParking(from location: CLLocation) {
        isLoading = true

        Task {
            defer { isLoading = false }

            do {
                spots = try await ParkingCloudService.shared.fetchNearbyParking(
                    userLocation: location,
                    radius: searchRadius
                )
            } catch {
                print("CloudKit nearby parking error:", error.localizedDescription)
            }
        }
    }
}
