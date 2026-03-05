import Foundation
import CoreLocation
import WeatherKit

final class WeatherKitProvider {
    static let shared = WeatherKitProvider()
    private init() {}

    private let service = WeatherService.shared

    /// Fetch current weather using WeatherKit.
    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherSnapshot {
        let location = CLLocation(latitude: lat, longitude: lon)
        let weather = try await service.weather(for: location)
        let current = weather.currentWeather

        let tempC = current.temperature.converted(to: .celsius).value
        let symbol = current.symbolName

        return WeatherSnapshot(tempC: tempC, symbol: symbol)
    }
}
