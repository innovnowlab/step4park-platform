import SwiftUI
import CoreLocation

struct ParkingPlacesView: View {

    @StateObject private var vm = PlacesViewModel()
    let userLocation: CLLocation

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Chargement des parkings…")
                } else if let errorMessage = vm.errorMessage {
                    ContentUnavailableView(
                        "Erreur CloudKit",
                        systemImage: "icloud.slash",
                        description: Text(errorMessage)
                    )
                } else if vm.nearbyParking.isEmpty {
                    ContentUnavailableView(
                        "Aucun parking",
                        systemImage: "car.circle",
                        description: Text("Aucune place de parking publique trouvée près de ta position.")
                    )
                } else {
                    List(vm.nearbyParking) { spot in
                        Button {
                            vm.selectedSpot = spot
                        } label: {
                            ParkingSpotRowView(spot: spot)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Parking")
            .onAppear {
                vm.loadNearbyParking(location: userLocation)
            }
            .sheet(item: $vm.selectedSpot) { spot in
                ParkingSpotDetailView(spot: spot)
            }
        }
    }
}

#Preview {
    ParkingPlacesView(
        userLocation: CLLocation(latitude: 48.8566, longitude: 2.3522)
    )
}