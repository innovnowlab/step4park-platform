import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Se connecter")
                    .font(.title2).fontWeight(.semibold)
                Text("Connecte-toi pour sauvegarder ton profil et le réutiliser dans les prochaines sessions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handle(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let u = auth.user {
                VStack(spacing: 8) {
                    Text(u.fullName ?? "Utilisateur")
                        .font(.headline)

                    if let email = u.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        auth.signOut()
                    } label: {
                        Text("Se déconnecter")
                            .font(.subheadline).fontWeight(.semibold)
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding(18)
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
        .presentationBackground(.ultraThinMaterial)
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authz):
            guard let credential = authz.credential as? ASAuthorizationAppleIDCredential else { return }

            let userID = credential.user

            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .nilIfEmpty

            let email = credential.email

            // Apple provides name/email only on first authorization.
            let existing = auth.user
            let merged = UserProfile(
                userID: userID,
                fullName: fullName ?? existing?.fullName,
                email: email ?? existing?.email
            )

            auth.save(merged)
            dismiss()

        case .failure:
            break
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
