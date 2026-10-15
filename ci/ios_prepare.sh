#!/usr/bin/env bash
# تجهيز مشروع iOS لبرونز داخل GitHub Actions (يُستدعى من ملف البناء في share2).
# أي تعديل على خطوات البناء يصير هنا — بدون الحاجة لتعديل ملف الـ workflow.
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_NUMBER="${1:-1}"
BUNDLE_ID="sa.almubarky.bronz"

echo "▶ توليد مجلد iOS"
flutter create --org sa.almubarky --project-name bronz_app --platforms=ios .

echo "▶ رقم البناء: $BUILD_NUMBER"
sed -i '' -E "s/^version: (.*)\+.*/version: \1+$BUILD_NUMBER/" pubspec.yaml

echo "▶ هوية التطبيق"
P=ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName برونز" "$P"
/usr/libexec/PlistBuddy -c "Set :CFBundleName برونز" "$P"
/usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" "$P" || true
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "$P" || true
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:0 string remote-notification" "$P" || true
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = sa.almubarky.bronzApp;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" ios/Runner.xcodeproj/project.pbxproj

echo "▶ صلاحية الإشعارات (Push)"
cat > ios/Runner/Runner.entitlements <<'EOF'
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

echo "▶ Pods"
cd ios && pod install --repo-update && cd ..
flutter build ios --release --config-only --no-codesign

echo "▶ إعدادات fastlane"
mkdir -p ios/fastlane
cp ci/Fastfile ios/fastlane/Fastfile
echo "✅ التجهيز اكتمل"
