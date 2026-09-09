import SwiftUI

/// P1 · Trips sub-view — the read-only travel log. Cards open the (read-only)
/// packing checklist for that trip.
struct TripsListView: View {
    var trips: [Trip]
    var onPlanTrip: () -> Void

    var body: some View {
        if trips.isEmpty {
            VStack(spacing: 0) {
                Image("PassportBook")
                    .resizable().scaledToFit()
                    .frame(width: 190, height: 190)
                    .blendMode(.multiply)
                    .opacity(0.75)
                    .padding(.top, 20)
                Text("No trips in your log yet")
                    .font(.Suite.titleS).tracking(22 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .padding(.top, 6)
                Text("Trips you finish land here as a travel journal —\ndates, destinations and what you packed.")
                    .font(.Suite.bodyS)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .padding(.top, 8)

                SuiteButton(title: "Plan a trip", showsLeadingPlus: true, action: onPlanTrip)
                    .padding(.top, 24)
                    .padding(.horizontal, 4)
            }
            .padding(.top, 24)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(trips) { trip in
                    NavigationLink(value: trip) { TripCardView(trip: trip) }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}
