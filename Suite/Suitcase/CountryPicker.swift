import SwiftUI

/// Sheet: pick a country. Same row style as onboarding's "Where are you from?".
struct CountryPicker: View {
    @Binding var selectedCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [Country] {
        query.isEmpty
            ? Countries.prioritized
            : Countries.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
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
            .padding(.top, 20)
            .padding(.bottom, 14)

            ScrollView {
                LazyVStack(spacing: 7) {
                    ForEach(results) { country in
                        Button {
                            selectedCode = country.code
                            dismiss()
                        } label: {
                            HStack(spacing: 13) {
                                Text(country.flag)
                                    .font(.system(size: 26))
                                    .frame(width: 30, height: 22)
                                Text(country.name)
                                    .font(.archivo(15, .medium))
                                    .foregroundStyle(Theme.Palette.textPrimary)
                                Spacer()
                                if country.code == selectedCode {
                                    SuiteIconView(icon: .check, size: 16, color: Theme.Palette.accent)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 15))
                            .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Theme.Palette.border))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
    }
}
