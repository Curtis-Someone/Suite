import SwiftUI

/// The 2-column selectable chip grid used on both builder steps. Each chip is a
/// full-colour icon tile (a deliberate multi-colour exception) + label; selected
/// = amber tint + amber border.
struct BuilderChipGrid: View {
    var chips: [PresetChip]
    /// When true, picking one clears the rest (used for the trip-type section).
    var singleSelect: Bool = false
    @Binding var selected: Set<String>

    private let columns = [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 9) {
            ForEach(chips) { chip in
                let isOn = selected.contains(chip.id)
                Button {
                    if isOn {
                        selected.remove(chip.id)
                    } else if singleSelect {
                        selected = [chip.id]
                    } else {
                        selected.insert(chip.id)
                    }
                } label: {
                    HStack(spacing: 11) {
                        LucideIcon(name: chip.iconName, size: 17, color: .white)
                            .frame(width: 32, height: 32)
                            .background(chip.tileColor, in: RoundedRectangle(cornerRadius: 9))
                        Text(chip.title)
                            .font(.archivo(13, .semibold))
                            .foregroundStyle(Theme.Palette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 58)
                    .background(isOn ? Theme.Palette.accent.opacity(0.12) : Theme.Palette.surface,
                               in: RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .strokeBorder(isOn ? Theme.Palette.accent : Theme.Palette.border,
                                          lineWidth: 1.4)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
