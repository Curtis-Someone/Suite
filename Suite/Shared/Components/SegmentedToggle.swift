import SwiftUI

/// Two-option segmented control — `surfaceSunken` track, 4 pt inset, active
/// segment amber-filled (Archivo 700), inactive plain (`textSecondary`, 500).
/// Used for Trips ⁄ Passport on the Passport tab.
struct SegmentedToggle<Option: Hashable>: View {
    var options: [(value: Option, title: String)]
    @Binding var selection: Option
    var height: CGFloat = 46

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                let isActive = option.value == selection
                Text(option.title)
                    .font(.archivo(15, isActive ? .bold : .medium))
                    .foregroundStyle(isActive ? Theme.Palette.textPrimary : Theme.Palette.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if isActive {
                            RoundedRectangle(cornerRadius: (height - 8) / 2)
                                .fill(Theme.Palette.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selection = option.value }
            }
        }
        .padding(4)
        .frame(height: height)
        .background(Theme.Palette.surfaceSunken, in: Capsule())
    }
}
