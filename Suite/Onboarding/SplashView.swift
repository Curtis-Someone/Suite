import SwiftUI

/// 01 · Splash — centred suitcase mark, auto-advances.
struct SplashView: View {
    var onDone: () -> Void

    var body: some View {
        ZStack {
            Theme.Palette.surface.ignoresSafeArea()
            Image("SuiteLogomark")
                .resizable()
                .scaledToFit()
                .frame(width: 252, height: 252)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDone)
        .task {
            guard !ProcessInfo.processInfo.arguments.contains("-holdSplash") else { return }
            try? await Task.sleep(for: .seconds(1.4))
            onDone()
        }
    }
}
