import SwiftUI

struct PublicParkingMapMarkerView: View {
    let spot: ParkingSpot
    let isSelected: Bool
    let isParked: Bool

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: isParked ? "car.fill" : "car")
                    .font(.system(size: 11, weight: .bold))

                if isSelected {
                    Text(shortTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, isSelected ? 12 : 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .shadow(radius: shadowRadius, y: shadowYOffset)

            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(pointerColor)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
                .shadow(radius: isHighlighted ? 6 : 3, y: 2)
        }
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isParked)
    }

    private var shortTitle: String {
        if !spot.street.isEmpty { return spot.street }
        if !spot.city.isEmpty { return spot.city }
        if !spot.address.isEmpty { return spot.address }
        return "Parking"
    }

    private var isHighlighted: Bool {
        isSelected || isParked
    }

    private var foregroundColor: Color {
        isHighlighted ? .white : .primary
    }

    private var backgroundColor: Color {
        isHighlighted ? .blue : .white.opacity(0.96)
    }

    private var borderColor: Color {
        isHighlighted ? .clear : .white.opacity(0.18)
    }

    private var borderWidth: CGFloat {
        isHighlighted ? 0 : 1
    }

    private var shadowRadius: CGFloat {
        isHighlighted ? 10 : 6
    }

    private var shadowYOffset: CGFloat {
        isHighlighted ? 5 : 3
    }

    private var pointerColor: Color {
        isHighlighted ? .blue : Color.white.opacity(0.92)
    }
}
