import SwiftUI

/// Touch-down feedback for surfaces where the whole thing is the button
/// (cards, list rows, plan tiles). Swap in for `.buttonStyle(.plain)`.
struct SuitePressStyle: ButtonStyle {
    var scale: CGFloat = 0.985
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.62 : 1)
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SuitePressStyle {
    static var suitePress: SuitePressStyle { SuitePressStyle() }
}
