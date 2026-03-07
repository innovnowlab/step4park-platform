import Foundation
import Combine
import SwiftUI

@MainActor
final class ParkingRefreshSettingsStore: ObservableObject {
    
    @AppStorage("parking_auto_refresh_enabled") var isEnabled: Bool = true
    @AppStorage("parking_auto_refresh_interval") var refreshInterval: Double = 30

    let availableIntervals: [TimeInterval] = [15, 30, 60, 120, 300]


    func intervalLabel(for interval: TimeInterval) -> String {
        switch interval {
        case 15: return "15 sec"
        case 30: return "30 sec"
        case 60: return "1 min"
        case 120: return "2 min"
        case 300: return "5 min"
        default:
            if interval < 60 {
                return "\(Int(interval)) sec"
            } else {
                return "\(Int(interval / 60)) min"
            }
        }
    }
}
