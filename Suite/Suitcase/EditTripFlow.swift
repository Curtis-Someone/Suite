import SwiftUI
import SwiftData

/// Edit-trip form — the same fields as `NewTripFlow` (name, destination, dates,
/// trip type), pre-filled from an existing `Trip` and written back in place on
/// save. Opened from `TripDetailView`'s options menu.
struct EditTripFlow: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name: String
    @State private var countryCode: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var tripTypeSel: Set<String>
    @State private var showingCountryPicker = false

    init(trip: Trip) {
        self.trip = trip
        _name = State(initialValue: trip.name)
        _countryCode = State(initialValue: trip.destinationCountryCode)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
        _tripTypeSel = State(initialValue: trip.tripType.isEmpty ? [] : [trip.tripType])
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !countryCode.isEmpty
            && endDate >= startDate
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Text("Edit trip.")
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
                SuiteButton(title: "Save changes", isEnabled: isValid, action: save)
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
            .accessibilityLabel("Cancel")
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: Save

    private func save() {
        let newStart = Calendar.current.startOfDay(for: startDate)
        let newEnd = Calendar.current.startOfDay(for: endDate)
        // Cached weather is tied to the destination + dates — drop it so the
        // checklist refetches when either changes (the 6h freshness guard in
        // WeatherService would otherwise keep stale rows).
        let destinationChanged = countryCode != trip.destinationCountryCode
            || newStart != trip.startDate
            || newEnd != trip.endDate

        trip.name = name.trimmingCharacters(in: .whitespaces)
        trip.destinationCountryCode = countryCode
        trip.destinationCountry = Countries.name(for: countryCode)
        trip.startDate = newStart
        trip.endDate = newEnd
        trip.tripType = tripTypeSel.first ?? ""
        trip.iconName = trip.tripType.isEmpty
            ? "luggage"
            : (PackingPreset.icon(forTripType: trip.tripType) ?? "luggage")

        if destinationChanged {
            for day in trip.weatherDays { context.delete(day) }
        }
        try? context.save()
        dismiss()
    }

    // MARK: Building blocks (mirror NewTripFlow)

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
