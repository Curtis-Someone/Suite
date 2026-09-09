import SwiftUI
import SwiftData

/// S3 packing checklist and S4 completed state (same layout; `trip.isArchived`
/// makes it read-only + muted). Keyed on a single `Suitcase` — a trip can hold
/// several; the trip-level actions (complete / reopen) live on `TripDetailView`.
struct PackingChecklistView: View {
    let suitcase: Suitcase

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let entitlements = Entitlements.shared

    @State private var collapsed: Set<ItemCategory> = []
    @State private var addingTo: ItemCategory?
    @State private var newItemName = ""
    @State private var upsell: UpsellMoment?
    @State private var templateSaved = false
    @State private var showExport = false

    /// Safe to force-unwrap: `body` renders the error state when the inverse is
    /// missing, and every suitcase we push here belongs to a trip.
    private var trip: Trip { suitcase.trip! }
    private var isDone: Bool { suitcase.trip?.isArchived ?? false }

    private var sections: [(category: ItemCategory, items: [Item])] {
        let grouped = Dictionary(grouping: suitcase.items, by: \.category)
        return ItemCategory.allCases
            .sorted { $0.sortRank < $1.sortRank }
            .compactMap { cat in
                guard let items = grouped[cat], !items.isEmpty else { return nil }
                return (cat, items.sorted { $0.sortOrder < $1.sortOrder })
            }
    }

