import SwiftUI

/// Screens with a custom chevron header hide the whole system navigation bar
/// (`.toolbar(.hidden, for: .navigationBar)`), which can switch off the
/// edge-swipe-back gesture iOS users rely on (HIG · Accessibility — Mobility:
/// don't remove an expected gesture). Attach `.keepsSwipeBack()` to such a
/// pushed screen to force the interactive pop gesture back on.
extension View {
    func keepsSwipeBack() -> some View { background(SwipeBackEnabler().frame(width: 0, height: 0)) }
}

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { Proxy() }
    func updateUIViewController(_ vc: UIViewController, context: Context) {}

    /// Sits in the view hierarchy only to reach the enclosing
    /// `UINavigationController` and re-enable its pop gesture.
    final class Proxy: UIViewController, UIGestureRecognizerDelegate {
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
            gesture.isEnabled = true
            gesture.delegate = self
        }

        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }

        // Let the swipe start alongside the screen's own scroll views.
        func gestureRecognizer(_ recognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
