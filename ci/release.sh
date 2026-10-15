#!/usr/bin/env bash
# بناء برونز ورفعه لـ App Store وإرساله للمراجعة.
# يُستدعى من ملف البناء في share2 بـ: bash bronz/ci/release.sh <رقم البناء>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash ci/ios_prepare.sh "${1:-1}"
bash ci/screenshots.sh

echo "▶ إرجاع إعدادات البناء للنسخة النهائية (بدون وضع التصوير)"
flutter build ios --release --config-only --no-codesign

echo "▶ نسخ بيانات المتجر"
rm -rf ios/fastlane/metadata && cp -R ci/store/metadata ios/fastlane/metadata

cd ios
fastlane release
