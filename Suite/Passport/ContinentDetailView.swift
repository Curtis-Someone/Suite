import SwiftUI
import SwiftData

/// P3 · Continent detail — every country in the continent, visited ones amber
/// with a check, the rest greyed.
struct ContinentDetailView: View {
    let continent: Continent

    @Environment(\.dismiss) private var dismiss
    @Query private var visits: [VisitedPlace]

    private var visitedCodes: Set<String> { Set(visits.map { $0.countryCode.uppercased() }) }
    private var countries: [Country] { Countries.countries(in: continent).sorted { $0.name < $1.name } }
    private var visitedCount: Int { countries.filter { visitedCodes.contains($0.code) }.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 7) {
                    ForEach(countries) { country in
                        let visited = visitedCodes.contains(country.code)
                        HStack(spacing: 13) {
                            Text(country.flag).font(.system(size: 22)).frame(width: 28, height: 20)
                                .opacity(visited ? 1 : 0.35)
                            Text(country.name)
                                .font(.archivo(15, visited ? .semibold : .regular))
                                .foregroundStyle(visited ? Theme.Palette.textPrimary : Theme.Palette.textTertiary)
                            Spacer()
                            if visited {
                                SuiteIconView(icon: .check, size: 13, color: Theme.Palette.accent)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(visited ? Theme.Palette.accent.opacity(0.10) : Theme.Palette.surface,
                                   in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Palette.border))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(Theme.Palette.border).frame(width: 40, height: 40))
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Back")
            VStack(alignment: .leading, spacing: 2) {
                Text(fullContinentName)
                    .font(.Suite.title).tracking(25 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("\(visitedCount) of \(continent.totalCountries) visited")
                    .font(.Suite.data)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var fullContinentName: String {
        switch continent {
        case .northAmerica: "North America"
        case .southAmerica: "South America"
        default: continent.displayName
        }
    }
}
