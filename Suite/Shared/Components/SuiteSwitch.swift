import SwiftUI

/// On/off switch — 50 × 30 visual (amber when on). Built on a real `Toggle` with
/// a custom style so it keeps the handoff look while VoiceOver / Voice Control /
/// Switch Control get the toggle trait, an on/off value, and a full 44 pt hit
/// target. Honours Reduce Motion.
struct SuiteSwitch: View {
    @Binding var isOn: Bool
    /// Spoken label. Set it when the switch isn't already beside its own visible
    /// label; hidden visually, used by assistive tech only.
    var accessibilityLabel: String = ""

    var body: some View {
        Toggle(isOn: $isOn) {
            if !accessibilityLabel.isEmpty { Text(accessibilityLabel) }
        }
        .labelsHidden()
        .toggleStyle(SuiteToggleStyle())
    }
}

private struct SuiteToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let toggle = {
            if reduceMotion {
                configuration.isOn.toggle()
            } else {
                withAnimation(.snappy(duration: 0.18)) { configuration.isOn.toggle() }
            }
        }
        return ZStack(alignment: configuration.isOn ? .trailing : .leading) {
            Capsule()
                .fill(configuration.isOn ? Theme.Palette.accent : Theme.Palette.track)
            Circle()
                .fill(configuration.isOn ? Theme.Palette.surface : Theme.Palette.textTertiary)
                .padding(3)
        }
        .frame(width: 50, height: 30)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture(perform: toggle)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? Text("On") : Text("Off"))
        .accessibilityAction(.default, toggle)
    }
}
