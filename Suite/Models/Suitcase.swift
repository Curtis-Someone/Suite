import Foundation
import SwiftData

@Model
final class Suitcase {
    var name: String = ""          // "Carry-on", "Checked bag", or custom
    var createdAt: Date = Date.now
    var trip: Trip?

    @Relationship(deleteRule: .cascade, inverse: \Item.suitcase)
    var items: [Item] = []

    init(name: String, trip: Trip? = nil) {
        self.name = name
        self.trip = trip
        self.createdAt = .now
    }

    /// Readiness formula (rewards/progress spec): a freshly created suitcase
    /// starts at an ~18% baseline just for existing — never 0% — and the
    /// remaining ~82% fills in as items get checked off.
    var progress: Double {
        let baseline = 0.18
        guard !items.isEmpty else { return baseline }
        let packedRatio = Double(items.filter(\.isPacked).count) / Double(items.count)
        return baseline + (1 - baseline) * packedRatio
    }
}
