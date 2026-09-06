import SwiftUI

/// R1–R4 · the reward overlay — dark scrim, a centred white card with an amber
/// ray-burst behind an 88pt badge, headline + one line of copy. Taps or a ~3.4s
/// timer dismiss it.
struct RewardOverlayView: View {
    let reward: Reward
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.62 : 0)
                .ignoresSafeArea()
                .onTapGesture { close() }

            card
                .scaleEffect(reduceMotion ? 1 : (shown ? 1 : 0.92))
                .opacity(shown ? 1 : 0)
                .padding(.horizontal, 34)
                .accessibilityAddTraits(.isModal)
                .accessibilityAction { close() }
        }
        .onAppear {
            if reduceMotion { shown = true }
            else { withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { shown = true } }
        }
        .task {
            let seconds: Double = UIAccessibility.isVoiceOverRunning ? 12 : 6
            try? await Task.sleep(for: .seconds(seconds))
            close()
        }
    }

    private func close() {
        guard shown else { return }
        withAnimation(.easeIn(duration: 0.22)) { shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { onDismiss() }
    }

    private var card: some View {
        VStack(spacing: 0) {
            ZStack {
                RayBurst().frame(width: 190, height: 190)
                LucideIcon(name: reward.iconName, size: 40, color: Theme.Palette.onAccent)
                    .frame(width: 88, height: 88)
                    .background(Theme.Palette.accent, in: Circle())
            }
            .frame(width: 220, height: 128)
            .clipped()
            .padding(.top, -44)

            Text(reward.title)
                .font(.archivo(25, .heavy)).tracking(25 * -0.02)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Palette.textHeading)
                .padding(.top, 4)

            Text(reward.message)
                .font(.archivo(14))
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Theme.Palette.textSecondary)
                .padding(.top, 10)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 26))
        .overlay(alignment: .bottom) {
            Capsule().fill(Theme.Palette.textPrimary.opacity(0.18))
                .frame(width: 132, height: 5)
                .padding(.bottom, 10)
        }
        .shadow(color: .black.opacity(0.45), radius: 30, y: 24)
    }
}

/// 16 amber rays radiating from the centre — long/bright and short/faint,
/// alternating, matching the handoff burst.
private struct RayBurst: View {
    var body: some View {
        GeometryReader { geo in
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let inner = geo.size.width * 0.28
            Canvas { ctx, _ in
                for i in 0..<16 {
                    let long = i.isMultiple(of: 2)
                    let angle = Double(i) / 16 * 2 * .pi
                    let outer = inner + (long ? geo.size.width * 0.22 : geo.size.width * 0.12)
                    var path = Path()
                    path.move(to: point(c, inner, angle))
                    path.addLine(to: point(c, outer, angle))
                    ctx.stroke(path,
                               with: .color(Theme.Palette.accent.opacity(long ? 0.7 : 0.4)),
                               style: StrokeStyle(lineWidth: long ? 3 : 2, lineCap: .round))
                }
            }
        }
    }

    private func point(_ c: CGPoint, _ r: CGFloat, _ a: Double) -> CGPoint {
        CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
    }
}
