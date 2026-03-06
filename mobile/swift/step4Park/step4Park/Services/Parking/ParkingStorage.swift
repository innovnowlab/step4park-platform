
import Foundation
import UIKit

enum ParkingStorage {
    private static let userDefaultsKey = "step4Park.savedParkingLocation"
    private static let fileManager = FileManager.default

    static func loadParking() -> SavedParkingLocation? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(SavedParkingLocation.self, from: data)
    }

    static func saveParking(_ parking: SavedParkingLocation?) {
        guard let parking else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            return
        }
        if let data = try? JSONEncoder().encode(parking) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    static func saveImageData(_ data: Data) throws -> String {
        let fileName = "parking-photo-\(UUID().uuidString).jpg"
        let url = documentsDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return fileName
    }

    static func imageData(for fileName: String?) -> Data? {
        guard let fileName else { return nil }
        let url = documentsDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: url)
    }

    static func deleteImage(named fileName: String?) {
        guard let fileName else { return }
        let url = documentsDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: url)
    }

    private static var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
