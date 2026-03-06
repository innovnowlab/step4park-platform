import SwiftUI

struct ProfilePlacesHomeView: View {
    @StateObject private var locationVM = ProfilePlacesLocationViewModel()

    var body: some View {
        List {
            NavigationLink {
                if let location = locationVM.currentLocation {
                    ParkingPlacesView(userLocation: location)
                } else if locationVM.isLoading {
                    ProgressView("Localisation…")
                } else {
                    ContentUnavailableView(
                        "Position indisponible",
                        systemImage: "location.slash",
                        description: Text("Active la localisation pour voir les places proches de toi.")
                    )
                }
            } label: {
                placeRow(
                    icon: "car.fill",
                    iconColor: .blue,
                    title: "Parking",
                    subtitle: "Places de parking proches"
                )
            }

            placeRow(
                icon: "fork.knife",
                iconColor: .orange,
                title: "Restaurants",
                subtitle: "Bientôt disponible"
            )
            .opacity(0.55)
            .allowsHitTesting(false)

            placeRow(
                icon: "cup.and.saucer.fill",
                iconColor: .green,
                title: "Cafés",
                subtitle: "Bientôt disponible"
            )
            .opacity(0.55)
            .allowsHitTesting(false)
        }
        .navigationTitle("Lieux")
        .listStyle(.insetGrouped)
        .onAppear {
            locationVM.requestLocationIfNeeded()
        }
    }

    private func placeRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.16))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ProfilePlacesHomeView()
    }
}
