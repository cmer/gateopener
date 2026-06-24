#!/usr/bin/env bash
# Build a production zip and publish it to GitHub Releases.

set -euo pipefail

cd "$(dirname "$0")/.."

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <version>" >&2
  echo "Example: $0 1.0.0" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is required: https://cli.github.com/" >&2
  exit 1
fi

VERSION="$1"
TAG="v$VERSION"
ZIP_PATH="build/GateOpener-$VERSION.zip"
GH_REPO="${GH_REPO:-cmer/gateopener}"

./scripts/build-prod.sh "$VERSION"

echo "-> Creating GitHub release $TAG..."
gh release create "$TAG" "$ZIP_PATH" \
  --repo "$GH_REPO" \
  --title "GateOpener $VERSION" \
  --notes "GateOpener $VERSION release."

echo "Published: $TAG to $GH_REPO"
