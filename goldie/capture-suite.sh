#!/bin/bash
# Capture the raw App Store screenshots for Suite.
#
# goldie's pinned argent (0.22) can't pass launch arguments, and Suite's demo
# state is entirely `ProcessInfo.processInfo.arguments`-driven, so we drive the
# capture with plain `xcrun simctl` here and let `goldie frame` / `goldie studio`
# take it from raw/. Re-run any time; it's idempotent.
#
# Usage:  bash goldie/capture-suite.sh
# Needs:  the Release sim build at build/goldie-release/... (see goldie.config.ts)

set -euo pipefail

BUNDLE="com.suiteapp.Suite"
SIM_NAME="iPhone 17 Pro Max"
APP="/Users/Ivan/Documents/Suite/App/build/goldie-release/Build/Products/Release-iphonesimulator/Suite.app"
OUT="$(cd "$(dirname "$0")" && pwd)/out/raw/iphone-6.9"

UDID="$(xcrun simctl list devices available | grep "$SIM_NAME (" | head -1 | grep -oE '[0-9A-F-]{36}')"
[ -n "$UDID" ] || { echo "no '$SIM_NAME' simulator found"; exit 1; }
echo "device  $UDID"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP"
mkdir -p "$OUT"

# 9:41, full bars, no clutter — the same pinning goldie would apply.
pin_status_bar() {
  xcrun simctl status_bar "$UDID" override \
    --time "9:41" --batteryState unplugged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    >/dev/null 2>&1 || true
}

shoot() {
  local id="$1"; shift
  echo "  capture $id"
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" "$@" >/dev/null
  sleep 12                 # cold start + autopilot onboarding + SwiftData seed
  pin_status_bar
  sleep 2
  xcrun simctl io "$UDID" screenshot "$OUT/$id.png" >/dev/null
}

shoot map       -autopilot -proUnlocked -seedVisits -seedWishlist -tab map
shoot suitcase  -autopilot -proUnlocked -seedTrips -tab suitcase
shoot checklist -autopilot -proUnlocked -seedTrips -tab suitcase -openChecklist upcoming
shoot passport  -autopilot -proUnlocked -seedVisits -tab passport
shoot paywall   -screen paywall

cat > "$OUT/manifest.json" <<JSON
{
  "device": "iphone-6.9",
  "udid": "$UDID",
  "capturedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "screenshots": [
    { "sceneId": "map",       "file": "$OUT/map.png" },
    { "sceneId": "suitcase",  "file": "$OUT/suitcase.png" },
    { "sceneId": "checklist", "file": "$OUT/checklist.png" },
    { "sceneId": "passport",  "file": "$OUT/passport.png" },
    { "sceneId": "paywall",   "file": "$OUT/paywall.png" }
  ],
  "preview": null
}
JSON

xcrun simctl status_bar "$UDID" clear >/dev/null 2>&1 || true
echo "wrote $OUT/{map,suitcase,checklist,passport,paywall}.png + manifest.json"
