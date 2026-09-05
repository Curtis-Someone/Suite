import SwiftUI

/// Shown right after a successful purchase / restore — a full amber screen with
/// a white success badge whose checkmark draws itself in, a one-shot pop and an
/// expanding pulse ring. Everything is white on the amber.
struct PurchaseConfirmationView: View {
    var onDone: () -> Void

    @State private var badgeIn = false
    @State private var checkDraw = false
    @State private var pop = false
    @State private var pulse = false
    @State private var textIn = false

    private let badge: CGFloat = 132

    var body: some View {
        ZStack {
            Theme.Palette.accent.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    // expanding pulse rings, kicked off when the check lands
                    ForEach(0..<2) { i in
                        Circle()
                            .stroke(.white, lineWidth: 2)
                            .frame(width: badge, height: badge)
                            .scaleEffect(pulse ? 2.1 : 1)
                            .opacity(pulse ? 0 : 0.45)
                            .animation(.easeOut(duration: 1.0).delay(Double(i) * 0.12), value: pulse)
                    }

                    Circle()
                        .fill(.white)
                        .frame(width: badge, height: badge)

                    Checkmark()
                        .trim(from: 0, to: checkDraw ? 1 : 0)
                        .stroke(Theme.Palette.accent,
                                style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                        .frame(width: badge * 0.52, height: badge * 0.52)
                }
                .scaleEffect(badgeIn ? (pop ? 1.08 : 1) : 0.3)
                .opacity(badgeIn ? 1 : 0)

                Spacer().frame(height: 40)

                Text("You're Pro.")
                    .font(.archivo(32, .heavy)).tracking(32 * -0.02)
                    .foregroundStyle(.white)
                    .opacity(textIn ? 1 : 0)
                    .offset(y: textIn ? 0 : 10)

                Spacer().frame(height: 12)

                Text("Every limit is gone. Unlimited trips,\ntemplates, sync and the full passport.")
                    .font(.archivo(15)).lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .opacity(textIn ? 1 : 0)

                Spacer()

                Button(action: onDone) {
                    Text("Start exploring")
                        .font(.archivo(17, .bold))
                        .foregroundStyle(Theme.Palette.accent)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
                .opacity(textIn ? 1 : 0)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear(perform: play)
        .task {
            try? await Task.sleep(for: .seconds(4.5))
            onDone()
        }
    }

    private func play() {
        withAnimation(.spring(response: 0.44, dampingFraction: 0.58)) { badgeIn = true }
        withAnimation(.easeOut(duration: 0.34).delay(0.24)) { checkDraw = true }
        // one-shot pop as the check completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.56) {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.4)) { pop = true }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.12)) { pop = false }
            pulse = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.62)) { textIn = true }
    }
}

/// A tick sized to its frame; drawn with an animated `.trim`.
private struct Checkmark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.55))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.84))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.94, y: rect.minY + rect.height * 0.18))
        return p
    }
}
