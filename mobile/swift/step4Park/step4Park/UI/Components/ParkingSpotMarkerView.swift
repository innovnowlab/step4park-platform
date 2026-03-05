import SwiftUI

enum ParkingSpotStatus: String, Codable {
    case available
    case almostAvailable
    case occupied
    case ev
}

struct ParkingSpotMarkerView: View {
    let status: ParkingSpotStatus

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                )

            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))

            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .opacity(0.85)
                .offset(x: 0, y: 16)
        }
        .frame(width: 34, height: 46)
        .shadow(radius: 6, y: 3)
    }

    private var symbol: String {
        switch status {
        case .available: return "car.fill"
        case .almostAvailable: return "timer"
        case .occupied: return "xmark"
        case .ev: return "bolt.car.fill"
        }
    }

    private var color: Color {
        switch status {
        case .available: return .green
        case .almostAvailable: return .yellow
        case .occupied: return .red
        case .ev: return .blue
        }
    }
}
