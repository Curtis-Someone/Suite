import SwiftUI
import SwiftData

/// M1 · Add a visited place. Tap a country to toggle it visited; the Passport
/// stats behind this sheet update live.
struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var visits: [VisitedPlace]

    @State private var query = ""

    private var visitedCodes: Set<String> {
        Set(visits.map { $0.countryCode.uppercased() })
    }

    private var results: [Country] {
        query.isEmpty
            ? Countries.prioritized
            : Countries.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add your visits")
                    .font(.Suite.title).tracking(25 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(2).minimumScaleFactor(0.7)
                Spacer(minLength: 12)
                Button("Done") { dismiss() }
                    .font(.archivo(15, .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .buttonStyle(.suitePress)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            HStack(spacing: 12) {
                SuiteIconView(icon: .search, size: 18)
                TextField("Search countries", text: $query)
                    .font(.Suite.body)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 48)
            .background(Theme.Palette.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.Palette.border))
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            ScrollView {
                LazyVStack(spacing: 7) {
                    ForEach(results) { country in
                        row(country, isVisited: visitedCodes.contains(country.code))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
    }

    private func row(_ country: Country, isVisited: Bool) -> some View {
        Button {
            toggle(country, isVisited: isVisited)
        } label: {
            HStack(spacing: 13) {
                Text(country.flag).font(.system(size: 24)).frame(width: 30, height: 22)
                Text(country.name)
                    .font(.archivo(15, isVisited ? .semibold : .medium))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if isVisited {
                    SuiteIconView(icon: .check, size: 14, color: Theme.Palette.onAccent)
                        .frame(width: 22, height: 22)
                        .background(Theme.Palette.accent, in: Circle())
                } else {
                    Circle().strokeBorder(Theme.Palette.track, lineWidth: 1.6)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 58)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(isVisited ? Theme.Palette.accent : Theme.Palette.border,
                                  lineWidth: isVisited ? 1.6 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ country: Country, isVisited: Bool) {
        if isVisited {
            for place in visits where place.countryCode.uppercased() == country.code {
                context.delete(place)
            }
        } else {
            context.insert(VisitedPlace(countryName: country.name, countryCode: country.code))
            try? context.save()
            RewardEngine.countryAdded(
                code: country.code,
                visitsAfter: (try? context.fetch(FetchDescriptor<VisitedPlace>())) ?? [])
            return
        }
        try? context.save()
    }
}
