#!/usr/bin/env bash
# Build, Developer ID sign, notarize, package, and publish GateOpener.

set -euo pipefail

cd "$(dirname "$0")/.."

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <version>" >&2
  echo "Example: $0 1.2.0" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is required: https://cli.github.com/" >&2
  exit 1
fi

if ! xcrun notarytool --version >/dev/null 2>&1; then
  echo "Xcode notarytool is required. Install Xcode and select it with xcode-select." >&2
  exit 1
fi

VERSION="$1"
APP_NAME="GateOpener"
APP_PATH="build/$APP_NAME.app"
ZIP_PATH="build/$APP_NAME-$VERSION.zip"
TAG="v$VERSION"
GH_REPO="${GH_REPO:-cmer/gateopener}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
RELEASE_BUNDLE_ID="${BUNDLE_ID:-com.cmer.gateopener}"
CURRENT_BRANCH="$(git branch --show-current)"

is_interactive() {
  [ -t 0 ] && [ -t 1 ]
}

choose_developer_id_identity() {
  if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
    return
  fi

  local identities=()
  local identity

  while IFS= read -r identity; do
    identities+=("$identity")
  done < <(
    security find-identity -v -p codesigning |
      sed -n 's/^ *[0-9]*) [A-F0-9]* "\(Developer ID Application: .*\)"/\1/p'
  )

  case "${#identities[@]}" in
    0)
      echo "No Developer ID Application signing identity was found." >&2
      echo "Install your Developer ID Application certificate, then rerun:" >&2
      echo "  security find-identity -v -p codesigning" >&2
      exit 1
      ;;
    1)
      DEVELOPER_ID_APPLICATION="${identities[0]}"
      echo "-> Using signing identity: $DEVELOPER_ID_APPLICATION"
      ;;
    *)
      if ! is_interactive; then
        echo "Multiple Developer ID Application identities found." >&2
        echo "Set DEVELOPER_ID_APPLICATION to the exact identity to use." >&2
        exit 1
      fi

      echo "Choose a Developer ID Application signing identity:"
      local index
      for index in "${!identities[@]}"; do
        printf "  %d) %s\n" "$((index + 1))" "${identities[$index]}"
      done

      local choice
      read -r -p "Signing identity number: " choice
      if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
        [ "$choice" -lt 1 ] ||
        [ "$choice" -gt "${#identities[@]}" ]; then
        echo "Invalid signing identity selection." >&2
        exit 1
      fi

      DEVELOPER_ID_APPLICATION="${identities[$((choice - 1))]}"
      ;;
  esac
}

choose_notary_profile() {
  if [ -n "$NOTARY_PROFILE" ]; then
    return
  fi

  local default_profile="bloomworks-notary"

  if is_interactive; then
    local entered_profile
    read -r -p "Notary keychain profile [$default_profile]: " entered_profile
    NOTARY_PROFILE="${entered_profile:-$default_profile}"
  else
    NOTARY_PROFILE="$default_profile"
  fi
}

confirm_release() {
  if [ "${SKIP_RELEASE_CONFIRMATION:-}" = "1" ] || ! is_interactive; then
    return
  fi

  echo
  echo "Release configuration:"
  echo "  Version: $VERSION"
  echo "  Tag: $TAG"
  echo "  Branch: $CURRENT_BRANCH"
  echo "  GitHub repo: $GH_REPO"
  echo "  Bundle ID: $RELEASE_BUNDLE_ID"
  echo "  Signing identity: $DEVELOPER_ID_APPLICATION"
  echo "  Notary profile: $NOTARY_PROFILE"
  echo

  local answer
  read -r -p "Build, notarize, and publish this release? [y/N] " answer
  case "$answer" in
    y | Y | yes | YES)
      ;;
    *)
      echo "Release canceled."
      exit 0
      ;;
  esac
}

if [ -n "$(git status --porcelain)" ]; then
  echo "Refusing to release with uncommitted changes." >&2
  exit 1
fi

if git rev-parse --verify --quiet "$TAG" >/dev/null; then
  echo "Tag $TAG already exists locally." >&2
  exit 1
fi

if gh release view "$TAG" --repo "$GH_REPO" >/dev/null 2>&1; then
  echo "GitHub release $TAG already exists in $GH_REPO." >&2
  exit 1
fi

gh auth status >/dev/null
choose_developer_id_identity
choose_notary_profile
confirm_release

echo "-> Building $APP_NAME $VERSION (Release)..."
make clean
make CONFIG=Release BUNDLE_ID="$RELEASE_BUNDLE_ID" app

if [ ! -d "$APP_PATH" ]; then
  echo "Build succeeded but couldn't locate $APP_PATH" >&2
  exit 1
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_PATH/Contents/Info.plist"

echo "-> Signing with Developer ID..."
codesign \
  --force \
  --deep \
  --options runtime \
  --timestamp \
  --sign "$DEVELOPER_ID_APPLICATION" \
  "$APP_PATH"

echo "-> Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

rm -f "$ZIP_PATH"

echo "-> Creating notarization upload $ZIP_PATH..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "-> Notarizing with profile $NOTARY_PROFILE..."
xcrun notarytool submit "$ZIP_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

echo "-> Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "-> Repackaging stapled app..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "-> Assessing Gatekeeper acceptance..."
spctl --assess --type execute --verbose=4 "$APP_PATH"

SIZE=$(du -sh "$ZIP_PATH" | awk '{print $1}')
echo "Built: $APP_PATH"
echo "Packaged: $ZIP_PATH ($SIZE)"

echo "-> Creating GitHub release $TAG..."
gh release create "$TAG" "$ZIP_PATH" \
  --repo "$GH_REPO" \
  --target "$CURRENT_BRANCH" \
  --title "$APP_NAME $VERSION" \
  --notes "$APP_NAME $VERSION release."

echo "Published: $TAG to $GH_REPO"
