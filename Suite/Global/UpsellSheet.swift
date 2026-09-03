import SwiftUI

/// The small contextual paywall nudge. Copy is specific to the `UpsellMoment`
/// the person just hit; "See plans" opens the full `PaywallView`.
struct UpsellSheet: View {
    let moment: UpsellMoment
    @Environment(\.dismiss) private var dismiss
    @State private var showPlans = false

    var body: some View {
        VStack(spacing: 0) {
            LucideIcon(name: iconName, size: 26, color: Theme.Palette.onAccent)
                .frame(width: 60, height: 60)
                .background(Theme.Palette.accent, in: Circle())
                .padding(.top, 40)

            Text(title)
                .font(.archivo(22, .bold)).tracking(22 * -0.02)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Palette.textHeading)
                .padding(.top, 18)

            Text(blurb)
                .font(.archivo(14)).lineSpacing(3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Theme.Palette.textSecondary)
                .padding(.top, 10)
                .padding(.horizontal, 12)

            Spacer(minLength: 24)

            Button { showPlans = true } label: {
                Text("See plans")
                    .font(.archivo(17, .bold))
                    .foregroundStyle(Theme.Palette.onAccent)
                    .frame(maxWidth: .infinity).frame(height: Theme.Size.cta)
                    .background(Theme.Palette.accent, in: Capsule())
            }
            .buttonStyle(.plain)

            Button("Not now") { dismiss() }
                .font(.archivo(14, .semibold))
                .foregroundStyle(Theme.Palette.textSecondary)
                .padding(.top, 16)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.ground.ignoresSafeArea())
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showPlans) {
            PaywallView()
                .overlay(alignment: .topLeading) {
                    Button { showPlans = false; dismiss() } label: {
                        SuiteIconView(icon: .close, size: 18, color: .white)
                            .frame(width: 42, height: 42)
                    }
                    .padding(.leading, 12).padding(.top, 8)
                }
        }
    }

    private var iconName: String {
        switch moment {
        case .secondSuitcase:  "luggage"
        case .thirdActiveTrip: "luggage"
        case .saveTemplate:    "book-open"
        case .addTraveler:     "users"
        case .smartSuggestions: "sparkles"
        case .exportTrip:      "share-2"
        }
    }

    private var title: String {
        switch moment {
        case .secondSuitcase:  "Pack in more bags"
        case .thirdActiveTrip: "Plan more trips at once"
        case .saveTemplate:    "Save it as a template"
        case .addTraveler:     "Travel together"
        case .smartSuggestions: "Smart packing"
        case .exportTrip:      "Take your list anywhere"
        }
    }

    private var blurb: String {
        switch moment {
        case .secondSuitcase:
            "Free covers one suitcase per trip. Pro removes every limit."
        case .thirdActiveTrip:
            "Free keeps two trips going at once. Pro makes it unlimited — plus your full archive."
        case .saveTemplate:
            "Turn a packed trip into a reusable list. Templates are a Pro feature."
        case .addTraveler:
            "Add people to a trip and it syncs across everyone's devices. Part of Pro."
        case .smartSuggestions:
            "Let Suite suggest what to pack from the trip type and the forecast. Pro only."
        case .exportTrip:
            "Send a packing list as a PDF or over Messages. Export is a Pro feature."
        }
    }
}
