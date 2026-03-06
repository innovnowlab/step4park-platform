import CoreLocation

extension MapViewModel {

    func isCurrentlyParked(on spot: ParkingSpot) -> Bool {
        guard let savedParking else { return false }

        let saved = CLLocation(
            latitude: savedParking.latitude,
            longitude: savedParking.longitude
        )

        let selected = CLLocation(
            latitude: spot.coordinate.latitude,
            longitude: spot.coordinate.longitude
        )

        // Tolérance pour considérer que c'est la même place
        return saved.distance(from: selected) < 15
    }

    func releaseCurrentParking() {
        deleteSavedParking()
    }
}
