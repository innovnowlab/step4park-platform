import Foundation

final class AirQualityProvider {
    static let shared = AirQualityProvider()
    private init() {}

    /// Uses Open-Meteo Air Quality (no API key) and converts PM2.5 to an AQI-like number for visual marking.
    func fetchAQI(lat: Double, lon: Double) async throws -> Int {
        let urlStr = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(lat)&longitude=\(lon)&current=pm2_5&timezone=auto"
        let url = URL(string: urlStr)!
        let (data, _) = try await URLSession.shared.data(from: url)

        struct Resp: Decodable {
            struct Current: Decodable { let pm2_5: Double }
            let current: Current
        }

        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        let pm25 = decoded.current.pm2_5

        // Simple MVP mapping (visual). Replace with an official AQI formula if needed.
        let aqi = Int(min(max(pm25 * 4.0, 0), 300))
        return aqi
    }
}
