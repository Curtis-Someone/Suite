import SwiftUI
import SwiftData

/// Batch-3 check: seed a trip + suitcase + items into a fresh in-memory store,
/// read them back through `@Query`, show what came out. Launch with `-dataCheck YES`.
struct DataCheckView: View {
    var body: some View {
        Content()
            .modelContainer(SampleData.inMemoryContainer())
    }

    private struct Content: View {
        @Environment(\.modelContext) private var context
        @Query(sort: \Trip.createdAt) private var trips: [Trip]
        @Query private var places: [VisitedPlace]
        @State private var seeded = false

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Data round-trip").font(.Suite.titleS)
                        .foregroundStyle(Theme.Palette.textPrimary)

                    ForEach(trips) { trip in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(trip.name) — \(trip.destinationCity), \(trip.destinationCountry) (\(trip.destinationCountryCode)) · \(trip.status.rawValue)")
                                .font(.Suite.bodyStrong)
                            ForEach(trip.suitcases) { suitcase in
                                Text("suitcase: \(suitcase.name) · progress \(Int(suitcase.progress * 100))% · \(suitcase.items.count) items")
                                    .font(.Suite.bodyS)
                                ForEach(suitcase.items.sorted { $0.sortOrder < $1.sortOrder }) { item in
                                    Text("  \(item.isPacked ? "☑︎" : "☐") \(item.name) ×\(item.quantity) — \(item.category.rawValue)")
                                        .font(.Suite.data)
                                }
                            }
                        }
                        .foregroundStyle(Theme.Palette.textBody)
                    }

                    Text("places: \(places.count) · home: \(places.filter(\.isHomeCountry).map(\.countryCode).joined(separator: ", "))")
                        .font(.Suite.bodyS)
                        .foregroundStyle(Theme.Palette.textBody)

                    let suitcase = trips.first?.suitcases.first
                    let ok = trips.count == 1
                        && suitcase?.items.count == 4
                        && suitcase?.items.filter(\.isPacked).count == 1
                        && (suitcase.map { $0.progress > 0.18 && $0.progress < 1 } ?? false)
                        && places.count == 1
                    Text(ok ? "PASS — created, saved, fetched back" : "FAIL")
                        .font(.Suite.button)
                        .foregroundStyle(ok ? Theme.Palette.accent : Theme.Palette.danger)
                }
                .padding(Theme.Space.screenH)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Palette.ground.ignoresSafeArea())
            .task {
                guard !seeded else { return }
                SampleData.seed(into: context)
                seeded = true
            }
        }
    }
}
