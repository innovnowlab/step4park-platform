import SwiftUI

@main
struct Step4ParkApp: App {
    @StateObject private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            MapScreen()
                .environmentObject(auth)
        }
    }
}
