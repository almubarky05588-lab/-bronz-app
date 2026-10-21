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

mkdir -p "$OUT/ar-SA"
rm -f "$OUT/ar-SA/"*.png
DATA=$(xcrun simctl get_app_container "$UDID" sa.almubarky.bronz data)
mkdir -p "$DATA/tmp"
shot() { xcrun simctl io "$UDID" screenshot "$OUT/ar-SA/$1.png"; echo "📸 $1"; }
# السكربت يقود التطبيق: يصوّر ← يطلب الشاشة التالية ← ينتظر تحميلها ← يصوّر
step() { echo "$1" > "$DATA/tmp/bronz_step"; echo "▶ الخطوة $1"; }
sleep 90;  shot "1_home"        # الرئيسية
step 1; sleep 50;  shot "2_categories"  # الأقسام
step 2; sleep 50;  shot "3_category"    # صفحة قسم
step 3; sleep 50;  shot "4_product"     # صفحة منتج
step 4; sleep 20;  shot "5_account"     # حسابي
xcrun simctl shutdown "$UDID" || true

echo "▶ فحص اللقطات (لو فيها صور فاضية يتوقف البناء وما يوصل لآبل شي)"
python3 -m venv /tmp/frameenv
/tmp/frameenv/bin/pip install -q pillow arabic-reshaper python-bidi
/tmp/frameenv/bin/python "$ROOT/ci/check_screenshots.py" "$OUT/ar-SA"

echo "▶ إخراج الصور التسويقية (خلفية سوداء + الشعار + العنوان)"
(
  curl -sL -o /tmp/Cairo.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf"
  /tmp/frameenv/bin/python "$ROOT/ci/frame_screenshots.py" "$OUT/ar-SA" /tmp/Cairo.ttf "$ROOT/assets/branding/BRONZ_app_icon_4096.png"
) || echo "⚠️ تعذّر الإخراج التسويقي — نكمل باللقطات الخام"

# نفس الصور للإنجليزي
mkdir -p "$OUT/en-US" && rm -f "$OUT/en-US/"*.png && cp "$OUT/ar-SA/"*.png "$OUT/en-US/"
ls -la "$OUT/ar-SA"
