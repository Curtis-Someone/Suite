import SwiftUI

/// Internal batch-2 preview: every shared component at every state, on the
/// app ground. Not a product screen — `RootView` points here only while the
/// component library is under review.
///
/// Launch arg `-galleryBottom YES` opens scrolled to the end (used to
/// screenshot the lower half for review).
struct ComponentGallery: View {
    @State private var tab: SuiteTab = .suitcase
    @State private var segment = "passport"
    @State private var chips: Set<String> = ["All time"]
    @State private var switchA = true
    @State private var switchB = false

    private var startAtBottom: Bool {
        ProcessInfo.processInfo.arguments.contains("-galleryBottom")
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        header.id("top")

                        group("Primary pill CTA") {
                            SuiteButton(title: "Track countries") {}
                            SuiteButton(title: "New suitcase", showsLeadingPlus: true) {}
                            SuiteButton(title: "Sign in", style: .secondary) {}
                            SuiteButton(title: "Send reset link", style: .formPrimary) {}
                            SuiteButton(title: "Continue", isEnabled: false) {}
                        }

                        group("Card") {
                            SuiteCard { Text("Sunken — surfaceSunken, no border").font(.Suite.body) }
                            SuiteCard(style: .surface) { Text("Surface — white, 1px border").font(.Suite.body) }
                        }

                        group("Progress bar") {
                            SuiteProgressBar(value: 0.05)
                            SuiteProgressBar(value: 0.14)
                            SuiteProgressBar(value: 0.62)
                            SuiteProgressBar(value: 0.4, height: 8)
                        }
                        .id("mid")

                        group("Circular gauge") {
                            HStack(spacing: 22) {
                                CircularGauge(value: 0)
                                CircularGauge(value: 0.5)
                                CircularGauge(value: 1)
                            }
                        }

                        group("Segmented toggle") {
                            SegmentedToggle(
                                options: [("trips", "Trips"), ("passport", "Passport")],
                                selection: $segment
                            )
                            .frame(width: 270)
                        }

                        group("Filter chips") {
                            HStack(spacing: 8) {
                                ForEach(["All time", "2026", "2025"], id: \.self) { title in
                                    FilterChip(title: title, isActive: chips.contains(title)) { chips = [title] }
                                }
                            }
                        }

                        group("Toggle switch — on / off") {
                            HStack(spacing: 24) {
                                SuiteSwitch(isOn: $switchA)
                                SuiteSwitch(isOn: $switchB)
                            }
                        }

                        group("Section header") {
                            SectionHeader(title: "Auth, continued")
                            KickerLabel("4 results")
                        }

                        group("Lucide icons (template-tinted)") {
                            let all: [SuiteIcon] = [
                                .chevronLeft, .chevronRight, .chevronDown, .chevronUp, .arrowLeft,
                                .plus, .circlePlus, .check, .checkDouble, .circleCheck, .close,
                                .search, .settings, .bell, .mapPin, .pin, .ellipsis, .calendar,
                                .pencil, .pencilLine, .share, .filter, .funnel, .list, .listPlus,
                                .user, .globe, .trash, .info, .bookOpen, .map, .contact, .luggage,
                                .sun, .wind, .snowflake, .cloud, .cloudRain, .cloudSnow, .cloudSunRain,
                            ]
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 16) {
                                ForEach(all, id: \.rawValue) { icon in
                                    SuiteIconView(icon: icon, size: 24, color: Theme.Palette.textHeading)
                                }
                            }
                        }

                        group("Stat block") {
                            StatBlock(
                                title: "In total",
                                leading: StatColumn(value: "10", unit: " / 195", caption: "countries"),
                                trailing: StatColumn(value: "5", unit: "%", caption: "of the world", alignment: .trailing),
                                progress: 0.05,
                                caption: "Based on 195 UN countries"
                            )
                            StatStrip(stats: [
                                StatColumn(value: "10", caption: "countries", valueSize: 26, alignment: .center),
                                StatColumn(value: "3", caption: "trips", valueSize: 26, alignment: .center),
                                StatColumn(value: "5%", caption: "of world", valueSize: 26, alignment: .center),
                            ])
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(Theme.Space.screenH)
                    .padding(.bottom, 40)
                }
                .onAppear {
                    if ProcessInfo.processInfo.arguments.contains("-galleryMid") {
                        proxy.scrollTo("mid", anchor: .top)
                    } else if startAtBottom {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            BottomNavBar(selection: $tab)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Wordmark(size: 40)
            KickerLabel("Component library · batch 2")
        }
    }

    @ViewBuilder
    private func group<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            KickerLabel(title)
            content()
        }
    }
}

#Preview {
    ComponentGallery()
}
