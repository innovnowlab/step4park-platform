import SwiftUI
import CoreLocation
import Combine

@MainActor
final class WeatherPollutionViewModel: ObservableObject {
    @Published var temperatureText: String = "--°"
    @Published var weatherSymbol: String = "cloud.sun.fill"

    @Published var aqiText: String = "--"
    @Published var aqiLabel: String = "—"
    @Published var aqiColor: Color = .gray

    private var lastCoord: CLLocationCoordinate2D?
    private var refreshTask: Task<Void, Never>?

    func start() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                if let c = self.lastCoord {
                    await self.refresh(for: c)
                }
                try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
            }
        }
    }

    func updateCoordinate(_ coord: CLLocationCoordinate2D) {
        lastCoord = coord
        Task { await refresh(for: coord) }
    }

    private func refresh(for coord: CLLocationCoordinate2D) async {
        do {
            let w = try await WeatherKitProvider.shared.fetchWeather(lat: coord.latitude, lon: coord.longitude)
            temperatureText = "\(Int(round(w.tempC)))°"
            weatherSymbol = w.symbol
        } catch {
            // keep last values
        }

        do {
            let aqi = try await AirQualityProvider.shared.fetchAQI(lat: coord.latitude, lon: coord.longitude)
            applyAQI(aqi)
        } catch {
            // keep last values
        }
    }

    private func applyAQI(_ aqi: Int) {
        aqiText = "\(aqi)"

        switch aqi {
        case ..<51:
            aqiLabel = "Bon"
            aqiColor = .green
        case 51..<101:
            aqiLabel = "Moyen"
            aqiColor = .yellow
        case 101..<151:
            aqiLabel = "Sensibles"
            aqiColor = .orange
        case 151..<201:
            aqiLabel = "Mauvais"
            aqiColor = .red
        default:
            aqiLabel = "Très mauvais"
            aqiColor = .purple
        }
    }
}
