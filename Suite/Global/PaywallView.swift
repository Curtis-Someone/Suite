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

            HStack(alignment: .firstTextBaseline) {
                Button { dismiss() } label: {
                    SuiteIconView(icon: .close, size: 18, color: .white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Close")

                Spacer(minLength: 8)

                Button {
                    Task { working = true; await entitlements.restore(); working = false
                        if entitlements.isPro { withAnimation { purchased = true } } }
                } label: {
                    Text("Already purchased? Restore")
                        .font(.archivo(13, .semibold))
                        .underline()
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)

            VStack(spacing: 0) {
                Spacer().frame(height: 188)

                (Text("Unlock Suite ") + Text("Pro").foregroundColor(Theme.Palette.accent))
                    .font(.archivo(30, .heavy)).tracking(30 * -0.02)
                    .multilineTextAlignment(.center)
                    .lineLimit(2).minimumScaleFactor(0.6)
                    .foregroundStyle(Theme.Palette.textHeading)

                Text("Track everything. Pack smarter.\nNever hit a limit.")
                    .font(.archivo(14)).lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
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

                (billingLine + Text("\n")
                 + Text("Terms of Use").underline() + Text(" apply."))
                    .font(.archivo(11)).lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
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

    // MARK: billing copy

    private func displayPrice(_ id: ProductID) -> String {
        entitlements.product(for: id)?.displayPrice ?? id.fallbackPrice
    }

    /// Trial / billing terms for the *selected* plan — the current single line
    /// misstates terms for Monthly and Lifetime (HIG · In-App Purchase).
    private var billingLine: Text {
        switch plan {
        case .proYearly:
            Text("5-day free trial, then \(displayPrice(.proYearly)) / year. Cancel anytime.")
        case .proMonthly:
            Text("\(displayPrice(.proMonthly)) / month. Cancel anytime.")
        case .proLifetime:
            Text("One payment of \(displayPrice(.proLifetime)). No subscription.")
        }
    }

    /// Yearly saving vs. paying monthly for a year — from StoreKit `Decimal`s
    /// when loaded, else the CLAUDE.md-derived 47%.
    private var savingsPercent: Int {
        guard let yearly = entitlements.product(for: .proYearly)?.price,
              let monthly = entitlements.product(for: .proMonthly)?.price,
              monthly > 0 else { return 47 }
        let saved = (monthly * 12 - yearly) / (monthly * 12)
        return Int((saved as NSDecimalNumber).doubleValue * 100)
    }

    // MARK: plan cards

    @ViewBuilder
    private func planCard(_ id: ProductID) -> some View {
        let selected = plan == id
        let price = displayPrice(id)

        Button { plan = id } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title(id))
                        .font(.archivo(17, .bold))
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .foregroundStyle(muted(id) ? Theme.Palette.textSecondary : Theme.Palette.textHeading)
                    if id == .proYearly {
                        Text("5 days free")
                            .font(.jetBrainsMono(11, .bold))
                            .foregroundStyle(Theme.Palette.onAccent)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.horizontal, 10).frame(minHeight: 24)
                            .background(Theme.Palette.accent, in: Capsule())
                    } else if id == .proLifetime {
                        Text("one payment")
                            .font(.archivo(12))
                            .foregroundStyle(Theme.Palette.textTertiary)
                    }
                }
                Spacer(minLength: 10)
                VStack(alignment: .trailing, spacing: 3) {
                    (Text(price) + Text(suffix(id)).font(.archivo(13)).foregroundColor(Theme.Palette.textSecondary))
                        .font(.archivo(22, .bold)).tracking(22 * -0.02)
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .foregroundStyle(muted(id) ? Theme.Palette.textSecondary : Theme.Palette.textHeading)
                    if id == .proYearly {
                        Text(weekly(id))
                            .font(.jetBrainsMono(11))
                            .lineLimit(1).minimumScaleFactor(0.7)
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
                    Text("SAVE \(savingsPercent)%")
                        .font(.jetBrainsMono(11, .bold))
                        .foregroundStyle(Theme.Palette.onAccent)
                        .padding(.horizontal, 10).frame(minHeight: 22)
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
    /// "≈ $0.48/wk" — from the StoreKit `Decimal` + locale-correct format style
    /// when the product is loaded, else parsed from the fallback string.
    private func weekly(_ id: ProductID) -> String {
        if let product = entitlements.product(for: id) {
            let perWeek = product.price / Decimal(52)
            return "≈ \(perWeek.formatted(product.priceFormatStyle)) / wk"
        }
        let digits = id.fallbackPrice.filter { $0.isNumber || $0 == "." }
        guard let value = Double(digits) else { return "" }
        return String(format: "≈ $%.2f / wk", value / 52)
    }
}
