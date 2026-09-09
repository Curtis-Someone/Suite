import SwiftUI
import SwiftData

/// M1 · Add a visited place. Tap a country to toggle it visited; the Passport
/// stats behind this sheet update live.
struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var visits: [VisitedPlace]

    @State private var query = ""
    @State private var confirmRemoval: Country?
    @State private var protectedNotice: Country?

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
                Spacer()
                Button("Done") { dismiss() }
                    .font(.archivo(15, .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
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
            .frame(height: 48)
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
        .alert(
            "Remove this country?",
            isPresented: Binding(get: { confirmRemoval != nil },
                                 set: { if !$0 { confirmRemoval = nil } }),
            presenting: confirmRemoval
        ) { country in
            Button("Remove", role: .destructive) { removeVisits(for: country) }
            Button("Cancel", role: .cancel) { }
        } message: { _ in
            Text("Remove this country from your visited list? This can't be undone.")
        }
        .alert(
            "This one stays",
            isPresented: Binding(get: { protectedNotice != nil },
                                 set: { if !$0 { protectedNotice = nil } }),
            presenting: protectedNotice
        ) { _ in
            Button("OK", role: .cancel) { }
        } message: { country in
            Text(noticeMessage(for: country))
        }
    }

    private func noticeMessage(for country: Country) -> String {
        let stamps = visits.filter { $0.countryCode.uppercased() == country.code }
        return stamps.contains { $0.isHomeCountry }
            ? "\(country.name) is your home country, so it stays on your map. It can't be removed here."
            : "\(country.name) came from a completed trip, so it stays stamped. It can't be removed here."
    }

    private func row(_ country: Country, isVisited: Bool) -> some View {
        Button {
            toggle(country, isVisited: isVisited)
        } label: {
            HStack(spacing: 13) {
                FlagView(code: country.code, height: 22)
                Text(country.name)
                    .font(.archivo(15, isVisited ? .semibold : .medium))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
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
            .frame(height: 58)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.chip)
                    .strokeBorder(isVisited ? Theme.Palette.accent : Theme.Palette.border,
                                  lineWidth: isVisited ? 1.6 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ country: Country, isVisited: Bool) {
        if isVisited {
            let stamps = visits.filter { $0.countryCode.uppercased() == country.code }
            if stamps.allSatisfy(\.isProtectedStamp) {
                protectedNotice = country
            } else {
                confirmRemoval = country
            }
        } else {
            context.insert(VisitedPlace(countryName: country.name, countryCode: country.code))
            try? context.save()
            RewardEngine.countryAdded(
                code: country.code,
                visitsAfter: (try? context.fetch(FetchDescriptor<VisitedPlace>())) ?? [])
        }
    }

    private func removeVisits(for country: Country) {
        for place in visits where place.countryCode.uppercased() == country.code
            && !place.isProtectedStamp {
            context.delete(place)
        }
        try? context.save()
    }
}
