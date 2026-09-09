import SwiftUI

/// 02 · Setting up — the ring fills 0 → 100 % with the number counting up, the
/// checklist ticking along with it, then it advances into the app.
struct SettingUpView: View {
    var onDone: () -> Void

    private let steps = ["Setting up your globe", "Loading your passport", "Packing your suitcase"]
    private let duration: Double = 1.8

    @State private var progress: Double = 0

    private var stepsDone: Int {
        // Each checklist row ticks as the ring passes its share.
        (1...steps.count).reduce(0) { count, n in
            progress >= Double(n) / Double(steps.count) - 0.001 ? count + 1 : count
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            CircularGauge(value: progress, size: 190, ringWidth: 12)
                .padding(.bottom, 40)
            Text("Setting up your\ntrip world…")
                .font(.Suite.titleL).tracking(27 * -0.02)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.bottom, 38)

            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, label in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(i < stepsDone ? Theme.Palette.accent : .clear)
                            .overlay(Circle().strokeBorder(Theme.Palette.track, lineWidth: i < stepsDone ? 0 : 2))
                            .frame(width: 26, height: 26)
                            .overlay {
                                if i < stepsDone {
                                    SuiteIconView(icon: .check, size: 14, color: Theme.Palette.onAccent)
                                }
                            }
                        Text(label)
                            .font(.archivo(16, .medium))
                            .foregroundStyle(i < stepsDone ? Theme.Palette.textHeading : Theme.Palette.textTertiary)
                    }
                    .animation(.easeOut(duration: 0.2), value: stepsDone)
                }
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.surface.ignoresSafeArea())
        .task { await fill() }
    }

    private func fill() async {
        let stepCount = 48
        let interval = duration / Double(stepCount)
        for step in 1...stepCount {
            try? await Task.sleep(for: .seconds(interval))
            withAnimation(.linear(duration: interval)) {
                progress = Double(step) / Double(stepCount)
            }
        }
        try? await Task.sleep(for: .seconds(0.35))
        onDone()
    }
}
