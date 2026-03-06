import Foundation
import CoreLocation
import Combine

@MainActor
final class PlacesViewModel: ObservableObject {

    @Published var nearbyParking: [ParkingSpot] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedSpot: ParkingSpot?

    func loadNearbyParking(location: CLLocation, radius: Double = 500) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await ParkingCloudService.shared.fetchNearbyParking(
                    userLocation: location,
                    radius: radius
                )
                nearbyParking = result
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    func saveIfNeeded(
        coordinate: CLLocationCoordinate2D,
        address: String,
        street: String = "",
        city: String = "",
        postalCode: String = "",
        country: String = ""
    ) async throws -> Bool {
        let exists = try await ParkingCloudService.shared.addressExists(address)
        if exists { return false }

        try await ParkingCloudService.shared.saveParkingSpot(
            coordinate: coordinate,
            address: address,
            street: street,
            city: city,
            postalCode: postalCode,
            country: country
        )
        return true
    }
}
