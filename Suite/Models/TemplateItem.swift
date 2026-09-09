import Foundation
import SwiftData

@Model
final class TemplateItem {
    var name: String = ""
    var category: ItemCategory = ItemCategory.misc
    var quantity: Int = 1
    var template: Template?

    init(name: String, category: ItemCategory, quantity: Int = 1, template: Template? = nil) {
        self.name = name
        self.category = category
        self.quantity = quantity
        self.template = template
    }
}
