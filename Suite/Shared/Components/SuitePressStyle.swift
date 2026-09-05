import SwiftUI

/// Press feedback for whole-surface buttons (trip cards, list rows, plan cards,
/// CTAs) that otherwise use `.buttonStyle(.plain)` and show nothing on
/// touch-down. A tappable surface that doesn't react reads as non-interactive
/// (HIG · Feedback).
///
/// Honours Reduce Motion: drops the scale and the animation, keeps a plain
/// opacity dim.
struct SuitePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressBody(configuration: configuration)
    }

    private struct PressBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let pressed = configuration.isPressed
            configuration.label
                .opacity(pressed ? 0.62 : 1)
                .scaleEffect(reduceMotion ? 1 : (pressed ? 0.985 : 1))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: pressed)
        }
    }
}

extension ButtonStyle where Self == SuitePressStyle {
    /// `.buttonStyle(.suitePress)`
    static var suitePress: SuitePressStyle { SuitePressStyle() }
}
