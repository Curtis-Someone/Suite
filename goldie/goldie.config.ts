import type { GoldieConfig } from "/Users/Ivan/.claude/plugins/cache/goldie/goldie/0.3.1/src/config.ts";

// NOTE ON CAPTURE: goldie's pinned argent (0.22) can't pass launch arguments
// to the app, and Suite's entire demo state (onboarding, seeded trips/visits,
// Pro, which tab/screen) is driven by `ProcessInfo.processInfo.arguments`. So
// the raw screenshots and preview clips are captured by `goldie/capture-suite.sh`
// (plain `xcrun simctl launch <args>` + `simctl io`), which writes
// out/raw/iphone-6.9/{*.png,*.mp4,manifest.json}. goldie then does the framing,
// captions, studio and preview encode from that. The `flow:` / segment names
// below are just ids the manifest keys on; there are no argent flow files.

const APP_ROOT = "/Users/Ivan/Documents/Suite/App/.claude/worktrees/goldie-appstore";

// Release build for the iOS Simulator (Debug paints LogBox/dev overlays that
// ruin marketing shots). Rebuild with:
//   xcodebuild -project Suite.xcodeproj -scheme Suite -configuration Release \
//     -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
//     -derivedDataPath build/goldie-release build
const APP_PATH =
  "/Users/Ivan/Documents/Suite/App/build/goldie-release/Build/Products/Release-iphonesimulator/Suite.app";

const config: GoldieConfig = {
  appRoot: APP_ROOT,
  appPath: APP_PATH,
  bundleId: "com.suiteapp.Suite",

  devices: ["iphone-6.9"], // App Store 6.9" iPhone (iPhone 17 Pro Max sim)
  locales: ["en-US"],
  appearance: "light", // Suite follows system appearance; light is the design default

  // Silver reads as neutral chrome next to Suite's warm off-white and amber;
  // the orange bezel would compete with the accent.
  frame: { variant: "17-pro-silver" },

  theme: {
    // Suite's ground (#F5F3EF) warmed into a soft top-down gradient.
    background: "linear-gradient(168deg, #F1EBDF 0%, #F6F3EE 52%, #FFFFFF 100%)",
    headlineColor: "#14161A", // Theme.Palette.textHeading
    subheadColor: "#77736C", // Theme.Palette.textSecondary
    // Archivo isn't in goldie's bundled set; DM Sans is the closest grotesque.
    fontFamily: '"DM Sans", -apple-system, "SF Pro Display", system-ui, sans-serif',
    copyHeightRatio: 0.24,
    deviceWidthRatio: 0.84,
    // A hero opener for the map, then full-device classic tiles so the app's
    // content (trip lists, checklist rows, prices, the CTA) stays uncropped.
    template: ["hero", "classic", "classic", "classic", "classic"],
    layout: "classic",
  },

  store: {
    name: "Suite",
    subtitle: { "en-US": "Pack, map & log your trips" },
    developer: "Ivan Serrano Garcia",
    category: "Travel",
    rating: 4.8,
    ratingCount: "128 Ratings",
    ageRating: "4+",
    price: "Free",
    description: {
      "en-US":
        "Suite is a calm home for every trip you take — the planning, the packing, and the memory of it afterwards.\n\n" +
        "Plan a trip and Suite lays out a packing list from the trip type and the forecast; you just tick things off. " +
        "Finished trips land on a dark, hand-styled world map and in a stamp-book passport of everywhere you've been.\n\n" +
        "Everything is stored on your device. Suite Pro adds unlimited trips, reusable templates, iCloud sync, PDF export and the full places-been stats.",
    },
  },

  scenes: [
    {
      kind: "screenshot",
      id: "map",
      flow: "store-01-map",
      headline: { "en-US": "See everywhere you've been" },
      subhead: { "en-US": "Countries fill in as you travel. Tap any one for its cities and regions." },
    },
    {
      kind: "screenshot",
      id: "suitcase",
      flow: "store-02-suitcase",
      headline: { "en-US": "Every trip in one place" },
      subhead: { "en-US": "Plan it, pack it, and watch the progress on each bag." },
    },
    {
      kind: "screenshot",
      id: "checklist",
      flow: "store-03-checklist",
      headline: { "en-US": "The packing list starts itself" },
      subhead: { "en-US": "Built from the trip and the forecast — you just tick things off." },
    },
    {
      kind: "screenshot",
      id: "passport",
      flow: "store-04-passport",
      headline: { "en-US": "Your travel history, stamped" },
      subhead: { "en-US": "Countries, cities, continents and every past trip." },
    },
    {
      kind: "screenshot",
      id: "paywall",
      flow: "store-05-paywall",
      headline: { "en-US": "Go further with Suite Pro" },
      subhead: { "en-US": "Unlimited trips, templates, iCloud sync and full passport stats." },
    },

    {
      kind: "preview",
      id: "preview",
      // One continuous screen recording of a tab tour (Suitcase -> Map ->
      // Passport -> Suitcase), captured by goldie/capture-preview.sh.
      segments: [{ id: "tour", flow: "store-preview-tour" }],
    },
  ],
};

export default config;
