import SwiftUI
import SwiftData

/// P4 · Full country list — every visited country with its visit count.
struct CountryListView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var visits: [VisitedPlace]

    private var rows: [(country: Country, count: Int)] {
        Dictionary(grouping: visits, by: { $0.countryCode.uppercased() })
            .compactMap { code, places -> (Country, Int)? in
                guard let country = Countries.all.first(where: { $0.code == code }) else { return nil }
                return (country, places.count)
            }
            .sorted { $0.0.name < $1.0.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button { dismiss() } label: {
                    SuiteIconView(icon: .chevronLeft, size: 19, color: Theme.Palette.textPrimary)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().strokeBorder(Theme.Palette.border).frame(width: 40, height: 40))
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
                Text("My countries")
                    .font(.Suite.title).tracking(25 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 7) {
                    ForEach(rows, id: \.country.code) { row in
                        HStack(spacing: 13) {
                            Text(row.country.flag).font(.system(size: 22)).frame(width: 28, height: 20)
                            Text(row.country.name)
                                .font(.archivo(15, .medium))
                                .foregroundStyle(Theme.Palette.textPrimary)
                            Spacer()
                            Text(row.count == 1 ? "1 visit" : "\(row.count) visits")
                                .font(.Suite.data)
                                .foregroundStyle(Theme.Palette.textTertiary)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 14))
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
}
