import Foundation
import SwiftData

/// Dev/preview fixtures. Reused by screen previews from batch 4 on.
enum SampleData {

    /// One realistic trip with a partly-packed suitcase, plus a seeded home place.
    @discardableResult
    static func seed(into context: ModelContext) -> Trip {
        let trip = Trip(
            name: "Lisbon spring break",
            destinationCity: "Lisbon",
            destinationCountry: "Portugal",
            destinationCountryCode: "PT",
            startDate: Date(timeIntervalSinceNow: 7 * 86_400),
            endDate: Date(timeIntervalSinceNow: 12 * 86_400)
        )
        let suitcase = Suitcase(name: "Carry-on")
        let items = [
            Item(name: "Passport", category: .documents),
            Item(name: "Charger", category: .electronics),
            Item(name: "Linen shirt", category: .clothing, quantity: 3),
            Item(name: "Sunscreen", category: .toiletries),
        ]
        items[0].isPacked = true
        for (i, item) in items.enumerated() { item.sortOrder = i }
        suitcase.items = items
        trip.suitcases = [suitcase]

        context.insert(trip)
        context.insert(VisitedPlace(countryName: "France", countryCode: "FR", isHomeCountry: true))
        return trip
    }

    /// Batch-5 demo: an upcoming trip mid-pack, another barely started, and a
    /// completed one — mirrors the S1 artboard. Dev only (`-seedTrips`).
    static func seedSuitcaseDemo(into context: ModelContext) {
        func trip(_ name: String, _ city: String, _ country: String, _ code: String,
                  startsInDays: Int, lengthDays: Int, archived: Bool = false) -> Trip {
            let start = Calendar.current.date(byAdding: .day, value: startsInDays, to: .now)!
            let t = Trip(name: name, destinationCity: city, destinationCountry: country,
                         destinationCountryCode: code,
                         startDate: Calendar.current.startOfDay(for: start),
                         endDate: Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: lengthDays, to: start)!))
            t.isArchived = archived
            return t
        }
        func fill(_ t: Trip, type: String, chips: Set<String>, packedFraction: Double) {
            t.tripType = type
            t.iconName = PackingPreset.icon(forTripType: type) ?? PackingPreset.tripIcon(for: chips)
            let s = Suitcase(name: "Packing list", trip: t)
            s.items = PackingPreset.items(for: chips).enumerated().map { i, p in
                let item = Item(name: p.name, category: p.category, quantity: p.quantity)
                item.sortOrder = i
                return item
            }
            let packUpto = Int(Double(s.items.count) * packedFraction)
            for item in s.items.prefix(packUpto) { item.isPacked = true }
            t.suitcases = [s]
        }

        let lisbon = trip("Lisbon & Sintra", "Lisbon", "Portugal", "PT", startsInDays: 12, lengthDays: 8)
        fill(lisbon, type: "beach", chips: ["essentials", "clothes", "toiletries", "beach"], packedFraction: 0.6)

        let dolomites = trip("Dolomites hike", "Cortina", "Italy", "IT", startsInDays: 48, lengthDays: 7)
        fill(dolomites, type: "mountains", chips: ["essentials", "clothes", "hiking", "photography"], packedFraction: 0.12)

        let kyoto = trip("Kyoto in autumn", "Kyoto", "Japan", "JP", startsInDays: -300, lengthDays: 6, archived: true)
        fill(kyoto, type: "city", chips: ["essentials", "clothes", "toiletries", "international"], packedFraction: 1)

        [lisbon, dolomites, kyoto].forEach(context.insert)
        try? context.save()
    }

    /// A spread of visited places for the Passport tab (`-seedVisits`).
    static func seedVisitsDemo(into context: ModelContext) {
        let places: [(String, String, String)] = [
            ("FR", "France", "Paris"), ("DE", "Germany", "Berlin"), ("ES", "Spain", "Barcelona"),
            ("PT", "Portugal", "Lisbon"), ("IT", "Italy", "Rome"), ("NL", "Netherlands", "Amsterdam"),
            ("GB", "United Kingdom", "London"), ("JP", "Japan", "Kyoto"), ("TH", "Thailand", "Bangkok"),
            ("US", "United States", "New York"),
        ]
        for (code, name, city) in places {
            context.insert(VisitedPlace(countryName: name, countryCode: code, cityName: city))
        }
        context.insert(VisitedPlace(countryName: "France", countryCode: "FR", isHomeCountry: true))
        try? context.save()
    }

    /// A single upcoming trip — to preview the sparse Suitcase list (`-seedOne`).
    static func seedOneTrip(into context: ModelContext) {
        let start = Calendar.current.date(byAdding: .day, value: 9, to: .now)!
        let t = Trip(name: "Lisbon & Sintra", destinationCity: "Lisbon", destinationCountry: "Portugal",
                     destinationCountryCode: "PT",
                     startDate: Calendar.current.startOfDay(for: start),
                     endDate: Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 6, to: start)!))
        t.tripType = "beach"
        t.iconName = "tree-palm"
        let s = Suitcase(name: "Packing list", trip: t)
        s.items = PackingPreset.items(for: ["essentials", "clothes", "toiletries", "beach"]).enumerated().map { i, p in
            let item = Item(name: p.name, category: p.category, quantity: p.quantity); item.sortOrder = i; return item
        }
        for item in s.items.prefix(4) { item.isPacked = true }
        t.suitcases = [s]
        context.insert(t)
        try? context.save()
    }

    /// Fresh in-memory store for previews and the batch-3 round-trip check.
    static func inMemoryContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(
            for: Trip.self, Suitcase.self, Item.self,
            Template.self, TemplateItem.self,
            Traveler.self, WeatherDay.self,
            VisitedPlace.self, UserSettings.self,
            configurations: config
        )
    }
}
