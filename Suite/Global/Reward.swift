import SwiftUI

/// One reward-overlay payload. The copy is pre-rendered with real values by
/// `RewardEngine`; the view only lays it out.
struct Reward: Equatable {
    enum Kind { case packed, tripComplete, country, milestone }
    var kind: Kind
    var title: String
    var message: String

    var iconName: String {
        switch kind {
        case .packed:       "luggage"
        case .tripComplete: "circle-check"
        case .country:      "map-pin"
        case .milestone:    "globe"
        }
    }
}

/// Shows a `Reward` in its own window so it floats above tabs *and* sheets —
/// the triggers fire from inside sheets (add-a-visit, country detail).
@MainActor
enum RewardPresenter {
    private static var window: UIWindow?

    static func present(_ reward: Reward) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard window == nil,
              let scene = scenes.first(where: { $0.activationState == .foregroundActive })
                        ?? scenes.first(where: { $0.keyWindow != nil })
                        ?? scenes.first
        else { return }

        let host = UIHostingController(
            rootView: RewardOverlayView(reward: reward, onDismiss: dismiss))
        host.view.backgroundColor = .clear

        let w = UIWindow(windowScene: scene)
        w.rootViewController = host
        w.windowLevel = .alert + 1
        w.isHidden = false
        window = w
    }

    static func dismiss() {
        window?.isHidden = true
        window = nil
    }
}
