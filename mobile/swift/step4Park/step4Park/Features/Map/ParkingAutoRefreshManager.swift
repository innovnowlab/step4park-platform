import Foundation
import Combine
import UIKit

@MainActor
final class ParkingAutoRefreshManager: ObservableObject {
    
    private var timer: Timer?

    func start(
        isEnabled: Bool,
        interval: TimeInterval,
        action: @escaping () -> Void
    ) {
        stop()

        guard isEnabled else { return }

        let scheduled = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            guard UIApplication.shared.applicationState == .active else { return }
            action()
        }
        timer = scheduled
        RunLoop.main.add(scheduled, forMode: .common)
    }

    func restart(
        isEnabled: Bool,
        interval: TimeInterval,
        action: @escaping () -> Void
    ) {
        start(isEnabled: isEnabled, interval: interval, action: action)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

