import SwiftUI
import AuthenticationServices
import UIKit

struct SignInView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {

            header

            if let user = auth.user {
                // ✅ Connected state (profile dashboard)
                profileSection(user: user)
                appSection
                deviceSection

                Button(role: .destructive) {
                    auth.signOut()
                } label: {
                    Text("Se déconnecter")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                )
                .padding(.top, 6)

            } else {
                // ✅ Not connected state (Sign in with Apple)
                Text("Connecte-toi pour sauvegarder ton profil et personnaliser l’expérience Step4Park.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handle(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 8)

                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .presentationBackground(.ultraThinMaterial)
    }

    // MARK: - UI Blocks

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(auth.user == nil ? "Connexion" : "Profil")
                    .font(.title2).fontWeight(.semibold)
                Text(auth.user == nil ? "Sign in with Apple" : "Compte connecté")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .opacity(0.75)
            }
            .buttonStyle(.plain)
        }
    }

    private func profileSection(user: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(.thinMaterial)
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.fullName ?? "Utilisateur")
                        .font(.headline)
                    if let email = user.email, !email.isEmpty {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Email non disponible (Apple ne le fournit qu’à la 1ère connexion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            Divider().opacity(0.25)

            infoRow(title: "Apple User ID", value: masked(user.userID))
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Application")
                .font(.headline)

            infoRow(title: "Nom", value: appName)
            infoRow(title: "Version", value: "\(appVersion) (\(appBuild))")
            infoRow(title: "Bundle ID", value: bundleID)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var deviceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appareil")
                .font(.headline)

            infoRow(title: "iPhone", value: deviceModel)
            infoRow(title: "iOS", value: systemVersion)
            infoRow(title: "Langue", value: localeIdentifier)
            infoRow(title: "Timezone", value: timeZoneIdentifier)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }

    // MARK: - Sign in handler

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authz):
            guard let credential = authz.credential as? ASAuthorizationAppleIDCredential else { return }

            let userID = credential.user

            // Apple donne fullName/email uniquement à la 1ère autorisation
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .nilIfEmpty

            let email = credential.email

            // Merge avec l'existant (garde les anciennes valeurs si Apple renvoie nil)
            let existing = auth.user
            let merged = UserProfile(
                userID: userID,
                fullName: fullName ?? existing?.fullName,
                email: email ?? existing?.email
            )

            auth.save(merged)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

        case .failure:
            // tu peux ajouter une alerte si tu veux
            break
        }
    }

    // MARK: - Helpers (App/Device)

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Step4Park"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private var bundleID: String {
        Bundle.main.bundleIdentifier ?? "—"
    }

    private var systemVersion: String {
        UIDevice.current.systemName + " " + UIDevice.current.systemVersion
    }

    private var deviceModel: String {
        UIDevice.current.model
    }

    private var localeIdentifier: String {
        Locale.current.identifier
    }

    private var timeZoneIdentifier: String {
        TimeZone.current.identifier
    }

    private func masked(_ s: String) -> String {
        guard s.count > 10 else { return s }
        let start = s.prefix(6)
        let end = s.suffix(4)
        return "\(start)…\(end)"
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}