import SwiftUI

struct PublicParkingMapMarkerView: View {
    let spot: ParkingSpot
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "car.fill")
                    .font(.system(size: 11, weight: .bold))

                if isSelected {
                    Text(shortTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, isSelected ? 12 : 10)
            .padding(.vertical, 9)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.blue)
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? .clear : .white.opacity(0.18), lineWidth: 1)
            )
            .shadow(radius: isSelected ? 10 : 6, y: isSelected ? 5 : 3)

            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(isSelected ? Color.blue : Color.white.opacity(0.92))
                .rotationEffect(.degrees(180))
                .offset(y: -2)
                .shadow(radius: isSelected ? 6 : 3, y: 2)
        }
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
    }

    private var shortTitle: String {
        if !spot.street.isEmpty { return spot.street }
        if !spot.city.isEmpty { return spot.city }
        if !spot.address.isEmpty { return spot.address }
        return "Parking"
    }
}
