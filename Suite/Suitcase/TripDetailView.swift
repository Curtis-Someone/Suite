import SwiftUI
import SwiftData

/// P2 · Trip detail — a trip's home screen: identity, quick stats, and the bags
/// packed for it. Suitcases are their own objects now; this is where you add one
/// and open its checklist, and where a trip is marked complete.
///
/// The handoff's "Photos" strip and multi-city breakdown aren't in the data
/// model (single `destinationCity`, no photo store) — omitted here, consistent
/// with the earlier P2 deferral.
struct TripDetailView: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private let entitlements = Entitlements.shared

    @State private var showingBuilder = false
    @State private var showingEdit = false
    @State private var showingTravelerPicker = false
    @State private var upsell: UpsellMoment?
    @State private var confirmDeleteTrip = false
    @State private var suitcaseToDelete: Suitcase?

    private var isDone: Bool { trip.isArchived }

    /// Raw span in days, matching the handoff ("04–10 Nov" reads as "6 days").
    private var days: Int {
        Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
    }

    private var suitcases: [Suitcase] {
        trip.suitcases.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    statTiles
                    travelersSection
                    suitcasesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 40)
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .keepsSwipeBack()
        .fullScreenCover(isPresented: $showingBuilder) {
            NewSuitcaseFlow(trip: trip) { _ in }
        }
        .fullScreenCover(isPresented: $showingEdit) {
            EditTripFlow(trip: trip)
        }
        .sheet(isPresented: $showingTravelerPicker) {
            TravelerPickerSheet(trip: trip).presentationDetents([.medium, .large])
        }
        .sheet(item: $upsell) { UpsellSheet(moment: $0) }
        .alert("Delete this trip?", isPresented: $confirmDeleteTrip) {
            Button("Delete", role: .destructive) { deleteTrip() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes “\(trip.name)” and its suitcases. This can't be undone.")
        }
        .alert("Delete this suitcase?",
               isPresented: Binding(get: { suitcaseToDelete != nil },
                                    set: { if !$0 { suitcaseToDelete = nil } }),
               presenting: suitcaseToDelete) { bag in
            Button("Delete", role: .destructive) { deleteSuitcase(bag) }
            Button("Cancel", role: .cancel) {}
        } message: { bag in
            Text("This deletes “\(bag.name)” and everything packed in it. This can't be undone.")
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().strokeBorder(Theme.Palette.border))
                }
                .accessibilityLabel("Back")
                Spacer()
                Button { confirmDeleteTrip = true } label: {
                    SuiteIconView(icon: .trash, size: 19, color: Theme.Palette.danger)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("Delete trip")
                Menu {
                    Button("Edit trip details") { showingEdit = true }
                    if isDone {
                        Button("Reopen trip") { reopen() }
                    } else {
                        Button("Mark trip complete") { markComplete() }
                    }
                } label: {
                    SuiteIconView(icon: .ellipsis, size: 20, color: Theme.Palette.textPrimary)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("Trip options")
            }

            if isDone {
                HStack(spacing: 7) {
                    SuiteIconView(icon: .check, size: 13, color: Theme.Palette.onAccent)
                    Text("Trip completed")
                        .font(.jetBrainsMono(11, .bold)).tracking(0.8).textCase(.uppercase)
                        .foregroundStyle(Theme.Palette.onAccent)
                }
                .padding(.horizontal, 11).frame(height: 26)
                .background(Theme.Palette.accent, in: Capsule())
                .padding(.top, 14)
            }

            Text(trip.destinationCountry.isEmpty ? "Trip" : "Trip · \(trip.destinationCountry)")
                .font(.jetBrainsMono(11)).tracking(1.4).textCase(.uppercase)
                .foregroundStyle(Theme.Palette.accent)
                .padding(.top, 14)

            Text(trip.name)
                .font(.Suite.title).tracking(26 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.top, 8)

            HStack(spacing: 12) {
                Text(PackingChecklistView.dateRange(trip))
                    .font(.jetBrainsMono(12))
                    .foregroundStyle(Theme.Palette.textSecondary)
                Rectangle().fill(Theme.Palette.track).frame(width: 1, height: 13)
                Text("\(days) day\(days == 1 ? "" : "s")")
                    .font(.jetBrainsMono(12, .medium))
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(Theme.Palette.surface)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Palette.border).frame(height: 1) }
    }

    // MARK: Stat tiles (handoff P2: dark block, amber numeral, mono caption).

    private var statTiles: some View {
        HStack(spacing: 10) {
            statTile("\(trip.destinationCountry.isEmpty ? 0 : 1)", "country")
            statTile("\(trip.destinationCity.isEmpty ? 0 : 1)", trip.destinationCity.isEmpty ? "cities" : "city")
            statTile("\(days)", "days")
        }
    }

    private func statTile(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.archivo(26, .bold)).tracking(26 * -0.02)
                .foregroundStyle(Theme.Palette.accent)
            Text(caption)
                .font(.jetBrainsMono(10)).tracking(1.2).textCase(.uppercase)
                .foregroundStyle(Theme.Palette.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.Palette.statTile, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
    }

    // MARK: Travelers (Pro — collaborators)

    @ViewBuilder
    private var travelersSection: some View {
        let travelers = trip.travelers.sorted { $0.name < $1.name }
        VStack(alignment: .leading, spacing: 12) {
            KickerLabel("Travelers")

            ForEach(travelers, id: \.persistentModelID) { traveler in
                HStack(spacing: 12) {
                    FriendAvatar(name: traveler.name, size: 36)
                    Text(traveler.name)
                        .font(.archivo(15, .semibold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Spacer()
                    if !isDone {
                        Button { removeTraveler(traveler) } label: {
                            SuiteIconView(icon: .close, size: 15, color: Theme.Palette.textTertiary)
                                .frame(width: 32, height: 32)
                        }
                        .accessibilityLabel("Remove \(traveler.name)")
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).strokeBorder(Theme.Palette.border))
            }

            if !isDone {
                Button { addTravelerTapped() } label: {
                    HStack(spacing: 10) {
                        SuiteIconView(icon: .plus, size: 16,
                                      color: entitlements.isPro ? Theme.Palette.textSecondary : Theme.Palette.textTertiary)
                        Text("Add a traveler")
                            .font(.archivo(15, .semibold))
                            .foregroundStyle(Theme.Palette.textSecondary)
                        Spacer()
                        if !entitlements.isPro {
                            Text("Pro").font(.jetBrainsMono(11, .bold)).foregroundStyle(Theme.Palette.accent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.chip)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                            .foregroundStyle(Theme.Palette.border)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Suitcases

    @ViewBuilder
    private var suitcasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KickerLabel("Suitcases")

            if suitcases.isEmpty {
                emptyBags
            } else {
                ForEach(suitcases) { bag in
                    NavigationLink(value: bag) { bagRow(bag) }
                        .buttonStyle(.suitePress)
                        .contextMenu {
                            Button { showingEdit = true } label: {
                                Label("Edit trip details", systemImage: "pencil")
                            }
                            Button(role: .destructive) { suitcaseToDelete = bag } label: {
                                Label("Delete suitcase", systemImage: "trash")
                            }
                        }
                }
                if !isDone { addBagRow }
            }
        }
    }

    private func bagRow(_ bag: Suitcase) -> some View {
        let packed = bag.items.filter(\.isPacked).count
        let total = bag.items.count
        return HStack(spacing: 14) {
            LucideIcon(name: "luggage", size: 22,
                       color: isDone ? Theme.Palette.textSecondary : Theme.Palette.onAccent)
                .frame(width: 48, height: 48)
                .background(isDone ? Theme.Palette.track : Theme.Palette.accent,
                           in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
            VStack(alignment: .leading, spacing: 7) {
                Text(bag.name)
                    .font(.archivo(15, .bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(1)
                SuiteProgressBar(value: isDone ? 1 : bag.progress, height: 6)
                Text(total == 0 ? "No items yet"
                     : (isDone ? "\(packed)/\(total) packed"
                        : "\(Int((bag.progress * 100).rounded()))% ready · \(packed)/\(total)"))
                    .font(.jetBrainsMono(11))
                    .foregroundStyle(Theme.Palette.textTertiary)
            }
            Spacer(minLength: 6)
            SuiteIconView(icon: .chevronRight, size: 16)
        }
        .padding(16)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).strokeBorder(Theme.Palette.border))
    }

    private var addBagRow: some View {
        Button { addSuitcaseTapped() } label: {
            HStack(spacing: 10) {
                SuiteIconView(icon: .plus, size: 18, color: Theme.Palette.textSecondary)
                Text("New suitcase")
                    .font(.archivo(15, .semibold))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .foregroundStyle(Theme.Palette.border)
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyBags: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isDone ? "No packing list for this trip." : "No suitcase yet.")
                .font(.Suite.bodyStrong)
                .foregroundStyle(Theme.Palette.textPrimary)
            if !isDone {
                Text("Add a bag to start a packing list — Suite fills it from your trip type and the weather.")
                    .font(.Suite.bodyS)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Theme.Palette.textSecondary)
                SuiteButton(title: "New suitcase", showsLeadingPlus: true) { addSuitcaseTapped() }
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: Actions

    private func addSuitcaseTapped() {
        switch PackingGate.canAddSuitcase(to: trip, isPro: entitlements.isPro) {
        case .allowed:             showingBuilder = true
        case .blocked(let reason): upsell = reason
        }
    }

    private func addTravelerTapped() {
        switch PackingGate.canAddTraveler(isPro: entitlements.isPro) {
        case .allowed:             showingTravelerPicker = true
        case .blocked(let reason): upsell = reason
        }
    }

    private func removeTraveler(_ traveler: Traveler) {
        context.delete(traveler)
        try? context.save()
    }

    private func reopen() {
        trip.isArchived = false
        try? context.save()
    }

    private func deleteTrip() {
        dismiss()
        context.delete(trip)
        try? context.save()
    }

    private func deleteSuitcase(_ bag: Suitcase) {
        context.delete(bag)
        try? context.save()
    }

    private func markComplete() {
        trip.isArchived = true
        context.insert(VisitedPlace(
            countryName: trip.destinationCountry,
            countryCode: trip.destinationCountryCode,
            cityName: trip.destinationCity,
            sourceTripID: trip.tripID
        ))
        try? context.save()
        let visits = (try? context.fetch(FetchDescriptor<VisitedPlace>())) ?? []
        RewardEngine.tripComplete(trip: trip, visits: visits)
    }
}
