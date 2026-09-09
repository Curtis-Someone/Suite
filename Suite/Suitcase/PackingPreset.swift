import SwiftUI

/// Seed data for the New-Suitcase builder. Picking a chip adds these items to
/// the suitcase (deduped by name); the checklist then groups everything by
/// `ItemCategory`. Lists are intentionally short starting points — users edit.
struct PresetItem: Hashable {
    let name: String
    let category: ItemCategory
    var quantity: Int = 1
}

struct PresetChip: Identifiable {
    let id: String
    let title: String
    let iconName: String   // Lucide asset
    let tileColor: Color
    var items: [PresetItem] = []
}

enum PackingPreset {

    static let accommodation: [PresetChip] = [
        .init(id: "hotel", title: "Hotel", iconName: "bed-single", tileColor: c(0x3B6FB0)),
        .init(id: "rental", title: "Rental", iconName: "house", tileColor: c(0x3B9C6D), items: [
            i("Dish soap", .misc), i("Trash bags", .misc),
        ]),
        .init(id: "friends", title: "Friends/Family", iconName: "users", tileColor: c(0xC0567A), items: [
            i("Host gift", .misc), i("Own towel", .misc),
        ]),
        .init(id: "second_home", title: "Second Home", iconName: "house", tileColor: c(0x7B5CC0)),
        .init(id: "camping", title: "Camping", iconName: "tent", tileColor: c(0x4E9C3B), items: [
            i("Tent", .misc), i("Sleeping bag", .misc), i("Roll mat", .misc),
            i("Camp stove", .misc), i("Head torch", .electronics),
        ]),
        .init(id: "cruise", title: "Cruise", iconName: "ship", tileColor: c(0x2F8FA6), items: [
            i("Formal outfit", .clothing), i("Seasickness tablets", .toiletries),
        ]),
    ]

    static let transportation: [PresetChip] = [
        .init(id: "car", title: "Car", iconName: "car", tileColor: c(0xB0553B), items: [
            i("Phone mount", .electronics), i("Sunshade", .misc), i("Road snacks", .misc),
        ]),
        .init(id: "plane", title: "Plane", iconName: "plane", tileColor: c(0x3B6FB0), items: [
            i("Neck pillow", .accessories), i("Eye mask", .accessories),
            i("Earplugs", .accessories), i("Empty water bottle", .misc),
        ]),
        .init(id: "train", title: "Train", iconName: "train-front", tileColor: c(0x9C5B3B), items: [
            i("Book", .misc), i("Snacks", .misc),
        ]),
        .init(id: "bus", title: "Bus", iconName: "bus", tileColor: c(0xC0A03B), items: [
            i("Neck pillow", .accessories), i("Snacks", .misc),
        ]),
    ]

    static let activities: [PresetChip] = [
        .init(id: "essentials", title: "Essentials", iconName: "circle-check-big", tileColor: c(0xB0553B), items: [
            i("Phone charger", .electronics), i("Wallet", .documents), i("Keys", .misc),
            i("Medication", .toiletries), i("Reusable water bottle", .misc),
        ]),
        .init(id: "clothes", title: "Clothes", iconName: "shirt", tileColor: c(0x7B5CC0), items: [
            i("Underwear", .clothing, 5), i("Socks", .clothing, 5), i("T-shirts", .clothing, 4),
            i("Trousers", .clothing, 2), i("Sleepwear", .clothing), i("Light jacket", .clothing),
        ]),
        .init(id: "toiletries", title: "Toiletries", iconName: "bath", tileColor: c(0x3B9C6D), items: [
            i("Toothbrush", .toiletries), i("Toothpaste", .toiletries), i("Deodorant", .toiletries),
            i("Shampoo", .toiletries), i("Razor", .toiletries),
        ]),
        .init(id: "international", title: "International", iconName: "globe-lock", tileColor: c(0x3B6FB0), items: [
            i("Passport", .documents), i("Travel adapter", .electronics),
            i("Local currency", .documents), i("Document copies", .documents),
        ]),
        .init(id: "working", title: "Working", iconName: "briefcase-business", tileColor: c(0x575E63), items: [
            i("Laptop", .electronics), i("Laptop charger", .electronics), i("Notebook", .misc),
            i("Pen", .misc), i("Headphones", .electronics),
        ]),
        .init(id: "beach", title: "Beach", iconName: "umbrella", tileColor: c(0x2F8FA6), items: [
            i("Swimsuit", .clothing, 2), i("Sunscreen", .toiletries), i("Beach towel", .misc),
            i("Sunglasses", .accessories), i("Flip-flops", .clothing),
        ]),
        .init(id: "cycling", title: "Cycling", iconName: "bike", tileColor: c(0x4E9C3B), items: [
            i("Helmet", .accessories), i("Cycling shorts", .clothing, 2),
            i("Jersey", .clothing, 2), i("Gloves", .accessories),
        ]),
        .init(id: "formal", title: "Formal Dinner", iconName: "gem", tileColor: c(0xC0567A), items: [
            i("Dress shoes", .clothing), i("Suit or dress", .clothing),
            i("Dress shirt", .clothing), i("Belt", .accessories),
        ]),
        .init(id: "golf", title: "Golf", iconName: "flag", tileColor: c(0x3B9C6D), items: [
            i("Golf shoes", .clothing), i("Glove", .accessories),
            i("Balls", .misc), i("Polo shirt", .clothing, 2),
        ]),
        .init(id: "gym", title: "Gym", iconName: "dumbbell", tileColor: c(0x575E63), items: [
            i("Trainers", .clothing), i("Gym shorts", .clothing, 2),
            i("Workout top", .clothing, 3), i("Water bottle", .misc),
        ]),
        .init(id: "hiking", title: "Hiking", iconName: "mountain", tileColor: c(0x9C5B3B), items: [
            i("Hiking boots", .clothing), i("Daypack", .misc), i("Water bladder", .misc),
            i("Trail snacks", .misc), i("First-aid kit", .toiletries),
        ]),
        .init(id: "festival", title: "Music Festival", iconName: "music", tileColor: c(0x7B5CC0), items: [
            i("Earplugs", .accessories), i("Rain poncho", .clothing),
            i("Portable charger", .electronics), i("Bum bag", .accessories),
        ]),
        .init(id: "photography", title: "Photography", iconName: "camera", tileColor: c(0x575E63), items: [
            i("Camera", .electronics), i("Lenses", .electronics), i("Spare batteries", .electronics),
            i("SD cards", .electronics), i("Tripod", .electronics),
        ]),
        .init(id: "swimming", title: "Swimming", iconName: "droplets", tileColor: c(0x2F8FA6), items: [
            i("Goggles", .accessories), i("Swimsuit", .clothing, 2),
            i("Swim cap", .accessories),
        ]),
        .init(id: "winter", title: "Winter Sports", iconName: "snowflake", tileColor: c(0x3B6FB0), items: [
            i("Thermal base layer", .clothing, 2), i("Ski gloves", .accessories),
            i("Goggles", .accessories), i("Beanie", .clothing), i("Hand warmers", .misc),
        ]),
    ]

