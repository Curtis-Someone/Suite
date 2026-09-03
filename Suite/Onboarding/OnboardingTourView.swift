import SwiftUI

/// 03–05 · Onboarding tour — one card per tab. Swipe or tap the CTA to advance;
/// the CTA on the last card finishes the tour.
struct OnboardingTourView: View {
    var onDone: () -> Void
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            card(index: 0,
                 caption: "Every country you set foot in fills\nin on your own world map.",
                 cta: "Track countries") { mapHero }
            card(index: 1,
                 caption: "One checklist per trip, so nothing\ngets left on the bed.",
                 cta: "Make your suitcase") { suitcaseHero }
            card(index: 2,
                 caption: "Countries, cities and days on the\nroad, stamped in one place.",
                 cta: "Get started") { passportHero }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Theme.Palette.surface.ignoresSafeArea())
    }

    private func card<Hero: View>(
        index: Int, caption: String, cta: String, @ViewBuilder hero: () -> Hero
    ) -> some View {
        let heroView = hero()
        return GeometryReader { geo in
            VStack(spacing: 0) {
                ZStack {
                    heroView
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                }
                .frame(height: geo.size.height * 0.60)
                .frame(maxWidth: .infinity)
                .background(Theme.Palette.panel)
                .clipShape(.rect(bottomLeadingRadius: 44, bottomTrailingRadius: 44))

                VStack(spacing: 28) {
                    Spacer(minLength: 0)
                    Text(caption)
                        .font(.Suite.bodyL)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(Theme.Palette.textSecondary)
                    SuiteButton(title: cta) {
                        if index < 2 { withAnimation { page = index + 1 } } else { onDone() }
                    }
                    Dots(count: 3, active: index)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                .frame(maxHeight: .infinity)
            }
        }
        .tag(index)
    }

    private var mapHero: some View {
        VStack(spacing: 26) {
            Image("WorldMap")
                .resizable().scaledToFit()
                .frame(height: 222)
                .blendMode(.multiply)
            StatStrip(stats: [
                StatColumn(value: "10", unit: " / 195", caption: "countries", valueSize: 30, alignment: .center),
                StatColumn(value: "5", unit: "%", caption: "of the world", valueSize: 30, alignment: .center),
            ])
        }
    }

    private var suitcaseHero: some View {
        VStack(spacing: 22) {
            Image("SuitcaseOpen")
                .resizable().scaledToFit()
                .frame(height: 300)
                .blendMode(.multiply)
            HStack(spacing: 10) {
                ForEach(["6 outfits", "2 pairs shoes", "Chargers"], id: \.self) { tag in
                    HStack(spacing: 8) {
                        Circle().fill(Theme.Palette.accent).frame(width: 6, height: 6)
                        Text(tag).font(.archivo(12, .medium)).foregroundStyle(Theme.Palette.textBody)
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 30)
                    .background(Theme.Palette.fillStrong, in: Capsule())
                }
            }
        }
    }

    private var passportHero: some View {
        Image("PassportBook")
            .resizable().scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, -24)
            .blendMode(.multiply)
    }
}

/// Pagination dots — active one amber, the rest `track`.
struct Dots: View {
    var count: Int
    var active: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == active ? Theme.Palette.accent : Theme.Palette.track)
                    .frame(width: 9, height: 9)
            }
        }
    }
}
