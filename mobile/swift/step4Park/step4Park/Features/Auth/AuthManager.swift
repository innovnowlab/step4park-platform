import Foundation
import Combine
import AuthenticationServices

struct UserProfile: Codable, Equatable {
    var userID: String
    var fullName: String?
    var email: String?
}

@MainActor
final class AuthManager: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    @Published private(set) var user: UserProfile?

    private let service = "com.step4park.auth"
    private let account = "apple_user_profile"

    init() {
        // All stored properties are initialized above. Now perform post-init work.
        restore()
        Task { [weak self] in
            await self?.refreshCredentialState()
        }
    }

    func restore() {
        do {
            guard let data = try KeychainStore.load(service: service, account: account) else { return }
            user = try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            // ignore restore errors
        }
    }

    func save(_ profile: UserProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            try KeychainStore.save(data, service: service, account: account)
            user = profile
        } catch {
            // handle if needed
        }
    }

    func signOut() {
        KeychainStore.delete(service: service, account: account)
        user = nil
    }

    /// Recommended: verify the Apple credential state at app start.
    func refreshCredentialState() async {
        guard let userID = user?.userID else { return }
        do {
            let provider = ASAuthorizationAppleIDProvider()
            let state = try await provider.credentialState(forUserID: userID)
            if state != .authorized {
                signOut()
            }
        } catch {
            // If we can't verify, keep the user; you can choose to signOut() if you prefer.
        }
    }
}

