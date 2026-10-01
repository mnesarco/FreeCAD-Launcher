#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SVG="${1:-$REPO_ROOT/packaging/appimage/freecad-launcher.svg}"
OUTPUT="$REPO_ROOT/windows/runner/resources/app_icon.ico"

if [[ ! -f "$SVG" ]]; then
  echo "Master SVG not found: $SVG" >&2
  exit 1
fi

render() {
  local size="$1"
  local output="$2"
  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$size" -h "$size" "$SVG" -o "$output"
  elif command -v inkscape >/dev/null 2>&1; then
    inkscape "$SVG" --export-type=png --export-width="$size" --export-height="$size" \
      --export-filename="$output" >/dev/null
  else
    echo "Need rsvg-convert or inkscape to render $SVG" >&2
    exit 1
  fi
}

if ! command -v convert >/dev/null 2>&1; then
  echo "Need ImageMagick (convert) to write the .ico" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SIZES=(16 24 32 48 64 128 256)
PNGS=()
for size in "${SIZES[@]}"; do
  render "$size" "$TMP/icon-$size.png"
  PNGS+=("$TMP/icon-$size.png")
done

convert "${PNGS[@]}" "$OUTPUT"
echo "Wrote $OUTPUT"
