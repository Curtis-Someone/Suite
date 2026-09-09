import SwiftUI

/// 08b · Where are you from? — single-select country list. The pick seeds the
/// Passport (a `VisitedPlace` with `isHomeCountry`), so stats start above zero.
struct HomeCountryView: View {
    var onContinue: (_ code: String, _ name: String) -> Void

    @State private var query = ""
    @State private var selected: Country?

    private var results: [Country] {
        guard !query.isEmpty else { return Countries.prioritized }
        return Countries.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Where are you from?")
                .font(.Suite.titleXL).tracking(28 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            Text("Your home country counts as visited, so your\npassport starts with something in it.")
                .font(.archivo(14))
                .foregroundStyle(Theme.Palette.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)

            HStack(spacing: 12) {
                SuiteIconView(icon: .search, size: 18, color: Theme.Palette.textTertiary)
                TextField("Search countries", text: $query)
                    .font(.Suite.body)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 18)
            .frame(height: 48)
            .background(Theme.Palette.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.Palette.border))
            .padding(.bottom, 16)

            ScrollView {
                LazyVStack(spacing: 7) {
                    ForEach(results) { country in
                        row(country)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)

            SuiteButton(title: "Continue", isEnabled: selected != nil) {
                if let s = selected { onContinue(s.code, s.name) }
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.ground.ignoresSafeArea())
    }

    private func row(_ country: Country) -> some View {
        let isSelected = selected == country
        return Button {
            selected = country
        } label: {
            HStack(spacing: 13) {
                FlagView(code: country.code, height: 22)
                Text(country.name)
                    .font(.archivo(15, isSelected ? .bold : .medium))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
                if isSelected {
                    SuiteIconView(icon: .check, size: 14, color: Theme.Palette.onAccent)
                        .frame(width: 20, height: 20)
                        .background(Theme.Palette.accent, in: Circle())
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.chip)
                    .strokeBorder(isSelected ? Theme.Palette.accent : Theme.Palette.border,
                                  lineWidth: isSelected ? 1.6 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
