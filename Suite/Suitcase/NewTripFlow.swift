import SwiftUI
import SwiftData

/// New-trip form — destination, dates, trip type. A trip is created with **no**
/// suitcase; bags are added afterwards from `TripDetailView`. This is the split
/// half of the old combined builder (see CLAUDE.md — trips and suitcases are
/// separate concepts). Visual language mirrors `NewSuitcaseFlow`'s Basics step;
/// there's no dedicated handoff artboard for it.
struct NewTripFlow: View {
    var onCreated: (Trip) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var countryCode = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
    @State private var tripTypeSel: Set<String> = []
    @State private var showingCountryPicker = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !countryCode.isEmpty
            && endDate >= startDate
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Text("New trip.")
                .font(.Suite.titleL).tracking(27 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    field {
                        TextField("Trip name", text: $name).font(.archivo(15, .medium))
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
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            footer {
                SuiteButton(title: "Create trip", isEnabled: isValid, action: create)
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
            Button { dismiss() } label: {
                SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Theme.Palette.border))
            }
            .accessibilityLabel("Back")
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: Create

    private func create() {
        let trip = Trip(
            name: name.trimmingCharacters(in: .whitespaces),
            destinationCity: "",
            destinationCountry: Countries.name(for: countryCode),
            destinationCountryCode: countryCode,
            startDate: Calendar.current.startOfDay(for: startDate),
            endDate: Calendar.current.startOfDay(for: endDate)
        )
        trip.tripType = tripTypeSel.first ?? ""
        trip.iconName = trip.tripType.isEmpty
            ? "luggage"
            : (PackingPreset.icon(forTripType: trip.tripType) ?? "luggage")

        context.insert(trip)
        try? context.save()
        dismiss()
        onCreated(trip)
    }

    // MARK: Building blocks (mirror NewSuitcaseFlow)

    @ViewBuilder
    private func field<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 16)
            .frame(height: 54)
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
