import Foundation
import CoreLocation

/// Parking spot model used on the map.
/// Note: CLLocationCoordinate2D is not Hashable/Equatable by default, so we hash/compare by `id`.
struct ParkingSpot: Identifiable, Hashable {
    let id: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D
    let status: ParkingSpotStatus

    init(id: UUID = UUID(), title: String, coordinate: CLLocationCoordinate2D, status: ParkingSpotStatus) {
        self.id = id
        self.title = title
        self.coordinate = coordinate
        self.status = status
    }

    static func == (lhs: ParkingSpot, rhs: ParkingSpot) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
