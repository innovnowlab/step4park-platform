import SwiftUI

struct ParkingSpotRowView: View {
    let spot: ParkingSpot

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.15))
                    .frame(width: 42, height: 42)

                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(spot.address.isEmpty ? "Parking" : spot.address)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(spot.parkingType.title)
                    Text("•")
                    Text(spot.parkingAccess.title)
                    if spot.hasCharging {
                        Text("•")
                        Text("Recharge")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let distance = spot.distance {
                    Text(distanceLabel(distance))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func distanceLabel(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
}