    /// Single-select on the builder's Basics step. Drives the trip-card icon.
    static let tripTypes: [PresetChip] = [
        .init(id: "city",        title: "City break",   iconName: "building-2",          tileColor: c(0x3B6FB0)),
        .init(id: "sightseeing", title: "Sightseeing",  iconName: "compass",             tileColor: c(0x2F8FA6)),
        .init(id: "beach",       title: "Beach",        iconName: "tree-palm",           tileColor: c(0xC0A03B)),
        .init(id: "mountains",   title: "Mountains",    iconName: "mountain",            tileColor: c(0x4E9C3B)),
        .init(id: "ski",         title: "Ski & snow",   iconName: "snowflake",           tileColor: c(0x3B6FB0)),
        .init(id: "roadtrip",    title: "Road trip",    iconName: "car",                 tileColor: c(0xB0553B)),
        .init(id: "business",    title: "Business",     iconName: "briefcase-business",  tileColor: c(0x575E63)),
        .init(id: "sport",       title: "Sport",        iconName: "dumbbell",            tileColor: c(0x9C5B3B)),
        .init(id: "backpacking", title: "Backpacking",  iconName: "backpack",            tileColor: c(0x7B5CC0)),
        .init(id: "festival",    title: "Festival",     iconName: "music",               tileColor: c(0xC0567A)),
        .init(id: "camping",     title: "Camping",      iconName: "tent",                tileColor: c(0x4E9C3B)),
        .init(id: "cruise",      title: "Cruise",       iconName: "ship",                tileColor: c(0x2F8FA6)),
    ]

    static func icon(forTripType id: String) -> String? {
        tripTypes.first { $0.id == id }?.iconName
    }

    static let other: [PresetChip] = [
        .init(id: "todo", title: "To-do List", iconName: "square-pen", tileColor: c(0x575E63)),
        .init(id: "baby", title: "Baby", iconName: "baby", tileColor: c(0xC0567A), items: [
            i("Nappies", .misc), i("Wipes", .misc), i("Baby clothes", .clothing, 6),
            i("Bottle", .misc), i("Formula", .misc), i("Blanket", .misc),
        ]),
    ]

    static var allChips: [PresetChip] { accommodation + transportation + activities + other }

    /// A single glyph for the trip card, chosen from the picked chips —
    /// most distinctive activity first, then trip shape, then transport.
    static func tripIcon(for selectedIDs: Set<String>) -> String {
        let priority: [(id: String, icon: String)] = [
            ("winter", "snowflake"), ("hiking", "mountain"), ("beach", "tree-palm"),
            ("swimming", "droplets"), ("cycling", "bike"), ("golf", "flag"),
            ("festival", "music"), ("photography", "camera"), ("gym", "dumbbell"),
            ("working", "briefcase-business"),
            ("camping", "tent"), ("cruise", "ship"),
            ("international", "landmark"),
            ("plane", "plane"), ("train", "train-front"), ("car", "car"), ("bus", "bus"),
        ]
        for entry in priority where selectedIDs.contains(entry.id) { return entry.icon }
        return "luggage"
    }

    /// Items for the selected chip ids, deduped by name (case-insensitive).
    static func items(for selectedIDs: Set<String>) -> [PresetItem] {
        var seen = Set<String>()
        return allChips
            .filter { selectedIDs.contains($0.id) }
            .flatMap(\.items)
            .filter { seen.insert($0.name.lowercased()).inserted }
    }

    // MARK: -

    private static func i(_ name: String, _ category: ItemCategory, _ qty: Int = 1) -> PresetItem {
        PresetItem(name: name, category: category, quantity: qty)
    }
    private static func c(_ hex: UInt32) -> Color { Color(hex: hex) }
}
