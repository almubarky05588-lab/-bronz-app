#!/usr/bin/env bash
# يصوّر شاشات App Store تلقائيًا على آيفون افتراضي (6.9 إنش).
# التطبيق يُبنى بوضع SCREENSHOTS فيتنقّل بين الشاشات بنفسه (lib/screens/shell.dart).
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
shot() { sleep "$1"; xcrun simctl io "$UDID" screenshot "$OUT/ar-SA/$2.png"; echo "📸 $2"; }
# التوقيت يطابق جولة التصوير في lib/screens/shell.dart (وقت كافٍ حتى تتحمّل كل الصور)
shot 70 "1_home"        # الرئيسية
shot 35 "2_categories"  # الأقسام (التطبيق ينتقل لها عند 75ث)
shot 45 "3_category"    # صفحة قسم (عند 110ث)
shot 40 "4_product"     # صفحة منتج (عند 155ث)
shot 25 "5_account"     # حسابي (عند 195ث)
xcrun simctl shutdown "$UDID" || true

echo "▶ إخراج الصور التسويقية (خلفية سوداء + الشعار + العنوان)"
(
  python3 -m venv /tmp/frameenv
  /tmp/frameenv/bin/pip install -q pillow arabic-reshaper python-bidi
  curl -sL -o /tmp/Cairo.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf"
  /tmp/frameenv/bin/python "$ROOT/ci/frame_screenshots.py" "$OUT/ar-SA" /tmp/Cairo.ttf "$ROOT/assets/branding/BRONZ_app_icon_4096.png"
) || echo "⚠️ تعذّر الإخراج التسويقي — نكمل باللقطات الخام"

# نفس الصور للإنجليزي
mkdir -p "$OUT/en-US" && rm -f "$OUT/en-US/"*.png && cp "$OUT/ar-SA/"*.png "$OUT/en-US/"
ls -la "$OUT/ar-SA"
