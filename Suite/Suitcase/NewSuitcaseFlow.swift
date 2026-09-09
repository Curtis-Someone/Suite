import SwiftUI
import SwiftData

/// S2a Basics → S2b Activities. Adds a `Suitcase` to an existing `Trip`, seeded
/// with items from the chosen chips. The trip's own details (name, destination,
/// dates, type) are set when the trip is created — this flow is bag-only.
/// Calls `onCreated` with the new suitcase.
struct NewSuitcaseFlow: View {
    var trip: Trip
    var onCreated: (Suitcase) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var step: Step = ProcessInfo.processInfo.arguments.contains("-builderActivities") ? .activities : .basics
    enum Step { case basics, activities }

    // Basics
    @State private var name = ""
    @State private var accommodation: Set<String> = []
    @State private var transport: Set<String> = []

    // Activities
    @State private var activities: Set<String> = []
    @State private var other: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            header
            switch step {
            case .basics:     basics
            case .activities: activitiesStep
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                if step == .activities { withAnimation { step = .basics } } else { dismiss() }
            } label: {
                SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Theme.Palette.border))
            }
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
                        TextField("Bag name (e.g. Carry-on)", text: $name).font(.archivo(15, .medium))
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
                SuiteButton(title: "Continue") {
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
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let suitcase = Suitcase(name: trimmed.isEmpty ? "Packing list" : trimmed, trip: trip)

        let selected = accommodation.union(transport).union(activities).union(other)
        suitcase.items = PackingPreset.items(for: selected).enumerated().map { index, preset in
            let item = Item(name: preset.name, category: preset.category, quantity: preset.quantity)
            item.sortOrder = index
            return item
        }

        // If the trip never got a distinctive icon, let the first bag's chips
        // pick one — never overwrite a type-derived icon.
        if trip.iconName.isEmpty || trip.iconName == "luggage" {
            let derived = PackingPreset.tripIcon(for: selected)
            if derived != "luggage" { trip.iconName = derived }
        }

        trip.suitcases.append(suitcase)
        context.insert(suitcase)
        try? context.save()
        dismiss()
        onCreated(suitcase)
    }

    // MARK: Building blocks

    @ViewBuilder
    private func field<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).strokeBorder(Theme.Palette.border))
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
