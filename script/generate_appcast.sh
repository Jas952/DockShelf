#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version>" >&2
  exit 64
fi

VERSION="$1"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$(uname -m)"
ARCHIVE="$ROOT_DIR/release/DockShelf-${VERSION}-macOS-${ARCH}.zip"
SPARKLE_BIN="$ROOT_DIR/.build/artifacts/sparkle/Sparkle/bin/generate_appcast"
OUTPUT_DIR="$ROOT_DIR/.github"
TEMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Release archive not found: $ARCHIVE" >&2
  exit 66
fi

if [[ ! -x "$SPARKLE_BIN" ]]; then
  echo "Sparkle tools are unavailable. Run 'swift build' first." >&2
  exit 69
fi

cp "$ARCHIVE" "$TEMP_DIR/"

"$SPARKLE_BIN" \
  --account DockShelf \
  --download-url-prefix "https://github.com/Jas952/DockShelf/releases/download/v${VERSION}/" \
  --link "https://github.com/Jas952/DockShelf/releases" \
  --maximum-versions 0 \
  "$TEMP_DIR"

cp "$TEMP_DIR/appcast.xml" "$OUTPUT_DIR/appcast.xml"
echo "Updated $OUTPUT_DIR/appcast.xml"
