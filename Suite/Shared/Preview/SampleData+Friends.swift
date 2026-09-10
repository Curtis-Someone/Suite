import Foundation
import SwiftData

extension SampleData {
    /// A spread of friends for the Friends tab / Map switcher (`-seedFriends`):
    /// two who share their passport, one who doesn't, and one incoming request.
    static func seedFriendsDemo(into context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Friend>())) ?? 0
        guard existing == 0 else { return }

        let maria = Friend(
            displayName: "Maria Alvés",
            shareCode: "MARIA24",
            status: .accepted,
            sharesPassport: true,
            countryCodes: ["PT", "ES", "FR", "IT", "MA", "BR", "MX", "JP", "TH", "GR", "HR", "IS"],
            cityCount: 21,
            sharedTrips: [
                SharedTripInfo(destination: "Lisbon, Portugal", countryCode: "PT", dateRange: "04–10 Nov 2024"),
                SharedTripInfo(destination: "Split, Croatia", countryCode: "HR", dateRange: "12–19 Jun 2023"),
            ])

        let theo = Friend(
            displayName: "Theo Bianchi",
            shareCode: "THEO0099",
            status: .accepted,
            sharesPassport: true,
            countryCodes: ["IT", "CH", "AT", "DE", "FR", "SI"],
            cityCount: 9,
            sharedTrips: [])

        let jun = Friend(
            displayName: "Jun Park",
            shareCode: "JUNPARK7",
            status: .accepted,
            sharesPassport: false)

        let request = Friend(
            displayName: "Amara Okafor",
            shareCode: "AMARA555",
            status: .incomingRequest)

        [maria, theo, jun, request].forEach(context.insert)
        try? context.save()
    }
}
