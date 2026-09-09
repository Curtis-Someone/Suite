import SwiftUI

/// The three tabs, always in this order.
enum SuiteTab: CaseIterable {
    case map, suitcase, passport

    /// Tab name — also the accessibility label and the visible tab label.
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

/// Bottom navigation — a floating "liquid glass" pill: a translucent
/// `.ultraThinMaterial` capsule inset from the screen edges, with a soft
/// specular border and a lifting shadow.
///
/// Every tab shows its glyph above a label. The current tab is tinted
/// `navAmber` and sits on a faint neutral highlight — a structural cue, not
/// colour alone (same rule as visited/not-visited on the Passport). Tapping
/// a tab is *reactive* — the pressed tab springs down under the finger
/// (`TabPressStyle`) and the switch fires a selection haptic.
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
        .padding(.horizontal, 8)
        .frame(height: Theme.Size.navPill)
        .background(.ultraThinMaterial, in: .capsule)
        .overlay(
            Capsule().strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.55), .white.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
        .padding(.horizontal, Theme.Space.xl)
        .padding(.bottom, Theme.Space.m)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// Touch feedback for the nav tabs — a springy scale + dim on press so the
/// tab reacts under the finger. Plain dim only when Reduce Motion is on.
private struct TabPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.86 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(reduceMotion ? .easeOut(duration: 0.12)
                                    : .spring(response: 0.3, dampingFraction: 0.55),
                       value: configuration.isPressed)
    }
}

/// One tab — glyph above label, always visible. Active: tinted `navAmber` on
/// a faint neutral highlight. Inactive: `navInk` at half strength.
private struct TabItem: View {
    let tab: SuiteTab
    let isActive: Bool
    let badged: Bool
    let action: () -> Void

    private var tint: Color {
        isActive ? Theme.Palette.navAmber : Theme.Palette.navInk.opacity(0.5)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                LucideIcon(name: tab.iconName, size: 22, color: tint)
                    .overlay(alignment: .topTrailing) {
                        if badged {
                            Circle()
                                .fill(Theme.Palette.brandAmber)
                                .frame(width: 7, height: 7)
                                .offset(x: 4, y: -2)
                        }
                    }

                Text(tab.title)
                    .font(.archivo(11, .semibold))
                    .foregroundStyle(tint)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.vertical, 6)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.Palette.navHighlight)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(TabPressStyle())
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(badged ? "There's a new update on this tab" : "")
    }
}
