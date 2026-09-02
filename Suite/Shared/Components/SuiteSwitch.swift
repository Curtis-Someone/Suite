import SwiftUI

/// On/off switch — 50 × 30. On = amber track + white knob; off = `track`
/// track + `textTertiary` knob.
struct SuiteSwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Theme.Palette.accent : Theme.Palette.track)
            Circle()
                .fill(isOn ? Theme.Palette.surface : Theme.Palette.textTertiary)
                .padding(3)
        }
        .frame(width: 50, height: 30)
        .contentShape(Capsule())
        .onTapGesture {
            withAnimation(.snappy(duration: 0.18)) { isOn.toggle() }
        }
    }
}
