import Foundation
import SwiftData

@Model
final class Item {
    var name: String = ""
    var category: ItemCategory = ItemCategory.misc
    var quantity: Int = 1
    var isPacked: Bool = false
    var notes: String = ""
    var sortOrder: Int = 0
    var suitcase: Suitcase?

    init(name: String, category: ItemCategory, quantity: Int = 1, suitcase: Suitcase? = nil) {
        self.name = name
        self.category = category
        self.quantity = quantity
        self.isPacked = false
        self.sortOrder = 0
        self.suitcase = suitcase
    }
}
