#!/usr/bin/env bash
# تجهيز مشروع iOS لبرونز داخل GitHub Actions (يُستدعى من ملف البناء في share2).
# أي تعديل على خطوات البناء يصير هنا — بدون الحاجة لتعديل ملف الـ workflow.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# +1000 حتى يكون رقم كل بناء جديد (TestFlight أو المتجر) أكبر من آخر رقم انرفع لآبل
BUILD_NUMBER="$(( ${1:-1} + 1000 ))"
BUNDLE_ID="sa.almubarky.bronz"

echo "▶ خط الأيقونات (BronzIcons)"
python3 -m venv /tmp/iconenv
/tmp/iconenv/bin/pip install -q picosvg fonttools skia-pathops
/tmp/iconenv/bin/python "$ROOT/ci/build_icons.py" "$ROOT/packages/phosphor_flutter/fonts/BronzIcons.ttf"

echo "▶ توليد مجلد iOS"
flutter create --org sa.almubarky --project-name bronz_app --platforms=ios .

echo "▶ رقم البناء: $BUILD_NUMBER"
sed -i '' -E "s/^version: (.*)\+.*/version: \1+$BUILD_NUMBER/" pubspec.yaml

echo "▶ هوية التطبيق"
P="$ROOT/ios/Runner/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName برونز" "$P"
/usr/libexec/PlistBuddy -c "Set :CFBundleName برونز" "$P"
/usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" "$P" || true
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "$P" || true
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:0 string remote-notification" "$P" || true
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = sa.almubarky.bronzApp;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" "$ROOT/ios/Runner.xcodeproj/project.pbxproj"
# آيفون فقط (بدون آيباد) — يكفي صور آيفون في App Store
sed -i '' 's/TARGETED_DEVICE_FAMILY = "1,2";/TARGETED_DEVICE_FAMILY = 1;/g' "$ROOT/ios/Runner.xcodeproj/project.pbxproj"
/usr/libexec/PlistBuddy -c "Delete :UISupportedInterfaceOrientations~ipad" "$P" || true

echo "▶ صلاحية الإشعارات (Push)"
cat > "$ROOT/ios/Runner/Runner.entitlements" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>production</string>
</dict>
</plist>
EOF

echo "▶ المكتبات والأيقونة والشاشة الافتتاحية"
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# Flutter الحالي يستخدم Swift Package Manager؛ CocoaPods فقط لو وُجد Podfile
if [ -f "$ROOT/ios/Podfile" ]; then
  echo "▶ Pods"
  (cd "$ROOT/ios" && pod install --repo-update)
fi

echo "▶ تجهيز ملفات Xcode"
cd "$ROOT"
flutter build ios --release --config-only --no-codesign

echo "▶ إعدادات fastlane"
mkdir -p "$ROOT/ios/fastlane"
cp "$ROOT/ci/Fastfile" "$ROOT/ios/fastlane/Fastfile"
echo "✅ التجهيز اكتمل"
