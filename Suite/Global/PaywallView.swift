import SwiftUI
import SwiftData
import StoreKit

/// Pro2 · Paywall / pricing. Map hero, three plans (yearly anchored), Continue +
/// Restore. Prices come from StoreKit when loaded, else the CLAUDE.md fallbacks.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    private let entitlements = Entitlements.shared
    @Query private var visits: [VisitedPlace]

    @State private var plan: ProductID = .proYearly
    @State private var working = false
    @State private var loadError = false
    @State private var purchased = false

    private var visitedCodes: Set<String> { Set(visits.map { $0.countryCode.uppercased() }) }

    var body: some View {
        if purchased {
            PurchaseConfirmationView { dismiss() }
                .transition(.opacity)
        } else {
            paywall
        }
    }

    private var paywall: some View {
        ZStack(alignment: .top) {
            Theme.Palette.ground.ignoresSafeArea()

            WorldMapView(visited: visitedCodes, interactive: false)
                .allowsHitTesting(false)
                .frame(height: 300)
                .overlay(
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.5), location: 0),
                            .init(color: .black.opacity(0.2), location: 0.4),
                            .init(color: Theme.Palette.ground, location: 1),
                        ],
                        startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea(edges: .top)

            Button {
                Task { working = true; await entitlements.restore(); working = false
                    if entitlements.isPro { withAnimation { purchased = true } } }
            } label: {
                Text("Already purchased? Restore")
                    .font(.archivo(13, .semibold))
                    .underline()
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 20)
            .padding(.top, 12)

            VStack(spacing: 0) {
                Spacer().frame(height: 188)

                (Text("Unlock Suite ") + Text("Pro").foregroundColor(Theme.Palette.accent))
                    .font(.archivo(30, .heavy)).tracking(30 * -0.02)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.textHeading)

                Text("Every trip. Every list.\nNo limits.")
                    .font(.archivo(14)).lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .padding(.top, 10)

                planCard(.proYearly).padding(.top, 26)
                planCard(.proMonthly).padding(.top, 12)
                planCard(.proLifetime).padding(.top, 12)

                Spacer(minLength: 20)

                Button {
                    Task {
                        working = true
                        if entitlements.product(for: plan) == nil { await entitlements.loadProducts() }
                        guard let product = entitlements.product(for: plan) else {
                            working = false
                            loadError = true
                            return
                        }
                        let ok = await entitlements.purchase(product)
                        working = false
                        if entitlements.isPro {
                            withAnimation { purchased = true }   // → confirmation screen
                        } else if ok {
                            dismiss()                            // pending family approval
                        }
                    }
                } label: {
                    ZStack {
                        if working { ProgressView().tint(Theme.Palette.onAccent) }
                        else { Text("Continue").font(.archivo(17, .bold)) }
                    }
                    .foregroundStyle(Theme.Palette.onAccent)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Theme.Palette.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(working)
                .padding(.top, 8)

                (Text("5-day free trial, then billed yearly. Cancel anytime.\n")
                 + Text("Terms of Use").underline() + Text(" apply."))
                    .font(.archivo(11)).lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .task {
            if entitlements.products.isEmpty { await entitlements.loadProducts() }
        }
        .alert("Plans unavailable", isPresented: $loadError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Couldn't load the plans from the App Store. In the Simulator this needs a StoreKit Configuration set on the scheme (Edit Scheme → Run → Options → StoreKit Configuration → Suite.storekit).")
        }
    }

    // MARK: plan cards

    @ViewBuilder
    private func planCard(_ id: ProductID) -> some View {
        let selected = plan == id
        let price = entitlements.product(for: id)?.displayPrice ?? id.fallbackPrice

        Button { plan = id } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title(id))
                        .font(.archivo(17, .bold))
                        .foregroundStyle(muted(id) ? Theme.Palette.textSecondary : Theme.Palette.textHeading)
                    if id == .proYearly {
                        Text("5 days free")
                            .font(.jetBrainsMono(11, .bold))
                            .foregroundStyle(Theme.Palette.onAccent)
                            .padding(.horizontal, 10).frame(height: 24)
                            .background(Theme.Palette.accent, in: Capsule())
                    } else if id == .proLifetime {
                        Text("one payment")
                            .font(.archivo(12))
                            .foregroundStyle(Theme.Palette.textTertiary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    (Text(price) + Text(suffix(id)).font(.archivo(13)).foregroundColor(Theme.Palette.textSecondary))
                        .font(.archivo(22, .bold)).tracking(22 * -0.02)
                        .foregroundStyle(muted(id) ? Theme.Palette.textSecondary : Theme.Palette.textHeading)
                    if id == .proYearly {
                        Text(weekly(price))
                            .font(.jetBrainsMono(11))
                            .foregroundStyle(Theme.Palette.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            .background(background(id), in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(selected ? Theme.Palette.accent : Theme.Palette.border,
                                  lineWidth: selected ? 1.6 : 1))
            .overlay(alignment: .topTrailing) {
                if id == .proYearly {
                    Text("SAVE 47%")
                        .font(.jetBrainsMono(11, .bold))
                        .foregroundStyle(Theme.Palette.onAccent)
                        .padding(.horizontal, 10).frame(height: 22)
                        .background(Theme.Palette.accent, in: Capsule())
                        .offset(x: -16, y: -11)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func title(_ id: ProductID) -> String {
        switch id { case .proYearly: "Yearly"; case .proMonthly: "Monthly"; case .proLifetime: "Lifetime" }
    }
    private func suffix(_ id: ProductID) -> String {
        switch id { case .proYearly: "/yr"; case .proMonthly: "/mo"; case .proLifetime: "" }
    }
    private func muted(_ id: ProductID) -> Bool { id == .proLifetime && plan != .proLifetime }
    private func background(_ id: ProductID) -> Color {
        switch id {
        case .proYearly:   Theme.Palette.accent.opacity(0.10)
        case .proMonthly:  Theme.Palette.surface
        case .proLifetime: .clear
        }
    }
    /// "≈ $0.48/wk" from a "$24.99" string.
    private func weekly(_ price: String) -> String {
        let digits = price.filter { $0.isNumber || $0 == "." }
        guard let value = Double(digits) else { return "" }
        return String(format: "≈ $%.2f/wk", value / 52)
    }
}
