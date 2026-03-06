
    import SwiftUI
    import PhotosUI
    import MapKit

    struct ParkingDetailView: View {
        @ObservedObject var vm: MapViewModel
        @Environment(\.dismiss) private var dismiss
        @State private var selectedPhotoItem: PhotosPickerItem?

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let parking = vm.savedParking {
                            actionButtons
                            detailsSection(for: parking)
                            deleteButton
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if let parking = vm.savedParking {
                            ShareLink(item: parking.shareText) {
                                toolbarCircle(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        if let parking = vm.savedParking {
                            VStack(spacing: 2) {
                                Text("Stationnement")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(parking.address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            toolbarCircle(systemName: "xmark")
                        }
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await vm.saveParkingPhoto(data)
                    }
                }
            }
        }

        private var actionButtons: some View {
            HStack(spacing: 12) {
                Button {
                    vm.openDirectionsToSavedParking()
                } label: {
                    actionPill(title: "Itinéraire", systemName: "arrow.turn.up.right", style: .filled)
                }
                .buttonStyle(.plain)

                Button {
                    vm.moveSavedParkingToCurrentPosition()
                } label: {
                    actionPill(title: "Déplacer", systemName: "mappin.and.ellipse", style: .outlined)
                }
                .buttonStyle(.plain)
            }
        }

        private func detailsSection(for parking: SavedParkingLocation) -> some View {
            VStack(alignment: .leading, spacing: 14) {
                Text("Détails")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 0) {
                    detailRow(title: "Temps écoulé", value: vm.elapsedParkingText)

                    Divider().opacity(0.2)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        TextEditor(text: Binding(
                            get: { vm.savedParking?.note ?? "" },
                            set: { vm.updateParkingNote($0) }
                        ))
                        .frame(minHeight: 96)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(20)

                    Divider().opacity(0.2)

                    HStack(alignment: .top, spacing: 14) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            VStack(spacing: 10) {
                                Image(systemName: "camera")
                                    .font(.system(size: 26, weight: .semibold))
                                Text("Ajouter\nune photo")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                            }
                            .foregroundStyle(.secondary)
                            .frame(width: 110, height: 110)
                            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        if let image = vm.savedParkingImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .frame(maxWidth: .infinity)
                                .frame(height: 110)
                                .overlay {
                                    Text("Aucune photo")
                                        .foregroundStyle(.secondary)
                                }
                        }
                    }
                    .padding(20)
                }
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }

        private func detailRow(title: String, value: String) -> some View {
            HStack(alignment: .top) {
                Text(title)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.title3)
                    .multilineTextAlignment(.trailing)
            }
            .padding(20)
        }

        private var deleteButton: some View {
            Button(role: .destructive) {
                vm.deleteSavedParking()
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                    Text("Supprimer le lieu de stationnement")
                        .fontWeight(.semibold)
                }
                .font(.title3)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
            }
            .buttonStyle(.plain)
            .background(Color.red.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .foregroundStyle(.red)
        }

        private var emptyState: some View {
            VStack(spacing: 12) {
                Image(systemName: "car.circle")
                    .font(.system(size: 42))
                Text("Aucun stationnement enregistré")
                    .font(.headline)
                Text("Utilise le bouton Se garer pour mémoriser ta position actuelle.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 280)
        }

        private func toolbarCircle(systemName: String) -> some View {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.06), in: Circle())
        }

        private enum ActionPillStyle { case filled, outlined }

        private func actionPill(title: String, systemName: String, style: ActionPillStyle) -> some View {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .foregroundStyle(style == .filled ? Color.white : Color.blue)
            .background(backgroundView(for: style))
        }

        @ViewBuilder
        private func backgroundView(for style: ActionPillStyle) -> some View {
            switch style {
            case .filled:
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.accentColor)
            case .outlined:
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.blue.opacity(0.16))
            }
        }
    }
