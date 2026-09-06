import SwiftUI

/// The three tabs, always in this order.
enum SuiteTab: CaseIterable {
    case map, suitcase, passport

    /// Tab name — also the accessibility label and the revealed active label.
    var title: String {
        switch self {
        case .map:      "Map"
        case .suitcase: "Suitcase"
        case .passport: "Passport"
        }
    }

    /// Asset name, imported template-mode so the tint is applied in code.
    /// `map` is the Lucide glyph; `suitcase` / `passport` are the custom
    /// line-art tab glyphs in `Assets.xcassets/Nav/`.
    var iconName: String {
        switch self {
        case .map:      "map"
        case .suitcase: "suitcase"
        case .passport: "passport"
        }
    }
}

/// Bottom navigation — a floating "glass pill" over the tab content.
///
/// `.ultraThinMaterial` picks up Liquid Glass on iOS 26 and degrades to a
/// plain blur on earlier releases. The active tab is shown *structurally* —
/// icon + label inside a neutral capsule highlight — so it doesn't rely on
/// colour perception (same rule as visited/not-visited on the Passport).
struct BottomNavBar: View {
    @Binding var selection: SuiteTab

    /// Tabs currently showing a "new update" dot (e.g. a fresh Passport stamp).
    /// Boolean for now; widen to a count for the reminder centre later.
    var badgedTabs: Set<SuiteTab> = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SuiteTab.allCases, id: \.self) { tab in
                TabItem(
                    tab: tab,
                    isActive: tab == selection,
                    badged: badgedTabs.contains(tab)
                ) {
                    guard tab != selection else { return }
                    if reduceMotion {
                        selection = tab
                    } else {
                        withAnimation(.snappy(duration: 0.28)) { selection = tab }
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .frame(height: Theme.Size.navPill)
        .background(.ultraThinMaterial, in: .capsule)
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
        .padding(.horizontal, Theme.Space.xl)
        .padding(.bottom, Theme.Space.m)
    }
}

/// One tab. Inactive: icon only. Active: icon + label side by side, on a
/// neutral capsule highlight, tinted with the text-safe amber.
private struct TabItem: View {
    let tab: SuiteTab
    let isActive: Bool
    let badged: Bool
    let action: () -> Void

    private var tint: Color {
        isActive ? Theme.Palette.navAmber : Theme.Palette.navInk.opacity(0.55)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                LucideIcon(name: tab.iconName, size: 22, color: tint)
                    .overlay(alignment: .topTrailing) {
                        if badged {
                            Circle()
                                .fill(Theme.Palette.brandAmber)
                                .frame(width: 7, height: 7)
                                .offset(x: 3, y: -3)
                        }
                    }

                if isActive {
                    Text(tab.title)
                        .font(.archivo(13, .semibold))
                        .foregroundStyle(Theme.Palette.navAmber)
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.horizontal, isActive ? 16 : 12)
            .frame(maxWidth: isActive ? .infinity : nil)
            .frame(minWidth: 44, minHeight: 44)
            .background {
                if isActive {
                    Capsule().fill(Theme.Palette.navHighlight)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(badged ? "There's a new update on this tab" : "")
    }
}
