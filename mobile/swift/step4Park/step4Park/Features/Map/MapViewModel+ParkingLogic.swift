import CoreLocation
import CloudKit

extension MapViewModel {

    func isCurrentlyParked(on spot: ParkingSpot) -> Bool {
        guard let savedParking else { return false }

        if let parkedPublicSpotRecordName = savedParking.parkedPublicSpotRecordName,
           parkedPublicSpotRecordName == spot.id.recordName {
            return true
        }

        let saved = CLLocation(latitude: savedParking.latitude, longitude: savedParking.longitude)
        let selected = CLLocation(latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude)

        return saved.distance(from: selected) < 3
    }

    func park(onPublicSpot spot: ParkingSpot) {
        let parking = SavedParkingLocation(
            latitude: spot.coordinate.latitude,
            longitude: spot.coordinate.longitude,
            address: spot.address.isEmpty ? "Parking" : spot.address,
            parkedPublicSpotRecordName: spot.id.recordName
        )

        savedParking = parking
        ParkingStorage.saveParking(parking)
        triggerMapRefresh()

        Task {
            do {
                try await ParkingCloudService.shared.updateParkingSpotStatus(
                    recordID: spot.id,
                    status: .occupied
                )

                await MainActor.run {
                    triggerMapRefreshWithRetry()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Impossible de mettre à jour le statut dans CloudKit : \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    func releaseCurrentParking() {
        let parkedRecordName = savedParking?.parkedPublicSpotRecordName

        deleteSavedParking()

        guard let parkedRecordName else { return }

        Task {
            do {
                try await ParkingCloudService.shared.updateParkingSpotStatus(
                    recordID: CKRecord.ID(recordName: parkedRecordName),
                    status: .available
                )

                await MainActor.run {
                    triggerMapRefreshWithRetry()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Impossible de libérer la place dans CloudKit : \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}
