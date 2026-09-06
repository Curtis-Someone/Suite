import SwiftUI
import SwiftData

/// S3 packing checklist and S4 completed state (same layout; `trip.isArchived`
/// makes it read-only + muted).
struct PackingChecklistView: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private let entitlements = Entitlements.shared

    @State private var collapsed: Set<ItemCategory> = []
    @State private var addingTo: ItemCategory?
    @State private var newItemName = ""
    @State private var upsell: UpsellMoment?
    @State private var templateSaved = false

    private var suitcase: Suitcase? { trip.suitcases.first }
    private var isDone: Bool { trip.isArchived }

    private var sections: [(category: ItemCategory, items: [Item])] {
        let grouped = Dictionary(grouping: suitcase?.items ?? [], by: \.category)
        return ItemCategory.allCases
            .sorted { $0.sortRank < $1.sortRank }
            .compactMap { cat in
                guard let items = grouped[cat], !items.isEmpty else { return nil }
                return (cat, items.sorted { $0.sortOrder < $1.sortOrder })
            }
    }

    var body: some View {
        if suitcase == nil {
            ErrorStateView(
                title: "Suitcase not found",
                message: "We couldn't load the checklist for this trip. Go back and open it again.",
                retry: { dismiss() }
            )
        } else {
            checklist
        }
    }

    private var checklist: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(sections, id: \.category) { section in
                        sectionCard(section.category, section.items)
                    }
                    if sections.isEmpty {
                        Text("No items yet. Add some below.")
                            .font(.Suite.bodyS)
                            .foregroundStyle(Theme.Palette.textTertiary)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .keepsSwipeBack()
        .task { await WeatherService.refresh(for: trip, in: context) }
        .alert("Add item", isPresented: Binding(get: { addingTo != nil }, set: { if !$0 { addingTo = nil } })) {
            TextField("Item name", text: $newItemName)
            Button("Add") { addItem() }
            Button("Cancel", role: .cancel) { newItemName = "" }
        } message: {
            if let addingTo { Text(addingTo.displayName) }
        }
        .sheet(item: $upsell) { UpsellSheet(moment: $0) }
        .alert("Saved to templates", isPresented: $templateSaved) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Start a new suitcase from “\(trip.name)” any time.")
        }
    }

    private func saveTemplateTapped() {
        switch PackingGate.canSaveTemplate(isPro: entitlements.isPro) {
        case .allowed:             saveTemplate()
        case .blocked(let reason): upsell = reason
        }
    }

    private func saveTemplate() {
        guard let suitcase else { return }
        let template = Template(name: trip.name, sourceTripName: trip.name)
        template.items = suitcase.items.map {
            TemplateItem(name: $0.name, category: $0.category, quantity: $0.quantity, template: template)
        }
        context.insert(template)
        try? context.save()
        templateSaved = true
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().strokeBorder(Theme.Palette.border).frame(width: 40, height: 40))
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
                Spacer()
                Menu {
                    if !isDone {
                        Button("Mark trip complete") { markComplete() }
                    } else {
                        Button("Reopen trip") { trip.isArchived = false; try? context.save() }
                    }
                    Button("Save as template") { saveTemplateTapped() }
                } label: {
                    SuiteIconView(icon: .ellipsis, size: 20, color: Theme.Palette.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("More options")
            }

            if isDone {
                HStack(spacing: 7) {
                    SuiteIconView(icon: .check, size: 13, color: Theme.Palette.onAccent)
                    Text("Trip completed")
                        .font(.jetBrainsMono(11, .bold)).tracking(0.8).textCase(.uppercase)
                        .foregroundStyle(Theme.Palette.onAccent)
                }
                .padding(.horizontal, 11).frame(minHeight: 26)
                .background(Theme.Palette.accent, in: Capsule())
                .padding(.top, 14)
            }

            Text(trip.name)
                .font(.Suite.title).tracking(26 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .lineLimit(2).minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            HStack(spacing: 12) {
                Text("\(Self.dateRange(trip)) · \(trip.destinationCountry)")
                    .font(.jetBrainsMono(12))
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let weather = weatherSummary {
                    Rectangle().fill(Theme.Palette.track).frame(width: 1, height: 14)
                    HStack(spacing: 7) {
                        LucideIcon(name: weather.icon, size: 16, color: Theme.Palette.accent)
                        Text(weather.range)
                            .font(.jetBrainsMono(12, .medium))
                            .foregroundStyle(Theme.Palette.textPrimary)
                            .fixedSize()
                    }
                }
            }
            .padding(.top, 8)

            SuiteProgressBar(value: suitcase?.progress ?? 0.18, height: 9)
                .padding(.top, 16)

            HStack(alignment: .firstTextBaseline) {
                Text("\(percent)% ready · \(packedCount)/\(totalCount) packed")
                    .font(.archivo(13, .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(isDone ? "done" : "\(max(0, totalCount - packedCount)) to go")
                    .font(.jetBrainsMono(12))
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .fixedSize()
            }
            .padding(.top, 9)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(Theme.Palette.surface)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Palette.border).frame(height: 1) }
    }

    // MARK: Section card

    private func sectionCard(_ category: ItemCategory, _ items: [Item]) -> some View {
        let isCollapsed = collapsed.contains(category)
        let packed = items.filter(\.isPacked).count
        return VStack(spacing: 0) {
            Button {
                if isCollapsed { collapsed.remove(category) } else { collapsed.insert(category) }
            } label: {
                HStack(spacing: 10) {
                    SuiteIconView(icon: isCollapsed ? .chevronRight : .chevronDown,
                                  size: 14, color: Theme.Palette.textPrimary)
                    Text(category.displayName)
                        .font(.archivo(14, .bold))
                        .foregroundStyle(isDone ? Theme.Palette.textSecondary : Theme.Palette.textPrimary)
                    Spacer()
                    Text("\(packed)/\(items.count)")
                        .font(.jetBrainsMono(12, .medium))
                        .foregroundStyle(packed == items.count ? Theme.Palette.textTertiary : Theme.Palette.accent)
                }
                .frame(minHeight: 50)
                .contentShape(Rectangle())
            }
            .buttonStyle(.suitePress)
            .accessibilityLabel("\(category.displayName), \(packed) of \(items.count) packed")
            .accessibilityHint(isCollapsed ? "Expand section" : "Collapse section")

            if !isCollapsed {
                ForEach(items) { item in
                    Divider().overlay(Theme.Palette.divider)
                    row(item)
                }
                if !isDone {
                    Divider().overlay(Theme.Palette.divider)
                    Button { addingTo = category } label: {
                        HStack(spacing: 10) {
                            SuiteIconView(icon: .plus, size: 14, color: Theme.Palette.textTertiary)
                            Text("Add item").font(.archivo(13)).foregroundStyle(Theme.Palette.textTertiary)
                            Spacer()
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.suitePress)
                    .accessibilityLabel("Add item to \(category.displayName)")
                }
            }
        }
        .padding(.horizontal, 16)
        .background(isDone ? Theme.Palette.fill : Theme.Palette.surface,
                   in: RoundedRectangle(cornerRadius: 16))
    }

    private func row(_ item: Item) -> some View {
        let label = item.quantity > 1 ? "\(item.name) × \(item.quantity)" : item.name
        return HStack(spacing: 12) {
            Button {
                guard !isDone else { return }
                let wasAllPacked = allPacked
                item.isPacked.toggle()
                try? context.save()
                if !wasAllPacked, allPacked, let suitcase {
                    RewardEngine.suitcasePacked(trip: trip, itemCount: suitcase.items.count)
                }
            } label: {
                RoundedRectangle(cornerRadius: 7)
                    .fill(item.isPacked ? checkFill : .clear)
                    .overlay {
                        if item.isPacked {
                            SuiteIconView(icon: .check, size: 13, color: isDone ? Theme.Palette.fill : Theme.Palette.onAccent)
                        } else {
                            RoundedRectangle(cornerRadius: 7).strokeBorder(Theme.Palette.track, lineWidth: 1.6)
                        }
                    }
                    .frame(width: 22, height: 22)
                    .frame(width: 44, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(.trailing, -22)   // 44pt target without shifting the row
            }
            .buttonStyle(.plain)
            .disabled(isDone)
            .accessibilityLabel(label)
            .accessibilityValue(item.isPacked ? "Packed" : "Not packed")
            .accessibilityAddTraits(.isToggle)

            Text(label)
                .font(.archivo(14, item.isPacked ? .regular : .medium))
                .foregroundStyle(item.isPacked ? Theme.Palette.textTertiary : Theme.Palette.textPrimary)
                .strikethrough(item.isPacked, color: Theme.Palette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)

            if !isDone {
                Button {
                    context.delete(item)
                    try? context.save()
                } label: {
                    SuiteIconView(icon: .close, size: 12, color: Theme.Palette.textDisabled)
                        .frame(width: 26, height: 26)
                        .background(Theme.Palette.ground, in: RoundedRectangle(cornerRadius: 8))
                        .frame(width: 44, height: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(label)")
            }
        }
        .frame(minHeight: 46)
    }

    private var checkFill: Color { isDone ? Theme.Palette.textDisabled : Theme.Palette.accent }

    // MARK: Actions / derived

    private func addItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        newItemName = ""
        guard let category = addingTo, !trimmed.isEmpty, let suitcase else { return }
        let item = Item(name: trimmed, category: category, suitcase: suitcase)
        item.sortOrder = (suitcase.items.map(\.sortOrder).max() ?? 0) + 1
        suitcase.items.append(item)
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

    private var allPacked: Bool {
        guard let suitcase, !suitcase.items.isEmpty else { return false }
        return suitcase.items.allSatisfy(\.isPacked)
    }

    private var totalCount: Int { suitcase?.items.count ?? 0 }
    private var packedCount: Int { suitcase?.items.filter(\.isPacked).count ?? 0 }
    private var percent: Int { Int(((suitcase?.progress ?? 0.18) * 100).rounded()) }

    private var weatherSummary: (range: String, icon: String)? {
        let days = trip.weatherDays
        guard !days.isEmpty else { return nil }
        let lo = Int(days.map(\.lowTemp).min()!.rounded())
        let hi = Int(days.map(\.highTemp).max()!.rounded())
        let code = days.sorted { $0.date < $1.date }[days.count / 2].conditionCode
        return ("\(lo)–\(hi)°C", WeatherService.iconName(for: code))
    }

    /// "14–22 Sep" when the same month, "28 Sep–3 Oct" when it spans months.
    static func dateRange(_ trip: Trip) -> String {
        let cal = Calendar.current
        let day = DateFormatter(); day.dateFormat = "d"
        let dayMonth = DateFormatter(); dayMonth.dateFormat = "d MMM"
        if cal.isDate(trip.startDate, equalTo: trip.endDate, toGranularity: .month) {
            return "\(day.string(from: trip.startDate))–\(dayMonth.string(from: trip.endDate))"
        }
        return "\(dayMonth.string(from: trip.startDate))–\(dayMonth.string(from: trip.endDate))"
    }
}
