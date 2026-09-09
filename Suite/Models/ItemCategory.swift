import Foundation

/// Storage taxonomy for packing items — deliberately coarse. The checklist
/// groups items under these six headers.
///
/// The New-Suitcase builder's activity chips (Beach, Hiking, Golf…) are a
/// separate seeding concept (`PackingPreset`): picking a chip adds preset
/// items, each tagged with one of these categories.
enum ItemCategory: String, Codable, CaseIterable {
    case clothing, toiletries, electronics, accessories, documents, misc

    var displayName: String {
        switch self {
        case .clothing:    "Clothing"
        case .toiletries:  "Toiletries"
        case .electronics: "Electronics"
        case .accessories: "Accessories"
        case .documents:   "Documents"
        case .misc:        "Other"
        }
    }

    /// Lucide asset name for the section header.
    var iconName: String {
        switch self {
        case .clothing:    "shirt"
        case .toiletries:  "bath"
        case .electronics: "plug"
        case .accessories: "glasses"
        case .documents:   "book-open"
        case .misc:        "list"
        }
    }

    /// Order the sections appear in the checklist.
    var sortRank: Int {
        switch self {
        case .documents: 0
        case .clothing: 1
        case .toiletries: 2
        case .electronics: 3
        case .accessories: 4
        case .misc: 5
        }
    }
}
