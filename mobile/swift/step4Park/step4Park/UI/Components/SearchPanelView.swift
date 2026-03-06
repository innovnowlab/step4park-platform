
import SwiftUI

struct SearchPanelView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var showSignIn: Bool = false
    @State private var showParkingDetails: Bool = false

    @ObservedObject var vm: MapViewModel
    @Binding var sheetLevel: MapScreen.SheetLevel
    @FocusState var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            if sheetLevel == .collapsed && !isSearchFocused {
                compactSearchRow
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            } else {
                expandedSearchRow
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
            }

            if sheetLevel != .collapsed {
                Divider().opacity(0.35)

                headerRow
                    .padding(.horizontal, 16)

                if vm.results.isEmpty {
                    suggestions
                        .padding(.horizontal, 16)
                } else {
                    resultsList
                }
            }

            Spacer(minLength: 8)
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
                .environmentObject(auth)
        }
        .sheet(isPresented: $showParkingDetails) {
            ParkingDetailView(vm: vm)
        }
    }

    // MARK: - Collapsed

    private var compactSearchRow: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    sheetLevel = .medium
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isSearchFocused = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))

                    Text(vm.query.isEmpty ? "Rechercher" : vm.query)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(vm.query.isEmpty ? .secondary : .primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            )
            .buttonStyle(.plain)

            parkingButton(size: 34)
            profileButton(size: 34)
        }
    }

    // MARK: - Expanded

    private var expandedSearchRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))

                TextField("Rechercher un lieu, une adresse…", text: $vm.query)
                    .focused($isSearchFocused)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit {
                        vm.search()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            sheetLevel = .medium
                        }
                    }

                if !vm.query.isEmpty {
                    Button {
                        vm.query = ""
                        vm.clearResults()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(0.75)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )

            parkingButton(size: 40)
            profileButton(size: 40)
        }
    }

    private func parkingButton(size: CGFloat) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            vm.parkCurrentLocation()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                sheetLevel = .medium
            }
        } label: {
            Image(systemName: "car.fill")
                .font(.system(size: size == 34 ? 14 : 15, weight: .semibold))
                .frame(width: size, height: size)
        }
        .background(.ultraThinMaterial, in: Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        .shadow(radius: size == 34 ? 5 : 7, y: size == 34 ? 3 : 4)
        .buttonStyle(.plain)
        .accessibilityLabel("Se garer")
    }

    private func profileButton(size: CGFloat) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showSignIn = true
        } label: {
            Image(systemName: auth.user == nil ? "person.fill" : "person.crop.circle.fill.badge.checkmark")
                .font(.system(size: size == 34 ? 14 : 15, weight: .semibold))
                .frame(width: size, height: size)
        }
        .background(.ultraThinMaterial, in: Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        .shadow(radius: size == 34 ? 5 : 7, y: size == 34 ? 3 : 4)
        .buttonStyle(.plain)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.results.isEmpty ? "Suggestions" : "Résultats")
                    .font(.headline)

                Text(vm.results.isEmpty ? "Essaye : parking, restaurant, borne…" : "\(vm.results.count) lieu(x) trouvé(s)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                vm.search()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(10)
            }
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .buttonStyle(.plain)
        }
    }

    // MARK: - Suggestions

    private var suggestions: some View {
        VStack(spacing: 10) {
            if let parking = vm.savedParking {
                savedParkingRow(parking)
            }

            suggestionRow(icon: "car.fill", title: "Parking proche", subtitle: "Trouver un parking près de toi") {
                vm.query = "Parking"
                vm.search()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { sheetLevel = .medium }
            }
            suggestionRow(icon: "bolt.car.fill", title: "Recharge", subtitle: "Bornes de recharge électrique") {
                vm.query = "Borne de recharge"
                vm.search()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { sheetLevel = .medium }
            }
            suggestionRow(icon: "fork.knife", title: "Restaurants", subtitle: "Où manger autour de moi") {
                vm.query = "Restaurant"
                vm.search()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { sheetLevel = .medium }
            }
        }
    }

    private func savedParkingRow(_ parking: SavedParkingLocation) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                sheetLevel = .large
            }
            showParkingDetails = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "car.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Stationnement")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(parking.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func suggestionRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline).fontWeight(.semibold)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Results

    private var resultsList: some View {
        List {
            ForEach(vm.results) { place in
                Button {
                    vm.select(place)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { sheetLevel = .medium }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if !place.subtitle.isEmpty {
                            Text(place.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }
}
