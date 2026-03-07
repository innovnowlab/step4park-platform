import SwiftUI
import AuthenticationServices
import UIKit
import CoreLocation

struct SignInView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var refreshSettings = ParkingRefreshSettingsStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    if let user = auth.user {
                        profileSection(user: user)
                        refreshSection
                        placesSection
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
                        Text("Connecte-toi pour sauvegarder ton profil et personnaliser l’expérience Step4Park.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)

                        refreshSection

                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handle(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 0)
                }
                .padding(18)
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(24)
            .presentationBackground(.ultraThinMaterial)
        }
    }

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

    private var refreshSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actualisation des parkings")
                .font(.headline)

            Toggle("Actualisation automatique", isOn: $refreshSettings.isEnabled)

            if refreshSettings.isEnabled {
                Picker("Fréquence", selection: $refreshSettings.refreshInterval) {
                    ForEach(refreshSettings.availableIntervals, id: \.self) { interval in
                        Text(refreshSettings.intervalLabel(for: interval))
                            .tag(interval)
                    }
                }
                .pickerStyle(.menu)
            }

            Text("Quand cette option est activée, la carte recharge automatiquement les places de parking autour de toi.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var placesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lieux")
                .font(.headline)

            NavigationLink {
                ProfilePlacesHomeView()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: "tray.full.fill")
                            .foregroundStyle(.purple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lieux")
                            .font(.headline)
                        Text("Parking, restaurants et plus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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
            infoRow(title: "Nom", value: Bundle.main.appName)
            infoRow(title: "Version", value: Bundle.main.appVersion)
            infoRow(title: "Build", value: Bundle.main.appBuild)
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
            infoRow(title: "iPhone", value: UIDevice.current.model)
            infoRow(title: "iOS", value: UIDevice.current.systemVersion)
            infoRow(title: "Nom", value: UIDevice.current.name)
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
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    private func masked(_ value: String) -> String {
        guard value.count > 10 else { return value }
        let prefix = value.prefix(6)
        let suffix = value.suffix(4)
        return "\(prefix)••••\(suffix)"
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure:
            break

        case .success(let authResult):
            guard let credential = authResult.credential as? ASAuthorizationAppleIDCredential else {
                return
            }

            let formatter = PersonNameComponentsFormatter()
            let fullName = formatter.string(from: credential.fullName ?? PersonNameComponents())
            let normalizedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

            let profile = UserProfile(
                userID: credential.user,
                fullName: normalizedName.isEmpty ? auth.user?.fullName : normalizedName,
                email: credential.email ?? auth.user?.email
            )

            auth.save(profile)
        }
    }
}

private extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Step4Park"
    }

    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}
