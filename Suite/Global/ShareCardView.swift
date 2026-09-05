import SwiftUI
import SwiftData

/// G4 · Share card — a shareable "my world so far" stat card over the map.
struct ShareCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var visits: [VisitedPlace]

    private var stats: PassportStats { PassportStats(visits: visits) }
    private var visitedCodes: Set<String> { stats.countryCodes }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button { dismiss() } label: {
                    SuiteIconView(icon: .close, size: 18, color: Theme.Palette.textPrimary)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().strokeBorder(Theme.Palette.border).frame(width: 42, height: 42))
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Close")
                Text("Share your passport")
                    .font(.Suite.titleS).tracking(22 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)

            card
                .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                ShareLink(item: renderCard(), preview: SharePreview("My Suite passport", image: renderCard())) {
                    Text("Share")
                        .font(.Suite.button)
                        .foregroundStyle(Theme.Palette.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: Theme.Size.cta)
                        .background(Theme.Palette.accent, in: Capsule())
                }
                SuiteButton(title: "Save image", style: .secondary, height: Theme.Size.ctaCompact) {
                    let ui = ImageRenderer(content: card).uiImage
                    if let ui { UIImageWriteToSavedPhotosAlbum(ui, nil, nil, nil) }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
    }

    private var card: some View {
        ZStack {
            WorldMapView(visited: visitedCodes, interactive: false)
                .allowsHitTesting(false)
            LinearGradient(colors: [.black.opacity(0.55), .black.opacity(0.2), .black.opacity(0.92)],
                           startPoint: .top, endPoint: .bottom)
            VStack(spacing: 8) {
                Text("My world so far")
                    .font(.jetBrainsMono(10)).tracking(2).textCase(.uppercase)
                    .foregroundStyle(Theme.Palette.accent)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(stats.countryCount)").font(.archivo(60, .heavy)).tracking(-2.4)
                        .foregroundStyle(.white)
                    Text(" / 195").font(.archivo(32, .bold)).foregroundStyle(Theme.Palette.accent)
                }
                Text("countries · \(Int((stats.worldPercent * 100).rounded()))% of the world")
                    .font(.archivo(15, .medium))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
        .frame(height: 470)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(alignment: .bottomLeading) {
            Wordmark(size: 15, wordColor: .white).padding(20)
        }
    }

    @MainActor private func renderCard() -> Image {
        let renderer = ImageRenderer(content: card.frame(width: 340, height: 470))
        renderer.scale = 3
        return renderer.uiImage.map(Image.init(uiImage:)) ?? Image(systemName: "photo")
    }
}
