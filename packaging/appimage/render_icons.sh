#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SVG="${1:-$SCRIPT_DIR/freecad-launcher.svg}"

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
  echo "Rendered $output"
}

render 512 "$SCRIPT_DIR/freecad-launcher.png"
render 256 "$SCRIPT_DIR/freecad-launcher-256.png"
