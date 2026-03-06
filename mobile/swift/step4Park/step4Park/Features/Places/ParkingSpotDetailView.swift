import SwiftUI
import MapKit

struct ParkingSpotDetailView: View {
    let spot: ParkingSpot
    @Environment(\.dismiss) private var dismiss

    @State private var position: MapCameraPosition

    init(spot: ParkingSpot) {
        self.spot = spot
        self._position = State(initialValue: .region(
            MKCoordinateRegion(
                center: spot.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Map(position: $position) {
                    Annotation(spot.address.isEmpty ? "Parking" : spot.address, coordinate: spot.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 22, height: 22)

                            Image(systemName: "car.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text(spot.address.isEmpty ? "Parking" : spot.address)
                        .font(.title3)
                        .fontWeight(.semibold)

                    infoRow("Type", spot.parkingType.title)
                    infoRow("Accès", spot.parkingAccess.title)

                    if let capacity = spot.capacity {
                        infoRow("Capacité", "\(capacity) places")
                    }

                    if let pricePerHour = spot.pricePerHour {
                        infoRow("Prix", String(format: "%.2f €/h", pricePerHour))
                    }

                    infoRow("Recharge", spot.hasCharging ? "Oui" : "Non")
                    infoRow("PMR", spot.hasDisabled ? "Oui" : "Non")
                    infoRow("Surveillance", spot.hasCamera ? "Oui" : "Non")

                    if let distance = spot.distance {
                        let value = distance < 1000 ? "\(Int(distance)) m" : String(format: "%.1f km", distance / 1000)
                        infoRow("Distance", value)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding(16)
            .navigationTitle("Détail du parking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}