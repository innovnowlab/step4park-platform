import SwiftUI
import CoreLocation

struct WeatherPollutionWidgetView: View {
    @ObservedObject var source: MapViewModel
    @StateObject private var vm = WeatherPollutionViewModel()
    private struct CoordinateKey: Equatable {
        let lat: Double
        let lon: Double
    }

    var body: some View {
        HStack(spacing: 10) {
            // Weather
            HStack(spacing: 6) {
                Image(systemName: vm.weatherSymbol)
                    .font(.system(size: 14, weight: .semibold))
                Text(vm.temperatureText)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            )

            // Pollution
            HStack(spacing: 6) {
                Circle()
                    .fill(vm.aqiColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))

                Text("AQI \(vm.aqiText)")
                    .font(.system(size: 14, weight: .semibold))

                Text(vm.aqiLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            )
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(radius: 8, y: 4)
        .onAppear { vm.start() }
        // CLLocationCoordinate2D is not Equatable: observe a tuple
        .onChange(of: coordinateKey) { _, _ in
            guard let coord = source.userCoordinate else { return }
            vm.updateCoordinate(coord)
        }
    }

    private var coordinateKey: CoordinateKey? {
        guard let c = source.userCoordinate else { return nil }
        return CoordinateKey(lat: c.latitude, lon: c.longitude)
    }
}
