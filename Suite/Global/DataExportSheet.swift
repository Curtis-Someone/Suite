import SwiftUI
import SwiftData

/// Pro · "Export your data" from Settings — pick a trip, then export its packing
/// list as a PDF via `TripExportSheet`.
struct DataExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @State private var selected: Trip?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button { dismiss() } label: {
                    SuiteIconView(icon: .close, size: 18, color: Theme.Palette.textPrimary)
                        .frame(width: 42, height: 42)
                        .overlay(Circle().strokeBorder(Theme.Palette.border))
                }
                Text("Export your data")
                    .font(.Suite.titleS).tracking(22 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            if trips.isEmpty {
                Spacer()
                Text("No trips to export yet.")
                    .font(.Suite.bodyS).foregroundStyle(Theme.Palette.textTertiary)
                Spacer()
            } else {
                HStack {
                    KickerLabel("Packing lists")
                    Spacer()
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 10)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(trips) { trip in
                            Button { selected = trip } label: { row(trip) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .sheet(item: $selected) { TripExportSheet(trip: $0) }
    }

    private func row(_ trip: Trip) -> some View {
        HStack(spacing: 14) {
            LucideIcon(name: trip.iconName, size: 18, color: Theme.Palette.onAccent)
                .frame(width: 34, height: 24)
                .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: 5))
            VStack(alignment: .leading, spacing: 3) {
                Text(trip.name).font(.archivo(15, .semibold)).foregroundStyle(Theme.Palette.textPrimary)
                Text("\(PackingChecklistView.dateRange(trip)) · \(trip.destinationCountry)")
                    .font(.archivo(12)).foregroundStyle(Theme.Palette.textTertiary)
            }
            Spacer()
            SuiteIconView(icon: .chevronRight, size: 16)
        }
        .padding(.horizontal, 16)
        .frame(height: 62)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
