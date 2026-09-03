import Foundation
import SwiftData

/// "Reuse what worked" (Pro). A template is a frozen snapshot — its items are
/// `TemplateItem`s, not `Item` references, so editing a past trip can never
/// change a template already saved from it.
@Model
final class Template {
    var name: String = ""                 // "Beach weekend", "Business trip"
    var createdAt: Date = Date.now
    var sourceTripName: String = ""        // freeform label, kept even if the source Trip is deleted

    @Relationship(deleteRule: .cascade, inverse: \TemplateItem.template)
    var items: [TemplateItem] = []

    init(name: String, sourceTripName: String = "") {
        self.name = name
        self.sourceTripName = sourceTripName
        self.createdAt = .now
    }
}
