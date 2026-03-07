import Foundation
import CloudKit
import CoreLocation

@MainActor
final class ParkingCloudService {

    static let shared = ParkingCloudService()

    private let containerIdentifier = "iCloud.com.innovnowlab.step4park"

    private var container: CKContainer {
        CKContainer(identifier: containerIdentifier)
    }

    private var database: CKDatabase {
        container.publicCloudDatabase
    }

    private init() {}

    func validateConfiguration() async throws {
        do {
            let status = try await container.accountStatus()

            switch status {
            case .available:
                print("✅ CloudKit account available")
            case .noAccount:
                throw ParkingCloudServiceError.noICloudAccount
            case .restricted:
                throw ParkingCloudServiceError.accountRestricted
            case .couldNotDetermine:
                throw ParkingCloudServiceError.accountUnavailable
            case .temporarilyUnavailable:
                throw ParkingCloudServiceError.temporarilyUnavailable
            @unknown default:
                throw ParkingCloudServiceError.unknownAccountStatus
            }
        } catch {
            throw ParkingCloudServiceError.configurationFetchFailed(underlying: error)
        }
    }

    func fetchNearbyParking(
        userLocation: CLLocation,
        radius: Double = 500
    ) async throws -> [ParkingSpot] {

        try await validateConfiguration()

        let predicate = NSPredicate(
            format: "distanceToLocation:fromLocation:(location, %@) < %f",
            userLocation,
            radius
        )

        let query = CKQuery(recordType: "ParkingSpot", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let result = try await database.records(matching: query)

        let mapped = result.matchResults.compactMap { _, matchResult -> ParkingSpot? in
            guard let record = try? matchResult.get() else { return nil }
            return record.toParkingSpot(from: userLocation)
        }

        return mapped.sorted {
            ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude)
        }
    }

    func addressExists(_ address: String) async throws -> Bool {
        try await validateConfiguration()

        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let predicate = NSPredicate(format: "address == %@", trimmed)
        let query = CKQuery(recordType: "ParkingSpot", predicate: predicate)

        let result = try await database.records(matching: query, resultsLimit: 1)
        return !result.matchResults.isEmpty
    }

    func saveParkingSpot(
        coordinate: CLLocationCoordinate2D,
        address: String,
        street: String = "",
        city: String = "",
        postalCode: String = "",
        country: String = "",
        parkingType: ParkingType = .street,
        parkingAccess: ParkingAccess = .publicAccess,
        capacity: Int? = nil,
        hasCharging: Bool = false,
        hasDisabled: Bool = false,
        hasCamera: Bool = false,
        pricePerHour: Double? = nil,
        currency: String = "EUR",
        source: String = "user",
        status: String = "active"
    ) async throws {

        try await validateConfiguration()

        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else {
            throw ParkingCloudServiceError.invalidAddress
        }

        let record = CKRecord(recordType: "ParkingSpot")

        record["address"] = trimmedAddress as CKRecordValue
        record["street"] = street as CKRecordValue
        record["city"] = city as CKRecordValue
        record["postalCode"] = postalCode as CKRecordValue
        record["country"] = country as CKRecordValue
        record["location"] = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        record["parkingType"] = parkingType.rawValue as CKRecordValue
        record["parkingAccess"] = parkingAccess.rawValue as CKRecordValue

        if let capacity {
            record["capacity"] = capacity as CKRecordValue
        }

        record["hasCharging"] = hasCharging as CKRecordValue
        record["hasDisabled"] = hasDisabled as CKRecordValue
        record["hasCamera"] = hasCamera as CKRecordValue

        if let pricePerHour {
            record["pricePerHour"] = pricePerHour as CKRecordValue
        }

        record["currency"] = currency as CKRecordValue
        record["source"] = source as CKRecordValue
        record["status"] = status as CKRecordValue
        record["popularityScore"] = 0 as CKRecordValue
        record["reportsCount"] = 0 as CKRecordValue
        record["photosCount"] = 0 as CKRecordValue
        record["notesCount"] = 0 as CKRecordValue

        let now = Date()
        record["createdAt"] = now as CKRecordValue
        record["updatedAt"] = now as CKRecordValue

        _ = try await database.save(record)
    }

    @discardableResult
    func saveParkingSpotIfNeeded(
        coordinate: CLLocationCoordinate2D,
        address: String,
        street: String = "",
        city: String = "",
        postalCode: String = "",
        country: String = ""
    ) async throws -> Bool {
        let exists = try await addressExists(address)
        if exists {
            return false
        }

        try await saveParkingSpot(
            coordinate: coordinate,
            address: address,
            street: street,
            city: city,
            postalCode: postalCode,
            country: country
        )

        return true
    }

    func updateParkingSpotStatus(recordID: CKRecord.ID, status: ParkingSpotStatus) async throws {
        try await validateConfiguration()

        let record = try await database.record(for: recordID)
        record["status"] = (status == .occupied ? "occupied" : "active") as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        _ = try await database.save(record)
    }
}

enum ParkingCloudServiceError: LocalizedError {
    case noICloudAccount
    case accountRestricted
    case accountUnavailable
    case temporarilyUnavailable
    case unknownAccountStatus
    case invalidAddress
    case configurationFetchFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .noICloudAccount:
            return "Aucun compte iCloud n’est connecté sur cet appareil."
        case .accountRestricted:
            return "Le compte iCloud est restreint."
        case .accountUnavailable:
            return "Le statut du compte iCloud n’a pas pu être déterminé."
        case .temporarilyUnavailable:
            return "Le service iCloud est temporairement indisponible."
        case .unknownAccountStatus:
            return "Statut iCloud inconnu."
        case .invalidAddress:
            return "L’adresse est invalide ou vide."
        case .configurationFetchFailed(let underlying):
            return "Impossible de récupérer la configuration CloudKit. Détail : \(underlying.localizedDescription)"
        }
    }
}
