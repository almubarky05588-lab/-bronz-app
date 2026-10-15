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
shot() { sleep "$1"; xcrun simctl io "$UDID" screenshot "$OUT/ar-SA/$2.png"; echo "📸 $2"; }
shot 34 "1_home"       # الرئيسية بعد ما تحمّل المنتجات
shot 14 "2_categories" # الأقسام (التطبيق ينتقل لها عند الثانية 40)
shot 15 "3_account"    # حسابي (عند الثانية 55)

# نفس الصور للإنجليزي (لو لغة التطبيق الأساسية في App Store إنجليزية)
mkdir -p "$OUT/en-US" && cp "$OUT/ar-SA/"*.png "$OUT/en-US/"
xcrun simctl shutdown "$UDID" || true
ls -la "$OUT/ar-SA"
