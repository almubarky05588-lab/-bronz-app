#!/usr/bin/env bash
# يصوّر شاشات App Store تلقائيًا على آيفون افتراضي (6.9 إنش).
# التطبيق يُبنى بوضع SCREENSHOTS، والسكربت يقوده من شاشة لشاشة (lib/screens/shell.dart).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="$ROOT/ios/fastlane/screenshots"

echo "▶ بناء نسخة التصوير للمحاكي"
flutter build ios --simulator --debug --dart-define=SCREENSHOTS=true

UDID=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
c=[x for k,v in d.items() if 'iOS' in k for x in v if 'Pro Max' in x['name']]
print(c[-1]['udid'] if c else '')")
[ -n "$UDID" ] || { echo "❌ ما لقيت محاكي Pro Max"; xcrun simctl list devices available; exit 1; }
echo "▶ المحاكي: $UDID"

xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularMode active --cellularBars 4 || true
xcrun simctl install "$UDID" build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$UDID" sa.almubarky.bronz

python3 -m venv /tmp/frameenv
/tmp/frameenv/bin/pip install -q pillow arabic-reshaper python-bidi

mkdir -p "$OUT/ar-SA"
rm -f "$OUT/ar-SA/"*.png
DATA=$(xcrun simctl get_app_container "$UDID" sa.almubarky.bronz data)
mkdir -p "$DATA/tmp"
step() { echo "$1" > "$DATA/tmp/bronz_step"; echo "▶ الخطوة $1"; }
# يصوّر كل 6 ثوانٍ ولا يعتمد اللقطة إلا لما تثبت الشاشة وتكون الصور متحمّلة (حد أقصى ~150ث)
shot() {
  local name="$1" need="$2" last="${3:-}" prev="/tmp/shot_prev.png" cur="/tmp/shot_cur.png"
  sleep 12
  xcrun simctl io "$UDID" screenshot "$prev" >/dev/null
  for i in $(seq 1 23); do
    sleep 6
    xcrun simctl io "$UDID" screenshot "$cur" >/dev/null
    if /tmp/frameenv/bin/python "$ROOT/ci/shot_ready.py" "$prev" "$cur" "$need" $last; then break; fi
    mv "$cur" "$prev"
  done
  if [ -f "$cur" ]; then cp "$cur" "$OUT/ar-SA/$name.png"; else cp "$prev" "$OUT/ar-SA/$name.png"; fi
  echo "📸 $name"
}
sleep 30
shot "1_home" 120
A="$OUT/ar-SA"
step 1; shot "2_categories" 150 "$A/1_home.png"
step 2; shot "3_category" 120 "$A/2_categories.png"
step 3; shot "4_product" 60 "$A/3_category.png"
step 4; shot "5_account" 0 "$A/4_product.png"
xcrun simctl shutdown "$UDID" || true

echo "▶ فحص اللقطات (لو فيها صور فاضية يتوقف البناء وما يوصل لآبل شي)"
/tmp/frameenv/bin/python "$ROOT/ci/check_screenshots.py" "$OUT/ar-SA"

echo "▶ إخراج الصور التسويقية (خلفية سوداء + الشعار + العنوان)"
(
  curl -sL -o /tmp/Cairo.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf"
  /tmp/frameenv/bin/python "$ROOT/ci/frame_screenshots.py" "$OUT/ar-SA" /tmp/Cairo.ttf "$ROOT/assets/branding/BRONZ_app_icon_4096.png"
) || echo "⚠️ تعذّر الإخراج التسويقي — نكمل باللقطات الخام"

# نفس الصور للإنجليزي
mkdir -p "$OUT/en-US" && rm -f "$OUT/en-US/"*.png && cp "$OUT/ar-SA/"*.png "$OUT/en-US/"
ls -la "$OUT/ar-SA"
