import Foundation
import StoreKit
import Observation

// =====================================================================
// SUITE — Free/Pro enforcement (ported from Documentos/SuiteEntitlements.swift)
//
// Every gated action goes through `PackingGate`, which reads `isPro` and
// returns `.allowed` or `.blocked(reason:)`. Views never check `isPro`
// directly — that keeps every limit in one place (`PlanLimits`) and every
// trigger point consistent.
// =====================================================================

// MARK: - Entitlements

/// Single source of truth for Pro status. StoreKit is the real authority;
/// `UserSettings.isProSubscriber` is a local cache so gate checks are instant
/// and work offline. Also owns product loading + purchase/restore.
@Observable
@MainActor
final class Entitlements {
    static let shared = Entitlements()

    private(set) var isPro = false
    private(set) var products: [Product] = []

    private var updatesTask: Task<Void, Never>?

    private init() {}

    /// Call once at launch.
    func start() async {
        updatesTask = Task.detached { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self?.refresh()
                }
            }
        }
        await loadProducts()
        await refresh()
        if ProcessInfo.processInfo.arguments.contains("-proUnlocked") { isPro = true }
    }

    func loadProducts() async {
        let ids = ProductID.allCases.map(\.rawValue)
        products = (try? await Product.products(for: ids))?
            .sorted { rank($0) < rank($1) } ?? []
    }

    /// Recompute `isPro` from the current entitlements.
    func refresh() async {
        var pro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, ProductID(rawValue: t.productID) != nil {
                pro = true
            }
        }
        isPro = pro
    }

    /// Returns true if the purchase completed (or is pending family approval).
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        guard let result = try? await product.purchase() else { return false }
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await refresh()
                return true
            }
            return false
        case .pending:
            return true
        case .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    private func rank(_ product: Product) -> Int {
        ProductID(rawValue: product.id).map { ProductID.allCases.firstIndex(of: $0) ?? 9 } ?? 9
    }
}

enum ProductID: String, CaseIterable {
    case proYearly   = "com.suiteapp.Suite.pro.yearly"
    case proMonthly  = "com.suiteapp.Suite.pro.monthly"
    case proLifetime = "com.suiteapp.Suite.pro.lifetime"

    /// Prices from CLAUDE.md — shown when StoreKit products fail to load.
    var fallbackPrice: String {
        switch self {
        case .proYearly:   "$24.99"
        case .proMonthly:  "$3.99"
        case .proLifetime: "$42.99"
        }
    }
}

// MARK: - Plan limits
// Every number/boolean from the Free/Pro table lives here and nowhere else.

enum PlanLimits {
    static func maxActiveTrips(isPro: Bool) -> Int? { isPro ? nil : 2 }        // nil == unlimited
    static func maxArchivedTripsShown(isPro: Bool) -> Int? { isPro ? nil : 3 }
    static func maxSuitcasesPerTrip(isPro: Bool) -> Int? { isPro ? nil : 1 }
    static func templatesAllowed(isPro: Bool) -> Bool { isPro }
    static func travelersAllowed(isPro: Bool) -> Bool { isPro }               // bundled with iCloud sync — B11
    static func smartWeatherSuggestionsAllowed(isPro: Bool) -> Bool { isPro } // suggestions only; basic forecast is free
    static func exportAllowed(isPro: Bool) -> Bool { isPro }
    // Basic passport tracking (country count, world %) is intentionally NOT gated —
    // it's seeded at onboarding before anyone sees a paywall.
}

// MARK: - Gate

enum GateResult {
    case allowed
    case blocked(reason: UpsellMoment)
}

/// One case per paywall trigger point — keeps the upsell copy specific to what
/// the person was just trying to do.
enum UpsellMoment: String, Identifiable {
    case secondSuitcase
    case thirdActiveTrip
    case saveTemplate
    case addTraveler        // wired in B11 with the invite/sync flow
    case smartSuggestions
    case exportTrip
    var id: String { rawValue }
}

/// The only place that decides yes/no on a Pro-gated action.
enum PackingGate {
    static func canCreateTrip(existingTrips: [Trip], isPro: Bool) -> GateResult {
        guard let limit = PlanLimits.maxActiveTrips(isPro: isPro) else { return .allowed }
        let active = existingTrips.filter { $0.status != .past && !$0.isArchived }.count
        return active < limit ? .allowed : .blocked(reason: .thirdActiveTrip)
    }

    static func canAddSuitcase(to trip: Trip, isPro: Bool) -> GateResult {
        guard let limit = PlanLimits.maxSuitcasesPerTrip(isPro: isPro) else { return .allowed }
        return trip.suitcases.count < limit ? .allowed : .blocked(reason: .secondSuitcase)
    }

    static func canSaveTemplate(isPro: Bool) -> GateResult {
        PlanLimits.templatesAllowed(isPro: isPro) ? .allowed : .blocked(reason: .saveTemplate)
    }

    static func canAddTraveler(isPro: Bool) -> GateResult {
        PlanLimits.travelersAllowed(isPro: isPro) ? .allowed : .blocked(reason: .addTraveler)
    }

    static func canShowSmartSuggestions(isPro: Bool) -> GateResult {
        PlanLimits.smartWeatherSuggestionsAllowed(isPro: isPro) ? .allowed : .blocked(reason: .smartSuggestions)
    }

    static func canExport(isPro: Bool) -> GateResult {
        PlanLimits.exportAllowed(isPro: isPro) ? .allowed : .blocked(reason: .exportTrip)
    }
}

// MARK: - Archive display (read-side limit, not a block)

extension Array where Element == Trip {
    func visibleArchive(isPro: Bool) -> [Trip] {
        let past = filter { $0.isArchived || $0.status == .past }
            .sorted { $0.endDate > $1.endDate }
        guard let limit = PlanLimits.maxArchivedTripsShown(isPro: isPro) else { return past }
        return Array(past.prefix(limit))
    }
}
