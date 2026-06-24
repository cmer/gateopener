#!/usr/bin/env bash
# Build GateOpener for release use and package it as a GitHub-hosted zip.

set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="GateOpener"
APP_PATH="build/$APP_NAME.app"
VERSION="${1:-}"

echo "-> Building $APP_NAME (Release)..."
make clean
make CONFIG=Release app

if [ ! -d "$APP_PATH" ]; then
  echo "Build succeeded but couldn't locate $APP_PATH" >&2
  exit 1
fi

if [ -n "$VERSION" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_PATH/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_PATH/Contents/Info.plist"
else
  VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
fi

echo "-> Ad-hoc signing..."
codesign --force --deep --sign - "$APP_PATH" >/dev/null

ZIP_PATH="build/$APP_NAME-$VERSION.zip"
rm -f "$ZIP_PATH"

echo "-> Creating $ZIP_PATH..."
(
  cd build
  /usr/bin/zip -qry -X "$APP_NAME-$VERSION.zip" "$APP_NAME.app"
)

SIZE=$(du -sh "$ZIP_PATH" | awk '{print $1}')
echo "Built: $APP_PATH"
echo "Packaged: $ZIP_PATH ($SIZE)"
