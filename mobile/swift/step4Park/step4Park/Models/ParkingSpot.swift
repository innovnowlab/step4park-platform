import Foundation
import MapKit
import CloudKit

struct ParkingSpot: Identifiable, Hashable {
    let id: CKRecord.ID

    var address: String
    var street: String
    var city: String
    var postalCode: String
    var country: String

    var coordinate: CLLocationCoordinate2D

    var parkingType: ParkingType
    var parkingAccess: ParkingAccess
    var status: ParkingSpotStatus

    var capacity: Int?
    var hasCharging: Bool
    var hasDisabled: Bool
    var hasCamera: Bool

    var pricePerHour: Double?

    var popularityScore: Int
    var reportsCount: Int

    var createdAt: Date
    var distance: Double?

    static func == (lhs: ParkingSpot, rhs: ParkingSpot) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id.recordName)
    }
}

enum ParkingType: String, Codable, CaseIterable {
    case street
    case publicParking
    case privateParking

    var title: String {
        switch self {
        case .street: return "Rue"
        case .publicParking: return "Public"
        case .privateParking: return "Privé"
        }
    }
}

enum ParkingAccess: String, Codable, CaseIterable {
    case publicAccess
    case residents

    var title: String {
        switch self {
        case .publicAccess: return "Public"
        case .residents: return "Résidents"
        }
    }
}
