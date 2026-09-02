import SwiftUI

/// Batch 2: `RootView` shows the internal component gallery while the shared
/// library is under review. Reverts to the real app shell in batch 4.
struct RootView: View {
    var body: some View {
        ComponentGallery()
    }
}

#Preview {
    RootView()
}
