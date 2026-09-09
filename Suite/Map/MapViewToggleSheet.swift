import SwiftUI

enum MapViewMode: String, CaseIterable {
    case countries, cities, regions
    var label: String { rawValue.capitalized }
    var iconName: String {
        switch self {
        case .countries: "globe"
        case .cities:    "building-2"
        case .regions:   "map"
        }
    }
    /// Only Countries is wired up so far.
    var isReady: Bool { self == .countries }
}

/// M3 · Map view toggle — bottom sheet, active option outlined amber.
struct MapViewToggleSheet: View {
    @Binding var mode: MapViewMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Map view")
                .font(.Suite.titleS).tracking(22 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.top, 20)

            ForEach(MapViewMode.allCases, id: \.self) { option in
                Button {
                    if option.isReady { mode = option; dismiss() }
                } label: {
                    HStack(spacing: 12) {
                        LucideIcon(name: option.iconName, size: 20,
                                   color: option == mode ? Theme.Palette.accent : Theme.Palette.textSecondary)
                        Text(option.label)
                            .font(.archivo(15, .semibold))
                            .foregroundStyle(option.isReady ? Theme.Palette.textPrimary : Theme.Palette.textTertiary)
                        Spacer()
                        if !option.isReady {
                            Text("Soon").font(.Suite.labelS).foregroundStyle(Theme.Palette.textTertiary)
                        } else if option == mode {
                            SuiteIconView(icon: .check, size: 16, color: Theme.Palette.accent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.chip)
                            .strokeBorder(option == mode ? Theme.Palette.accent : Theme.Palette.border,
                                          lineWidth: option == mode ? 1.6 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.ground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
    }
}
