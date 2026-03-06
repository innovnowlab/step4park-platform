import SwiftUI

struct FloatingControlsView: View {
    let isSatellite: Bool
    let onCenter: () -> Void
    let onToggleStyle: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            compactButton(systemName: "location.fill", action: onCenter)
            compactButton(systemName: isSatellite ? "map.fill" : "globe.europe.africa.fill", action: onToggleStyle)
            compactButton(systemName: "arrow.clockwise", action: onRefresh)
        }
    }

    private func compactButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 34, height: 34)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(radius: 5, y: 3)
        .buttonStyle(.plain)
    }
}