    var body: some View {
        if suitcase.trip == nil {
            ErrorStateView(
                title: "Suitcase not found",
                message: "We couldn't load this packing list. Go back and open it again.",
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
                        VStack(spacing: 16) {
                            Text(isDone ? "No items." : "No items yet.")
                                .font(.Suite.bodyS)
                                .foregroundStyle(Theme.Palette.textTertiary)
                            if !isDone {
                                Button { addingTo = .misc } label: {
                                    HStack(spacing: 8) {
                                        SuiteIconView(icon: .plus, size: 14, color: Theme.Palette.accent)
                                        Text("Add item")
                                            .font(.archivo(13, .semibold))
                                            .foregroundStyle(Theme.Palette.accent)
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 38)
                                    .overlay(Capsule().strokeBorder(Theme.Palette.accent.opacity(0.5)))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Add item")
                            }
                        }
                        .frame(maxWidth: .infinity)
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
        // One haptic per change in packed count — a single tap or a whole
        // "Select all" batch each fire once, not once per item.
        .sensoryFeedback(trigger: packedCount) { old, new in
            new > old ? .impact(weight: .light, intensity: 0.7) : .selection
        }
        .task { await WeatherService.refresh(for: trip, in: context) }
        .task {
            if ProcessInfo.processInfo.arguments.contains("-exportPDF") { showExport = true }
        }
        .alert("Add item", isPresented: Binding(get: { addingTo != nil }, set: { if !$0 { addingTo = nil } })) {
            TextField("Item name", text: $newItemName)
            Button("Add") { addItem() }
            Button("Cancel", role: .cancel) { newItemName = "" }
        } message: {
            if let addingTo { Text(addingTo.displayName) }
        }
        .sheet(item: $upsell) { UpsellSheet(moment: $0) }
        .sheet(isPresented: $showExport) { TripExportSheet(suitcase: suitcase) }
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

    private func exportTapped() {
        switch PackingGate.canExport(isPro: entitlements.isPro) {
        case .allowed:             showExport = true
        case .blocked(let reason): upsell = reason
        }
    }

    private func saveTemplate() {
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
                        .frame(width: 40, height: 40)
                        .overlay(Circle().strokeBorder(Theme.Palette.border))
                }
                .accessibilityLabel("Back")
                Spacer()
                Menu {
                    Button("Save as template") { saveTemplateTapped() }
                    Button("Export as PDF") { exportTapped() }
                } label: {
                    SuiteIconView(icon: .ellipsis, size: 20, color: Theme.Palette.textPrimary)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("Packing list options")
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

            Text(trip.name)
                .font(.Suite.title).tracking(26 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.top, 14)

            HStack(spacing: 12) {
                Text("\(Self.dateRange(trip)) · \(trip.destinationCountry)")
                    .font(.jetBrainsMono(12))
                    .foregroundStyle(Theme.Palette.textSecondary)
                if let weather = weatherSummary {
                    Rectangle().fill(Theme.Palette.track).frame(width: 1, height: 14)
                    HStack(spacing: 7) {
                        LucideIcon(name: weather.icon, size: 16, color: Theme.Palette.accent)
                        Text(weather.range)
                            .font(.jetBrainsMono(12, .medium))
                            .foregroundStyle(Theme.Palette.textPrimary)
                    }
                }
            }
            .padding(.top, 8)

            SuiteProgressBar(value: suitcase.progress, height: 9)
                .padding(.top, 16)

            HStack {
                Text("\(percent)% ready · \(packedCount)/\(totalCount) packed")
                    .font(.archivo(13, .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .contentTransition(.numericText())
                Spacer()
                Text(isDone ? "done" : "\(max(0, totalCount - packedCount)) to go")
                    .font(.jetBrainsMono(12))
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .contentTransition(.numericText())
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
            HStack(spacing: 10) {
                Button {
                    withAnimation(Theme.Motion.expand.gated(reduceMotion)) {
                        if isCollapsed { collapsed.remove(category) } else { collapsed.insert(category) }
                    }
                } label: {
                    HStack(spacing: 10) {
                        SuiteIconView(icon: .chevronDown,
                                      size: 14, color: Theme.Palette.textPrimary)
                            .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                        Text(category.displayName)
                            .font(.archivo(14, .bold))
                            .foregroundStyle(isDone ? Theme.Palette.textSecondary : Theme.Palette.textPrimary)
                        Spacer(minLength: 8)
                        Text("\(packed)/\(items.count)")
                            .font(.jetBrainsMono(12, .medium))
                            .foregroundStyle(packed == items.count ? Theme.Palette.textTertiary : Theme.Palette.accent)
                            .contentTransition(.numericText())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if !isDone && packed < items.count {
                    Button { selectAll(items) } label: {
                        Text("Select all")
                            .font(.archivo(12, .semibold))
                            .foregroundStyle(Theme.Palette.accent)
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .overlay(Capsule().strokeBorder(Theme.Palette.accent.opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Select all \(category.displayName) items")
                }
            }
            .frame(height: 50)

            if !isCollapsed {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        VStack(spacing: 0) {
                            Divider().overlay(Theme.Palette.divider)
                            row(item)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    if !isDone {
                        Divider().overlay(Theme.Palette.divider)
                        Button { addingTo = category } label: {
                            HStack(spacing: 10) {
                                SuiteIconView(icon: .plus, size: 14, color: Theme.Palette.textTertiary)
                                Text("Add item").font(.archivo(13)).foregroundStyle(Theme.Palette.textTertiary)
                                Spacer()
                            }
                            .frame(height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .background(isDone ? Theme.Palette.fill : Theme.Palette.surface,
                   in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
    }

    private func row(_ item: Item) -> some View {
        HStack(spacing: 12) {
            Button {
                guard !isDone else { return }
                let wasAllPacked = allPacked
                withAnimation(Theme.Motion.reactive.gated(reduceMotion)) {
                    item.isPacked.toggle()
                }
                try? context.save()
                if !wasAllPacked, allPacked {
                    RewardEngine.suitcasePacked(trip: trip, itemCount: suitcase.items.count)
                }
            } label: {
                RoundedRectangle(cornerRadius: Theme.Radius.control)
                    .fill(item.isPacked ? checkFill : .clear)
                    .overlay {
                        if item.isPacked {
                            SuiteIconView(icon: .check, size: 13, color: isDone ? Theme.Palette.fill : Theme.Palette.onAccent)
                                .transition(.scale(scale: 0.4).combined(with: .opacity))
                        } else {
                            RoundedRectangle(cornerRadius: Theme.Radius.control).strokeBorder(Theme.Palette.track, lineWidth: 1.6)
                                .transition(.opacity)
                        }
                    }
                    .frame(width: 22, height: 22)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.name)
            .accessibilityValue(item.isPacked ? "Packed" : "Not packed")
            .accessibilityAddTraits(item.isPacked ? [.isButton, .isSelected] : .isButton)

            Text(item.quantity > 1 ? "\(item.name) × \(item.quantity)" : item.name)
                .font(.archivo(14, item.isPacked ? .regular : .medium))
                .foregroundStyle(item.isPacked ? Theme.Palette.textTertiary : Theme.Palette.textPrimary)
                .strikethrough(item.isPacked, color: Theme.Palette.textTertiary)
                .contentTransition(.numericText())

            Spacer()

            if !isDone {
                HStack(spacing: 0) {
                    Button {
                        withAnimation(Theme.Motion.reactive.gated(reduceMotion)) {
                            item.quantity += 1
                        }
                        try? context.save()
                    } label: {
                        SuiteIconView(icon: .plus, size: 12, color: Theme.Palette.textDisabled)
                            .frame(width: 26, height: 26)
                            .background(Theme.Palette.ground, in: RoundedRectangle(cornerRadius: Theme.Radius.control))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add one \(item.name)")

                    Button {
                        withAnimation(Theme.Motion.expand.gated(reduceMotion)) {
                            context.delete(item)
                        }
                        try? context.save()
                    } label: {
                        SuiteIconView(icon: .close, size: 12, color: Theme.Palette.textDisabled)
                            .frame(width: 26, height: 26)
                            .background(Theme.Palette.ground, in: RoundedRectangle(cornerRadius: Theme.Radius.control))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(item.name)")
                }
            }
        }
        .frame(height: 46)
    }

    private var checkFill: Color { isDone ? Theme.Palette.textDisabled : Theme.Palette.accent }

    // MARK: Actions / derived

    private func addItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        newItemName = ""
        guard let category = addingTo, !trimmed.isEmpty else { return }
        let item = Item(name: trimmed, category: category, suitcase: suitcase)
        item.sortOrder = (suitcase.items.map(\.sortOrder).max() ?? 0) + 1
        withAnimation(Theme.Motion.expand.gated(reduceMotion)) {
            suitcase.items.append(item)
        }
        try? context.save()
    }

    /// Marks every item in one packing section packed — ticking them off
    /// top-to-bottom rather than all at once. Instant under Reduce Motion.
    private func selectAll(_ items: [Item]) {
        guard !isDone else { return }
        let wasAllPacked = allPacked
        for (i, item) in items.enumerated() where !item.isPacked {
            withAnimation(Theme.Motion.reactive.gated(reduceMotion)?
                .delay(Double(i) * Theme.Motion.staggerStep)) {
                item.isPacked = true
            }
        }
        try? context.save()
        if !wasAllPacked, allPacked {
            RewardEngine.suitcasePacked(trip: trip, itemCount: suitcase.items.count)
        }
    }

    private var allPacked: Bool {
        guard !suitcase.items.isEmpty else { return false }
        return suitcase.items.allSatisfy(\.isPacked)
    }

    private var totalCount: Int { suitcase.items.count }
    private var packedCount: Int { suitcase.items.filter(\.isPacked).count }
    private var percent: Int { Int((suitcase.progress * 100).rounded()) }

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
