#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

APP_NAME="FreeCADLauncher"
ARCH="${ARCH:-x86_64}"
VERSION="${VERSION:-$(sed -n "s/^const String appVersion = '\(.*\)';/\1/p" "$PROJECT_ROOT/lib/core/constants.dart")}"
OWNER="${APPIMAGE_OWNER:-REPLACE_OWNER}"
REPO="${APPIMAGE_REPO:-REPLACE_REPO}"
CHANNEL="${APPIMAGE_CHANNEL:-latest}"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/build/appimage}"
APPIMAGETOOL="${APPIMAGETOOL:-$OUTPUT_DIR/tools/appimagetool-$ARCH.AppImage}"
APPIMAGETOOL_URL="${APPIMAGETOOL_URL:-https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage}"
APPIMAGETOOL_SHA256="${APPIMAGETOOL_SHA256:-ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0}"
RUNTIME_FILE="${RUNTIME_FILE:-$OUTPUT_DIR/tools/runtime-$ARCH}"
RUNTIME_URL="${APPIMAGE_RUNTIME_URL:-https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64}"
RUNTIME_SHA256="${APPIMAGE_RUNTIME_SHA256:-1cc49bcf1e2ccd593c379adb17c9f85a36d619088296504de95b1d06215aebbf}"
SKIP_BUILD="${SKIP_BUILD:-0}"

if [[ -z "$VERSION" ]]; then
  echo "error: could not read appVersion from lib/core/constants.dart" >&2
  exit 1
fi

"$SCRIPT_DIR/../check_version.sh"

if [[ ( "$OWNER" == "REPLACE_OWNER" || "$REPO" == "REPLACE_REPO" ) && "${ALLOW_PLACEHOLDER_UPDATE_INFO:-0}" != "1" ]]; then
  echo "error: APPIMAGE_OWNER/APPIMAGE_REPO are placeholders; set them or ALLOW_PLACEHOLDER_UPDATE_INFO=1 for local builds" >&2
  exit 1
fi

if [[ -z "${SOURCE_DATE_EPOCH:-}" ]]; then
  SOURCE_DATE_EPOCH="$(git -C "$PROJECT_ROOT" log -1 --format=%ct 2>/dev/null || echo 0)"
fi
export SOURCE_DATE_EPOCH

log() { printf '\n==> %s\n' "$*"; }

APPDIR="$OUTPUT_DIR/AppDir"
BUNDLE="$PROJECT_ROOT/build/linux/x64/release/bundle"
OUTPUT="$OUTPUT_DIR/$APP_NAME-$VERSION-$ARCH.AppImage"

# Official AppImage excludelist (vendored) plus a force-bundle set: the font/text
# stack is listed upstream but is not guaranteed on minimal systems, and the spike
# verified it is needed on clean containers.
EXCLUDELIST_FILE="$SCRIPT_DIR/excludelist"
FORCE_BUNDLE='libharfbuzz.so.0 libfreetype.so.6 libfontconfig.so.1 libexpat.so.1 libz.so.1 libuuid.so.1 libfribidi.so.0 libgmp.so.10 libcom_err.so.2 libgpg-error.so.0 libICE.so.6 libSM.so.6'

log "Building the Flutter release bundle (version $VERSION)"
if [[ "$SKIP_BUILD" != "1" ]]; then
  (cd "$PROJECT_ROOT" && flutter build linux --release)
fi
if [[ ! -x "$BUNDLE/freecad_launcher" ]]; then
  echo "error: $BUNDLE/freecad_launcher not found; run without SKIP_BUILD=1 first" >&2
  exit 1
fi

log "Staging AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" \
  "$APPDIR/usr/share/applications"
cp -a "$BUNDLE/." "$APPDIR/usr/bin/"
cp "$SCRIPT_DIR/AppRun" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"
cp "$SCRIPT_DIR/freecad-launcher.desktop" "$APPDIR/freecad-launcher.desktop"
cp "$SCRIPT_DIR/freecad-launcher.desktop" "$APPDIR/usr/share/applications/"
cp "$SCRIPT_DIR/freecad-launcher.png" "$APPDIR/freecad-launcher.png"
for icon_size in 16 32 48 64 128 256 512; do
  install -Dm644 "$SCRIPT_DIR/freecad-launcher-$icon_size.png" \
    "$APPDIR/usr/share/icons/hicolor/${icon_size}x${icon_size}/apps/freecad-launcher.png"
