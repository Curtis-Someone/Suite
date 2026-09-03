import SwiftUI

/// Inline month calendar with tap-to-pick range selection. Replaces the two
/// separate date pickers on the New Suitcase "Basics" step.
///
/// Interaction: the first tap starts a fresh range (start == end); a following
/// tap on the same or a later day closes it; a tap on an earlier day restarts.
struct TripDatesCalendar: View {
    @Binding var startDate: Date
    @Binding var endDate: Date

    private let cal = Calendar.current
    @State private var visibleMonth = Date()

    /// Monday-first, matching the design reference.
    private let weekdays = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()
    private static let rangeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()

    var body: some View {
        VStack(spacing: 14) {
            header
            Rectangle().fill(Theme.Palette.border).frame(height: 1)
            weekdayRow
            grid
            Rectangle().fill(Theme.Palette.border).frame(height: 1)
            summary
        }
        .padding(18)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).strokeBorder(Theme.Palette.border))
        .onAppear { visibleMonth = startOfMonth(rangeStart) }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text(Self.monthFormatter.string(from: visibleMonth))
                .font(.archivo(17, .bold))
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
            navButton(.chevronLeft) { shiftMonth(-1) }
            navButton(.chevronRight) { shiftMonth(1) }
        }
    }

    private func navButton(_ icon: SuiteIcon, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SuiteIconView(icon: icon, size: 15, color: Theme.Palette.accent)
                .frame(width: 34, height: 34)
                .overlay(Circle().strokeBorder(Theme.Palette.border))
        }
        .buttonStyle(.plain)
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { d in
                Text(d)
                    .font(.Suite.labelS)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Grid

    private var grid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
            spacing: 4
        ) {
            ForEach(Array(monthCells(visibleMonth).enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let inRange = day >= rangeStart && day <= rangeEnd
        let isStart = sameDay(day, rangeStart)
        let isEnd = sameDay(day, rangeEnd)
        let isEndpoint = isStart || isEnd
        let showsBand = inRange && !sameDay(rangeStart, rangeEnd)

        return ZStack {
            if showsBand {
                let r = Theme.Radius.card
                UnevenRoundedRectangle(
                    topLeadingRadius: isStart ? r : 0,
                    bottomLeadingRadius: isStart ? r : 0,
                    bottomTrailingRadius: isEnd ? r : 0,
                    topTrailingRadius: isEnd ? r : 0
                )
                .fill(Theme.Palette.accent.opacity(0.14))
                .frame(height: 40)
            }
            if isEndpoint {
                Circle().fill(Theme.Palette.accent).padding(3)
            }
            Text("\(cal.component(.day, from: day))")
                .font(.jetBrainsMono(14, .medium))
                .foregroundStyle(
                    isEndpoint ? Theme.Palette.onAccent : Theme.Palette.textPrimary
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .contentShape(Rectangle())
        .onTapGesture { select(day) }
    }

    private var summary: some View {
        HStack {
            Text("\(Self.rangeFormatter.string(from: rangeStart)) – \(Self.rangeFormatter.string(from: rangeEnd))")
                .font(.Suite.data)
                .foregroundStyle(Theme.Palette.textSecondary)
            Spacer()
            Text(nightsLabel)
                .font(.Suite.data)
                .foregroundStyle(Theme.Palette.textTertiary)
        }
    }

    // MARK: Selection

    private func select(_ day: Date) {
        let d = cal.startOfDay(for: day)
        if sameDay(rangeStart, rangeEnd), d >= rangeStart {
            endDate = d
        } else {
            startDate = d
            endDate = d
        }
    }

    // MARK: Derived

    private var rangeStart: Date { cal.startOfDay(for: min(startDate, endDate)) }
    private var rangeEnd: Date { cal.startOfDay(for: max(startDate, endDate)) }

    private var nightsLabel: String {
        let n = cal.dateComponents([.day], from: rangeStart, to: rangeEnd).day ?? 0
        return n == 1 ? "1 night" : "\(n) nights"
    }

    private func sameDay(_ a: Date, _ b: Date) -> Bool { cal.isDate(a, inSameDayAs: b) }

    private func startOfMonth(_ d: Date) -> Date {
        cal.date(from: cal.dateComponents([.year, .month], from: d)) ?? d
    }

    private func shiftMonth(_ n: Int) {
        guard let m = cal.date(byAdding: .month, value: n, to: visibleMonth) else { return }
        withAnimation(.easeInOut(duration: 0.15)) { visibleMonth = startOfMonth(m) }
    }

    /// 7-column cells for `month`, `nil` for the leading/trailing blanks.
    private func monthCells(_ month: Date) -> [Date?] {
        let first = startOfMonth(month)
        guard let dayRange = cal.range(of: .day, in: .month, for: first) else { return [] }
        let leading = (cal.component(.weekday, from: first) + 5) % 7   // Monday = 0
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in dayRange.map({ $0 - 1 }) {
            cells.append(cal.date(byAdding: .day, value: offset, to: first))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}

#Preview {
    struct Wrap: View {
        @State var start = Date()
        @State var end = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        var body: some View {
            TripDatesCalendar(startDate: $start, endDate: $end)
                .padding(24)
                .background(Theme.Palette.ground)
        }
    }
    return Wrap()
}
