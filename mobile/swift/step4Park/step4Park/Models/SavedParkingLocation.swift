import Foundation
import CoreLocation

struct SavedParkingLocation: Codable, Identifiable, Equatable {
    let id: UUID
    var latitude: Double
    var longitude: Double
    var address: String
    var createdAt: Date
    var note: String
    var photoFilename: String?
    var parkedPublicSpotRecordName: String?

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        address: String,
        createdAt: Date = Date(),
        note: String = "",
        photoFilename: String? = nil,
        parkedPublicSpotRecordName: String? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.createdAt = createdAt
        self.note = note
        self.photoFilename = photoFilename
        self.parkedPublicSpotRecordName = parkedPublicSpotRecordName
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var shareText: String {
        "Mon stationnement Step4Park \(address) https://maps.apple.com/?ll=\(latitude),\(longitude)"
    }
}
