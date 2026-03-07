import CloudKit
import CoreLocation

extension CKRecord {
    func toParkingSpot(from userLocation: CLLocation? = nil) -> ParkingSpot? {
        guard let location = self["location"] as? CLLocation else {
            return nil
        }

        let spotLocation = CLLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        let computedDistance: Double?
        if let userLocation {
            computedDistance = userLocation.distance(from: spotLocation)
        } else {
            computedDistance = nil
        }

        let rawStatus = (self["status"] as? String ?? "active").lowercased()
        let mappedStatus: ParkingSpotStatus = (rawStatus == "occupied") ? .occupied : .available

        return ParkingSpot(
            id: recordID,
            address: self["address"] as? String ?? "",
            street: self["street"] as? String ?? "",
            city: self["city"] as? String ?? "",
            postalCode: self["postalCode"] as? String ?? "",
            country: self["country"] as? String ?? "",
            coordinate: location.coordinate,
            parkingType: ParkingType(rawValue: self["parkingType"] as? String ?? "") ?? .street,
            parkingAccess: ParkingAccess(rawValue: self["parkingAccess"] as? String ?? "") ?? .publicAccess,
            status: mappedStatus,
            capacity: self["capacity"] as? Int,
            hasCharging: self["hasCharging"] as? Bool ?? false,
            hasDisabled: self["hasDisabled"] as? Bool ?? false,
            hasCamera: self["hasCamera"] as? Bool ?? false,
            pricePerHour: self["pricePerHour"] as? Double,
            popularityScore: self["popularityScore"] as? Int ?? 0,
            reportsCount: self["reportsCount"] as? Int ?? 0,
            createdAt: self["createdAt"] as? Date ?? Date(),
            distance: computedDistance
        )
    }
}
