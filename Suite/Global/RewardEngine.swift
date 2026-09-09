import Foundation

/// Builds the four reward payloads from real model values and hands them to
/// `RewardPresenter`. Call these right after the triggering `context.save()`.
@MainActor
enum RewardEngine {
    static let milestones = [5, 10, 25, 50, 100]

    /// R1 — every item in the suitcase is now packed.
    static func suitcasePacked(trip: Trip, itemCount: Int) {
        let place = trip.destinationCity.isEmpty ? trip.destinationCountry : trip.destinationCity
        let where_ = place.isEmpty ? trip.name : place
        let days = Calendar.current.dateComponents([.day], from: .now, to: trip.startDate).day ?? 0
        let tail = days >= 1
            ? "\(days) \(days == 1 ? "day" : "days") to go."
            : "The trip's already on."
        RewardPresenter.present(Reward(
            kind: .packed,
            title: "All packed for \(where_).",
            message: "Every one of the \(itemCount) items is in the bag. \(tail)"))
    }

    /// R2 — a trip was marked complete.
    static func tripComplete(trip: Trip, visits: [VisitedPlace]) {
        let len = (Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0) + 1
        var cities = Set(visits
            .filter { $0.sourceTripID == trip.tripID && !$0.cityName.isEmpty }
            .map(\.cityName))
        if cities.isEmpty && !trip.destinationCity.isEmpty { cities = [trip.destinationCity] }
        let daysText = "\(len) \(len == 1 ? "day" : "days")"
        let tail = cities.isEmpty
            ? daysText + "."
            : "\(daysText), \(cities.count) \(cities.count == 1 ? "city" : "cities")."
        RewardPresenter.present(Reward(
            kind: .tripComplete,
            title: "Trip complete.",
            message: "\(trip.name) is stamped in your passport. \(tail)"))
    }

    /// R3 / R4 — a country that wasn't in the passport before was just added.
    /// Pass the full visit list *after* the insert + save.
    static func countryAdded(code: String, visitsAfter visits: [VisitedPlace]) {
        let codes = Set(visits.map { $0.countryCode.uppercased() }.filter { !$0.isEmpty })
        let count = codes.count
        guard count > 0 else { return }
        let pct = Int((Double(count) / 195 * 100).rounded())

        if milestones.contains(count) {
            RewardPresenter.present(Reward(
                kind: .milestone,
                title: "\(count) countries.",
                message: "\(pct)% of the world. Keep the passport moving."))
            return
        }

        var message = "\(pct)% of the world explored."
        if let continent = Countries.continent(for: code) {
            let inContinent = codes.filter { Countries.continent(for: $0) == continent }.count
            message = "\(pct)% of the world explored, and \(continent.displayName) is now \(inContinent) of \(continent.totalCountries)."
        }
        RewardPresenter.present(Reward(
            kind: .country,
            title: "That's your \(ordinal(count)) country.",
            message: message))
    }

    private static func ordinal(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        return f.string(from: NSNumber(value: n)) ?? "\(n)th"
    }
}
