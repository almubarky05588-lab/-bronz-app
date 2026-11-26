#!/usr/bin/env bash
# بناء برونز ورفعه لـ App Store وإرساله للمراجعة — كله تلقائي:
# يصوّر 5 شاشات ← يفحصها (لو فيها صور فاضية يتوقف) ← يخرجها تسويقيًا ← يرفع ويرسل.
# يُستدعى من ملف البناء في share2 بـ: bash bronz/ci/release.sh <رقم البناء>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash ci/ios_prepare.sh "${1:-1}"
# لو التصوير فشل (مثلًا المتجر ما فتح في المحاكي) نكمل الرفع بصور المتجر الحالية بدل ما يتوقف كل شي
if bash ci/screenshots.sh; then
  export SKIP_SHOTS=0
else
  echo "⚠️ التصوير ما نجح — نرفع النسخة بصور App Store الحالية"
  export SKIP_SHOTS=1
fi

echo "▶ إرجاع إعدادات البناء للنسخة النهائية (بدون وضع التصوير)"
flutter build ios --release --config-only --no-codesign

echo "▶ نسخ بيانات المتجر"
rm -rf ios/fastlane/metadata && cp -R ci/store/metadata ios/fastlane/metadata

cd ios
fastlane release
