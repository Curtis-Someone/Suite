import SwiftUI
import SwiftData

/// S2a Basics → S2b Activities. Creates a Trip + its first Suitcase, seeded with
/// items from the chosen chips. Calls `onCreated` with the new trip.
struct NewSuitcaseFlow: View {
    var onCreated: (Trip) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var step: Step = ProcessInfo.processInfo.arguments.contains("-builderActivities") ? .activities : .basics
    enum Step { case basics, activities }

    // Basics
    @State private var name = ""
    @State private var countryCode = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
    @State private var tripTypeSel: Set<String> = []
    @State private var accommodation: Set<String> = []
    @State private var transport: Set<String> = []
    @State private var showingCountryPicker = false

    // Activities
    @State private var activities: Set<String> = []
    @State private var other: Set<String> = []

    private var basicsValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !countryCode.isEmpty
            && endDate >= startDate
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            switch step {
            case .basics:     basics
            case .activities: activitiesStep
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .sheet(isPresented: $showingCountryPicker) {
            CountryPicker(selectedCode: $countryCode)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                if step == .activities { withAnimation { step = .basics } } else { dismiss() }
            } label: {
                SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(Theme.Palette.border).frame(width: 40, height: 40))
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(step == .activities ? "Back" : "Close")
            Spacer()
            Dots(count: 2, active: step == .basics ? 0 : 1)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 4)

        // title lives with each step below
    }

    // MARK: Basics

    private var basics: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("New suitcase.")
                .font(.Suite.titleL).tracking(27 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    field {
                        TextField("List name", text: $name).font(.archivo(15, .medium))
                    }

                    field {
                        Button { showingCountryPicker = true } label: {
                            HStack {
                                Text(countryCode.isEmpty ? "Destination" : Countries.name(for: countryCode))
                                    .font(.archivo(15, .medium))
                                    .foregroundStyle(countryCode.isEmpty ? Theme.Palette.textTertiary : Theme.Palette.textPrimary)
                                Spacer()
                                SuiteIconView(icon: .chevronRight, size: 16)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    TripDatesCalendar(startDate: $startDate, endDate: $endDate)

                    section("Type of trip") {
                        BuilderChipGrid(chips: PackingPreset.tripTypes, singleSelect: true, selected: $tripTypeSel)
                    }
                    section("Accommodation") {
                        BuilderChipGrid(chips: PackingPreset.accommodation, selected: $accommodation)
                    }
                    section("Transportation") {
                        BuilderChipGrid(chips: PackingPreset.transportation, selected: $transport)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            footer {
                SuiteButton(title: "Continue", isEnabled: basicsValid) {
                    withAnimation { step = .activities }
                }
            }
        }
    }

    // MARK: Activities

    private var activitiesStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("New suitcase.")
                .font(.Suite.titleL).tracking(27 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section("Activities / Items") {
                        BuilderChipGrid(chips: PackingPreset.activities, selected: $activities)
                    }
                    section("Other") {
                        BuilderChipGrid(chips: PackingPreset.other, selected: $other)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            footer {
                VStack(spacing: 12) {
                    SuiteButton(title: "Create suitcase", action: create)
                    SuiteButton(title: "+ Travellers", style: .secondary, height: Theme.Size.ctaCompact) {}
                        .opacity(0.5)   // Pro — wired in batch 11
                }
            }
        }
    }

    // MARK: Create

    private func create() {
        let country = Countries.name(for: countryCode)
        let trip = Trip(
            name: name.trimmingCharacters(in: .whitespaces),
            destinationCity: "",
            destinationCountry: country,
            destinationCountryCode: countryCode,
            startDate: Calendar.current.startOfDay(for: startDate),
            endDate: Calendar.current.startOfDay(for: endDate)
        )
        let suitcase = Suitcase(name: "Packing list", trip: trip)

        let selected = accommodation.union(transport).union(activities).union(other)
        trip.tripType = tripTypeSel.first ?? ""
        trip.iconName = trip.tripType.isEmpty
            ? PackingPreset.tripIcon(for: selected)
            : (PackingPreset.icon(forTripType: trip.tripType) ?? "luggage")
        suitcase.items = PackingPreset.items(for: selected).enumerated().map { index, preset in
            let item = Item(name: preset.name, category: preset.category, quantity: preset.quantity)
            item.sortOrder = index
            return item
        }
        trip.suitcases = [suitcase]

        context.insert(trip)
        try? context.save()
        dismiss()
        onCreated(trip)
    }

    // MARK: Building blocks

    @ViewBuilder
    private func field<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 16)
            .frame(minHeight: 54)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Palette.border))
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            KickerLabel(title)
            content()
        }
    }

    @ViewBuilder
    private func footer<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 34)
            .background(Theme.Palette.ground)
    }
}
