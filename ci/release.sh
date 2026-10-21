#!/usr/bin/env bash
# بناء برونز ورفعه لـ App Store (النسخة + البيانات).
# الصور تُرفع يدويًا من App Store Connect، والإرسال للمراجعة يدوي (Add for Review).
# (التصوير التلقائي موجود في ci/screenshots.sh لو احتجناه لاحقًا)
# يُستدعى من ملف البناء في share2 بـ: bash bronz/ci/release.sh <رقم البناء>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash ci/ios_prepare.sh "${1:-1}"

echo "▶ نسخ بيانات المتجر"
rm -rf ios/fastlane/metadata && cp -R ci/store/metadata ios/fastlane/metadata

cd ios
fastlane release