done
install -Dm644 "$PROJECT_ROOT/LICENSE" "$APPDIR/usr/share/doc/freecad-launcher/LICENSE"
install -Dm644 "$PROJECT_ROOT/THIRD_PARTY_NOTICES.md" \
  "$APPDIR/usr/share/doc/freecad-launcher/THIRD_PARTY_NOTICES.md"

log "Bundling non-baseline shared libraries"
if [[ -f "$EXCLUDELIST_FILE" ]]; then
  excluded_libs="$(grep -vE '^#|^[[:space:]]*$' "$EXCLUDELIST_FILE" | awk '{print $1}' | tr '\n' ' ')"
else
  excluded_libs='ld-linux-x86-64.so.2 libc.so.6 libdl.so.2 libm.so.6 libpthread.so.0 librt.so.1 libstdc++.so.6 libgcc_s.so.1 libGL.so.1 libEGL.so.1 libdrm.so.2 libX11.so.6 libxcb.so.1'
fi
queue=("$APPDIR/usr/bin/freecad_launcher")
while IFS= read -r -d '' lib; do
  queue+=("$lib")
done < <(find "$APPDIR/usr/bin/lib" -maxdepth 1 -name '*.so*' -print0)
seen=""
while ((${#queue[@]} > 0)); do
  current="${queue[0]}"
  queue=("${queue[@]:1}")
  while IFS= read -r resolved; do
    [[ -z "$resolved" ]] && continue
    base="$(basename "$resolved")"
    if [[ " $FORCE_BUNDLE " == *" $base "* ]]; then
      :
    else
      case " $excluded_libs " in *" $base "*) continue ;; esac
    fi
    case " $seen " in *" $base "*) continue ;; esac
    seen="$seen $base"
    cp -L "$resolved" "$APPDIR/usr/lib/$base"
    queue+=("$APPDIR/usr/lib/$base")
  done < <(ldd "$current" 2>/dev/null | awk '/=>/ && $3 ~ /^\// {print $3} /^\// {print $1}')
done

log "Adding unversioned symlinks for the bundled glib family"
for name in libgio-2.0 libglib-2.0 libgobject-2.0 libgmodule-2.0; do
  if [[ -f "$APPDIR/usr/lib/$name.so.0" && ! -e "$APPDIR/usr/lib/$name.so" ]]; then
    ln -s "$name.so.0" "$APPDIR/usr/lib/$name.so"
  fi
done

log "Fetching appimagetool and the type-2 runtime"
mkdir -p "$OUTPUT_DIR/tools"
if [[ ! -x "$APPIMAGETOOL" ]]; then
  curl -sSL --fail --max-time 300 -o "$APPIMAGETOOL" "$APPIMAGETOOL_URL"
  chmod +x "$APPIMAGETOOL"
fi
echo "$APPIMAGETOOL_SHA256  $APPIMAGETOOL" | sha256sum -c -
if [[ ! -f "$RUNTIME_FILE" ]]; then
  curl -sSL --fail --max-time 300 -o "$RUNTIME_FILE" "$RUNTIME_URL"
fi
echo "$RUNTIME_SHA256  $RUNTIME_FILE" | sha256sum -c -

log "Packaging the AppImage"
UPDATE_INFO="gh-releases-zsync|$OWNER|$REPO|$CHANNEL|$APP_NAME-*-$ARCH.AppImage.zsync"
rm -f "$OUTPUT" "$OUTPUT.zsync" "$OUTPUT.sha256"
(
  cd "$OUTPUT_DIR"
  APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" \
    --no-appstream \
    --runtime-file "$RUNTIME_FILE" \
    -u "$UPDATE_INFO" \
    "$APPDIR" "$OUTPUT"
)

log "Writing the checksum sidecar and the zsync file"
touch -d "@$SOURCE_DATE_EPOCH" "$OUTPUT"
if command -v zsyncmake >/dev/null 2>&1; then
  FILE_URL="${APPIMAGE_FILE_URL:-https://github.com/$OWNER/$REPO/releases/download/$CHANNEL/$APP_NAME-$VERSION-$ARCH.AppImage}"
  zsyncmake -u "$FILE_URL" -o "$OUTPUT.zsync" "$OUTPUT"
else
  echo "note: zsyncmake missing; keeping the zsync generated by appimagetool (if any)"
fi
(cd "$OUTPUT_DIR" && sha256sum "$(basename "$OUTPUT")" > "$(basename "$OUTPUT").sha256")

log "Result"
ls -l "$OUTPUT" "$OUTPUT.sha256" 2>/dev/null || true
ls -l "$OUTPUT.zsync" 2>/dev/null || echo "note: no .zsync generated (zsyncmake missing?)"
"$OUTPUT" --appimage-updateinformation || true
