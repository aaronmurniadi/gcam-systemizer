#!/bin/bash
# Build the Google Camera systemizer module zip from the Google Camera install on the
# connected phone. Two phones attached? Set ANDROID_SERIAL=<serial>.
# Usage: ./build.sh
# Output: dist/GoogleCamera-Systemizer-<version>.zip

set -euo pipefail

PKG="com.google.android.GoogleCamera"
ROOT="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$ROOT/module"
APK_DIR="$MODULE_DIR/system/priv-app/GoogleCamera"
STAGE="/sdcard/Download/.gcam_module_stage"

echo "== 1. check device =="
adb get-state >/dev/null || { echo "No device. Check adb devices."; exit 1; }

echo "== 2. find installed APK directory =="
BASE_PATH="$(adb shell "pm path $PKG" | sed -n '1p' | sed 's/^package://' | tr -d '\r')"
if [ -z "$BASE_PATH" ]; then
  echo "Package $PKG is not installed."
  exit 1
fi
APK_SRC_DIR="$(dirname "$BASE_PATH")"
echo "   $APK_SRC_DIR"

echo "== 3. copy APKs from the phone =="
adb shell "su -c 'rm -rf $STAGE && mkdir -p $STAGE && cp $APK_SRC_DIR/*.apk $STAGE/ && chmod 644 $STAGE/*.apk'"
rm -rf "$APK_DIR"
mkdir -p "$APK_DIR"
adb pull "$STAGE" "$APK_DIR" >/dev/null
mv "$APK_DIR"/.gcam_module_stage/*.apk "$APK_DIR"/
rmdir "$APK_DIR/.gcam_module_stage"
adb shell "su -c 'rm -rf $STAGE'"

COUNT=$(ls -1 "$APK_DIR"/*.apk 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" = "0" ]; then
  echo "No APK files copied."
  exit 1
fi
echo "   $COUNT APK files"
ls -la "$APK_DIR"

echo "== 4. read version from the phone =="
VERSION_NAME="$(adb shell "dumpsys package $PKG" | grep -m1 'versionName=' | sed 's/.*versionName=//' | tr -d '\r')"
VERSION_CODE="$(adb shell "dumpsys package $PKG" | grep -m1 'versionCode=' | sed 's/.*versionCode=//' | sed 's/ .*//' | tr -d '\r')"
if [ -z "$VERSION_NAME" ]; then
  VERSION_NAME="unknown"
fi
if [ -z "$VERSION_CODE" ]; then
  VERSION_CODE="1"
fi
echo "   $VERSION_NAME ($VERSION_CODE)"

sed -i '' "s/^version=.*/version=v$VERSION_NAME/" "$MODULE_DIR/module.prop"
sed -i '' "s/^versionCode=.*/versionCode=$VERSION_CODE/" "$MODULE_DIR/module.prop"

echo "== 5. zip module =="
mkdir -p "$ROOT/dist"
ZIP="$ROOT/dist/GoogleCamera-Systemizer-$VERSION_NAME.zip"
rm -f "$ZIP"
cd "$MODULE_DIR"
zip -r -0 -X "$ZIP" . -x '.*' >/dev/null
cd "$ROOT"

echo "== 6. result =="
ls -la "$ZIP"
unzip -l "$ZIP" | head -15
echo "Done: $ZIP"
