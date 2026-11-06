#!/usr/bin/env bash
# تجهيز مشروع Android لبرونز داخل GitHub Actions (يُستدعى من ملف البناء في share2).
# يولّد مجلد android من Flutter ثم يضبط الهوية والتوقيع ويبني ملف AAB لقوقل بلاي.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD_NUMBER="$(( ${1:-1} + 1000 ))"
APP_ID="sa.almubarky.bronz"

echo "▶ خط الأيقونات (BronzIcons)"
python3 -m venv /tmp/iconenv
/tmp/iconenv/bin/pip install -q picosvg fonttools skia-pathops
/tmp/iconenv/bin/python "$ROOT/ci/build_icons.py" "$ROOT/packages/phosphor_flutter/fonts/BronzIcons.ttf"

echo "▶ توليد مجلد Android"
flutter create --org sa.almubarky --project-name bronz_app --platforms=android .

echo "▶ رقم البناء: $BUILD_NUMBER"
sed -i -E "s/^version: (.*)\+.*/version: \1+$BUILD_NUMBER/" pubspec.yaml
# الأيقونة والشاشة الافتتاحية لأندرويد أيضًا
sed -i -E 's/^(\s*)android: false/\1android: true/' pubspec.yaml

echo "▶ هوية التطبيق والتوقيع"
python3 - "$ROOT" "$APP_ID" <<'PY'
import sys, os, re
root, app_id = sys.argv[1], sys.argv[2]
kts = os.path.join(root, 'android/app/build.gradle.kts')
groovy = os.path.join(root, 'android/app/build.gradle')
if os.path.exists(kts):
    s = open(kts).read()
    s = re.sub(r'applicationId\s*=\s*"[^"]+"', f'applicationId = "{app_id}"', s)
    s = re.sub(r'minSdk\s*=\s*[^\n]+', 'minSdk = 23', s)
    s = s.replace('signingConfig = signingConfigs.getByName("debug")',
                  'signingConfig = signingConfigs.getByName("release")')
    signing = '''
    signingConfigs {
        create("release") {
            val props = java.util.Properties()
            val f = rootProject.file("key.properties")
            if (f.exists()) props.load(java.io.FileInputStream(f))
            storeFile = rootProject.file(props.getProperty("storeFile", "upload.jks"))
            storePassword = props.getProperty("storePassword", "")
            keyAlias = props.getProperty("keyAlias", "bronz")
            keyPassword = props.getProperty("keyPassword", "")
        }
    }
    buildTypes {'''
    s = s.replace('\n    buildTypes {', signing, 1)
    open(kts, 'w').write(s)
elif os.path.exists(groovy):
    s = open(groovy).read()
    s = re.sub(r'applicationId\s*=?\s*"[^"]+"', f'applicationId "{app_id}"', s)
    s = re.sub(r'minSdk\s*=?\s*[^\n]+', 'minSdk 23', s)
    s = s.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release')
    s = s.replace('signingConfig = signingConfigs.debug', 'signingConfig = signingConfigs.release')
    signing = '''
    signingConfigs {
        release {
            def props = new Properties()
            def f = rootProject.file("key.properties")
            if (f.exists()) props.load(new FileInputStream(f))
            storeFile rootProject.file(props.getProperty("storeFile", "upload.jks"))
            storePassword props.getProperty("storePassword", "")
            keyAlias props.getProperty("keyAlias", "bronz")
            keyPassword props.getProperty("keyPassword", "")
        }
    }
    buildTypes {'''
    s = s.replace('\n    buildTypes {', signing, 1)
    open(groovy, 'w').write(s)
else:
    sys.exit('❌ ما لقيت build.gradle')

m = os.path.join(root, 'android/app/src/main/AndroidManifest.xml')
s = open(m).read()
s = re.sub(r'android:label="[^"]*"', 'android:label="برونز"', s, 1)
if 'android.permission.INTERNET' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
open(m, 'w').write(s)
print('✓ build.gradle + AndroidManifest')
PY

echo "▶ مفتاح التوقيع"
if [ -n "${ANDROID_KEYSTORE_B64:-}" ]; then
  echo "$ANDROID_KEYSTORE_B64" | tr -d '[:space:]' | base64 -d > "$ROOT/android/upload.jks"
  cat > "$ROOT/android/key.properties" <<EOP
storeFile=upload.jks
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyAlias=bronz
keyPassword=${ANDROID_KEYSTORE_PASSWORD}
EOP
else
  echo "❌ أضف ANDROID_KEYSTORE_B64 و ANDROID_KEYSTORE_PASSWORD في أسرار المستودع"; exit 1
fi

echo "▶ المكتبات والأيقونة والشاشة الافتتاحية"
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create

echo "▶ بناء AAB (قوقل بلاي) + APK (للتجربة المباشرة)"
flutter build appbundle --release
flutter build apk --release
mkdir -p "$ROOT/out"
cp build/app/outputs/bundle/release/app-release.aab "$ROOT/out/bronz-$BUILD_NUMBER.aab"
cp build/app/outputs/flutter-apk/app-release.apk "$ROOT/out/bronz-$BUILD_NUMBER.apk"
ls -la "$ROOT/out"
echo "✅ التجهيز اكتمل"
