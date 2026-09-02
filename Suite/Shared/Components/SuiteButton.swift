import SwiftUI

/// Full-width pill CTA.
///
/// - `.primary` — amber fill, dark label. The default across dark/photo screens.
/// - `.secondary` — 1px dark outline, dark label.
/// - `.formPrimary` — dark fill, white label. Used on light form screens
///   ("Send reset link", the sign-up sheet's "Log in").
/// Disabled state: `fillStrong` fill, `textDisabled` label (any style).
struct SuiteButton: View {
    enum Style { case primary, secondary, formPrimary }

    var title: String
    var style: Style = .primary
    var showsLeadingPlus: Bool = false
    var isEnabled: Bool = true
    var height: CGFloat = Theme.Size.cta
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if showsLeadingPlus {
                    Text("+").font(.archivo(22, .regular)).offset(y: -2)
                }
                Text(title).font(.Suite.button)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(background)
            .overlay(
                Capsule().strokeBorder(Theme.Palette.textPrimary,
                                       lineWidth: style == .secondary && isEnabled ? 1 : 0)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var foreground: Color {
        guard isEnabled else { return Theme.Palette.textDisabled }
        switch style {
        case .primary:     return Theme.Palette.onAccent
        case .secondary:   return Theme.Palette.textPrimary
        case .formPrimary: return Theme.Palette.surface
        }
    }

    private var background: Color {
        guard isEnabled else { return Theme.Palette.fillStrong }
        switch style {
        case .primary:     return Theme.Palette.accent
        case .secondary:   return .clear
        case .formPrimary: return Theme.Palette.textPrimary
        }
    }
}
