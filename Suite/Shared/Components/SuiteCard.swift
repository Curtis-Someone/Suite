import SwiftUI

/// Card container.
///
/// - `.sunken` — `surfaceSunken` fill, no border. The default (stat cards,
///   grouped settings rows).
/// - `.surface` — white fill, 1px `border`. Used for list rows / cards that
///   sit directly on the ground.
struct SuiteCard<Content: View>: View {
    enum Style { case sunken, surface }

    var style: Style = .sunken
    var cornerRadius: CGFloat = Theme.Radius.card
    var padding: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Theme.Palette.border, lineWidth: style == .surface ? 1 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var fill: Color {
        switch style {
        case .sunken:  Theme.Palette.surfaceSunken
        case .surface: Theme.Palette.surface
        }
    }
}
