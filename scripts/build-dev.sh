#!/usr/bin/env bash
# Build GateOpener for development and launch it.

set -euo pipefail

cd "$(dirname "$0")/.."

APP_PATH="build/GateOpener.app"

echo "-> Building GateOpener (Debug)..."
make CONFIG=Debug app

if [ ! -d "$APP_PATH" ]; then
  echo "Build succeeded but couldn't locate $APP_PATH" >&2
  exit 1
fi

echo "Built: $APP_PATH"
echo "-> Launching..."
open "$APP_PATH"
