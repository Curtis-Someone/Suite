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

/// The specular edge shared by every glass surface in the dock.
private let glassEdge = LinearGradient(
    colors: [.white.opacity(0.55), .white.opacity(0.08)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

/// Bottom navigation — a two-piece floating "liquid glass" dock: a translucent
/// tab pill on the left and a round quick-add button on its right, both
/// `.ultraThinMaterial` with a specular edge and a lifting shadow.
///
/// Every tab shows its glyph above a label; the current tab is tinted
/// `navAmber` on a faint neutral highlight (a structural cue, not colour
/// alone). Tapping "+" springs open a small menu — New trip / New place /
/// New friend — and the glyph rotates to a close "×". Tapping a tab or the
/// scrim closes it.
struct BottomNavBar: View {
    @Binding var selection: SuiteTab

    /// Tabs currently showing a "new update" dot (e.g. a fresh Passport stamp).
    var badgedTabs: Set<SuiteTab> = []

    /// Quick-add menu actions. Default no-ops keep previews / the gallery cheap.
    var onNewTrip: () -> Void = {}
    var onNewPlace: () -> Void = {}
    var onNewFriend: () -> Void = {}

    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if expanded {
                Rectangle()
                    .fill(Color.black.opacity(0.14))
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { setExpanded(false) }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Close quick add")
            }

            VStack(alignment: .trailing, spacing: 12) {
                if expanded {
                    QuickAddMenu(
                        onNewTrip:   { setExpanded(false); onNewTrip() },
                        onNewPlace:  { setExpanded(false); onNewPlace() },
                        onNewFriend: { setExpanded(false); onNewFriend() }
                    )
                    .transition(
                        .scale(scale: 0.9, anchor: .bottomTrailing).combined(with: .opacity)
                    )
                }

                HStack(spacing: 10) {
                    TabStrip(selection: $selection, badgedTabs: badgedTabs) {
                        if expanded { setExpanded(false) }
                    }
                    QuickAddButton(expanded: expanded) { setExpanded(!expanded) }
                }
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.bottom, Theme.Space.m)
        }
        .sensoryFeedback(.selection, trigger: selection)
        .sensoryFeedback(.impact(weight: .light), trigger: expanded)
    }

    private func setExpanded(_ value: Bool) {
        guard value != expanded else { return }
        if reduceMotion {
            expanded = value
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) { expanded = value }
        }
    }
}

/// The tab pill — glyphs above labels, evenly spaced, on a glass capsule.
private struct TabStrip: View {
    @Binding var selection: SuiteTab
    var badgedTabs: Set<SuiteTab> = []
    /// Called before a tab switch — lets the dock close an open menu.
    var willSwitch: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SuiteTab.allCases, id: \.self) { tab in
                TabItem(
                    tab: tab,
                    isActive: tab == selection,
                    badged: badgedTabs.contains(tab)
                ) {
                    willSwitch()
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
        .frame(maxWidth: .infinity)
        .frame(height: Theme.Size.navPill)
        .background(.ultraThinMaterial, in: .capsule)
        .overlay(Capsule().strokeBorder(glassEdge, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}

/// Round "+" that rotates to a close "×" while the quick-add menu is open.
private struct QuickAddButton: View {
    let expanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SuiteIconView(icon: .plus, size: 24, color: Theme.Palette.navInk)
                .rotationEffect(.degrees(expanded ? 45 : 0))
                .frame(width: Theme.Size.navPill, height: Theme.Size.navPill)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(glassEdge, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
        }
        .buttonStyle(TabPressStyle())
        .accessibilityLabel(expanded ? "Close quick add" : "Quick add")
        .accessibilityAddTraits(.isButton)
    }
}

/// The floating quick-add list, anchored above the "+" button.
private struct QuickAddMenu: View {
    let onNewTrip: () -> Void
    let onNewPlace: () -> Void
    let onNewFriend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row("suitcase", "New trip", action: onNewTrip)
            divider
            row("map-pin", "New place", action: onNewPlace)
            divider
            row("contact", "New friend", action: onNewFriend)
        }
        .padding(6)
        .frame(width: 230)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(glassEdge, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 22, x: 0, y: 10)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.Palette.navInk.opacity(0.10))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }

    private func row(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                LucideIcon(name: icon, size: 20, color: Theme.Palette.navInk)
                Text(title)
                    .font(.archivo(15, .semibold))
                    .foregroundStyle(Theme.Palette.navInk)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabPressStyle())
    }
}

/// Touch feedback for the dock — a springy scale + dim on press so a control
/// reacts under the finger. Plain dim only when Reduce Motion is on.
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
