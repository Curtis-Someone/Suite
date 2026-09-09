import SwiftUI

/// Pro1 · Benefits carousel — a light browse of what Pro adds, before the
/// pricing screen. "See plans" opens `PaywallView`.
struct ProBenefitsView: View {
    @Environment(\.dismiss) private var dismiss
    private let entitlements = Entitlements.shared
    @State private var page = 0
    @State private var showPlans = false

    private struct Benefit { let icon, title, body: String }
    private let benefits = [
        Benefit(icon: "luggage", title: "Unlimited trips & suitcases",
                body: "Keep as many active trips and packing lists going as you like."),
        Benefit(icon: "calendar", title: "Your full archive",
                body: "Every trip you've taken stays in your history — Free keeps only the last three."),
        Benefit(icon: "book-open", title: "Templates",
                body: "Turn a packed trip into a reusable list you start from next time."),
        Benefit(icon: "share-2", title: "PDF & Messages export",
                body: "Send any packing list as a PDF, or share it straight into Messages."),
        Benefit(icon: "landmark", title: "Passport stats",
                body: "Your places-been stats — every country and city you've visited, kept like stamps."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    SuiteIconView(icon: .close, size: 20, color: Theme.Palette.textPrimary)
                }
                Spacer()
                Text("Suite Pro").font(.archivo(18, .bold)).tracking(18 * -0.01)
                    .foregroundStyle(Theme.Palette.textHeading)
                Spacer()
                SuiteIconView(icon: .close, size: 20, color: .clear)   // balances the title
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Text("One upgrade unlocks everything.")
                .font(.archivo(14)).foregroundStyle(Theme.Palette.textSecondary)
                .padding(.top, 18)

            TabView(selection: $page) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                    VStack(spacing: 26) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Theme.Palette.surface)
                            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Theme.Palette.border))
                            .overlay(
                                LucideIcon(name: benefit.icon, size: 64, color: Theme.Palette.accent))
                            .frame(width: 220, height: 170)

                        VStack(spacing: 8) {
                            Text(benefit.title)
                                .font(.archivo(22, .bold)).tracking(22 * -0.02)
                                .foregroundStyle(Theme.Palette.textHeading)
                            Text(benefit.body)
                                .font(.archivo(14)).lineSpacing(3)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.Palette.textSecondary)
                        }
                        .padding(.horizontal, 32)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(benefits.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Theme.Palette.accent : Theme.Palette.border)
                        .frame(width: i == page ? 20 : 7, height: 7)
                }
            }
            .padding(.bottom, 24)

            Button { showPlans = true } label: {
                Text("See plans")
                    .font(.archivo(17, .bold))
                    .foregroundStyle(Theme.Palette.onAccent)
                    .frame(maxWidth: .infinity).frame(height: Theme.Size.cta)
                    .background(Theme.Palette.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .onChange(of: showPlans) { _, showing in
            if !showing && entitlements.isPro { dismiss() }
        }
        .fullScreenCover(isPresented: $showPlans) {
            PaywallView()
                .overlay(alignment: .topLeading) {
                    Button { showPlans = false } label: {
                        SuiteIconView(icon: .close, size: 18, color: .white)
                            .frame(width: 42, height: 42)
                    }
                    .padding(.leading, 12).padding(.top, 8)
                }
        }
    }
}
