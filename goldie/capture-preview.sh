#!/bin/bash
# Capture the App Store preview for Suite: one continuous screen recording of a
# tab tour (Suitcase -> Map -> Passport -> Suitcase). `goldie preview` scales
# and encodes it to the 886x1920 / 15-30s upload spec.
#
# Taps go through the argent CLI; the seeded launch is plain `simctl`.
# Usage:  bash goldie/capture-preview.sh

set -euo pipefail

BUNDLE="com.suiteapp.Suite"
SIM_NAME="iPhone 17 Pro Max"
ARGENT="/Users/Ivan/.npm/_npx/18a971dee120d222/node_modules/@swmansion/argent/dist/cli.js"
OUT="$(cd "$(dirname "$0")" && pwd)/out/raw/iphone-6.9"
FFPROBE="$HOME/bin/ffprobe"
CLIP="$OUT/preview-tour.mp4"

UDID="$(xcrun simctl list devices available | grep "$SIM_NAME (" | head -1 | grep -oE '[0-9A-F-]{36}')"
[ -n "$UDID" ] || { echo "no '$SIM_NAME' simulator found"; exit 1; }
echo "device  $UDID"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
xcrun simctl status_bar "$UDID" override \
  --time "9:41" --batteryState unplugged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --dataNetwork wifi --wifiMode active --wifiBars 3 >/dev/null 2>&1 || true

echo "seeding session"
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" \
  -autopilot -proUnlocked -seedTrips -seedVisits -seedWishlist -tab suitcase >/dev/null
sleep 12

tap() { node "$ARGENT" run gesture-tap --udid "$UDID" --x "$1" --y "$2" >/dev/null; }

echo "recording tour"
mkdir -p "$OUT"
xcrun simctl io "$UDID" recordVideo --codec h264 --force "$CLIP" &
REC=$!
sleep 4                                   # let the recorder warm up + hold on Suitcase
sleep 4 ; tap 0.213 0.915                  # -> Map
sleep 6 ; tap 0.788 0.915                  # -> Passport
sleep 6 ; tap 0.500 0.915                  # -> Suitcase
sleep 6
kill -INT "$REC" 2>/dev/null || true
wait "$REC" 2>/dev/null || true

xcrun simctl status_bar "$UDID" clear >/dev/null 2>&1 || true

DUR="$("$FFPROBE" -v error -show_entries format=duration -of csv=p=0 "$CLIP")"
python3 - "$OUT" "$DUR" <<'PY'
import json, sys, os
out, dur = sys.argv[1], float(sys.argv[2])
mani = os.path.join(out, "manifest.json")
m = json.load(open(mani))
m["preview"] = {
    "sceneId": "preview",
    "clips": [{"segmentId": "tour", "file": f"{out}/preview-tour.mp4", "durationSeconds": dur}],
}
json.dump(m, open(mani, "w"), indent=2)
print(f"preview clip: {dur:.1f}s")
PY

echo "wrote $CLIP + patched manifest.json"
