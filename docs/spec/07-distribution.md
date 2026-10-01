# 07 — Distribution

## 1. Versioning

- Semantic versioning for the launcher: `MAJOR.MINOR.PATCH`, git tags `vX.Y.Z`.
- Version lives in one place (`lib/core/constants.dart` + `pubspec.yaml`); CI verifies they match.
- Pre-releases: `vX.Y.Z-beta.N` published as GitHub pre-releases.
- CHANGELOG.md maintained per release (Keep a Changelog format).

## 2. Launcher artifacts

| OS | v0.1 artifact | Notes |
|---|---|---|
| Linux | `FreeCADLauncher-<ver>-x86_64.AppImage` + `.sha256` | Primary distribution channel (locked decision) |
| Windows | none in v0.1 | See OQ-1; `flutter build windows` must still succeed in CI |
| macOS | none in v0.1 | See OQ-1; `flutter build macos` must still succeed in CI |

The launcher itself never bundles FreeCAD; it downloads builds at runtime. This keeps the
license surface clean (GPL-3.0-or-later for our code; FreeCAD remains distributed by its authors).

## 3. Linux AppImage build

Proposed pipeline (spike S5 to validate tooling):

1. `flutter build linux --release` producing `build/linux/<arch>/release/bundle/`.
2. Assemble an AppDir:
   - `AppRun` (sets `LD_LIBRARY_PATH`, launches `freecad_launcher`),
   - `.desktop` file with `StartupWMClass`, icon,
   - copy bundle contents + required GTK/GLib libs not present on target distros.
3. Package with `appimagetool` (type-2, squashfs zstd), setting an update-information string
   (`gh-releases-zsync|<owner>|<repo>|<channel>|<asset-pattern>.zsync`).
4. Emit `-SHA256.txt` sidecar.

Application identity is `org.freecad.ext.launcher` (D-016); the `.desktop` file and icon name are
`freecad-launcher`. The icon is an **original design** (D-070): the editable master lives in
`packaging/appimage/freecad-launcher.svg` and `render_icons.sh` renders the committed PNGs the
build consumes; the official FreeCAD logo is not bundled. The AppImage name is
`FreeCADLauncher-<ver>-x86_64.AppImage`.

## 4. CI/CD

### 4.1 Pull requests

GitHub Actions matrix (`ubuntu-latest`, `windows-latest`, `macos-latest`):

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code            # generated files must be committed
flutter analyze
flutter test
flutter build <platform> --release
```

### 4.2 Release workflow (tag `v*`)

1. Run the full test matrix.
2. Build the Linux AppImage and sidecar checksum.
3. Create a GitHub release with:
   - AppImage + sha256,
   - source archive,
   - generated changelog section,
   - update-information string compatibility (zsync file hosted in the release).
4. Verify the release notes do not contain tokens and the checksums match.

### 4.3 Branching

- The public development branch is `devel` (default branch on GitHub); v2 work lands there.
- `main` is left behind for now and is reserved for a future release line.
- Prototype code tagged `prototype-final` before the v2 rewrite lands.

## 5. Self-update (v0.2)

AppImage self-update flow:

1. Check own GitHub releases (6-hour TTL, notify-only).
2. Download the new AppImage to the cache, verify SHA-256.
3. Replace on next start, not while running:
   - stage new file as `<current>.new` next to the current AppImage (same filesystem),
   - on next launch, if `<current>.new` exists and verifies, rename current → `.old`, rename
     new → current, and clean `.old` (or support `APPIMAGE_UPDATE` style zsync later).
4. If the AppImage lives in a read-only location, offer "Download to Downloads folder instead"
   and explain how to replace manually.
5. Never update silently; show a banner with version and changelog link first.

Windows/macOS self-update is out of scope until those artifacts exist (OQ-1).

## 6. Diagnostics and supportability

- About screen shows: launcher version, Flutter/Dart versions, OS/arch build, data dir,
  installed builds, log folder.
- "Export debug bundle" produces a zip with redacted logs, DB-free environment summary, and
  diagnostics (FUSE, Gatekeeper, disk). Users attach it to issues.
- Crash handling: top-level zone catches unhandled errors, writes a log entry, and shows a
  non-blocking error dialog with "Copy details".

## 7. Licensing and notices

- Project license: **GPL-3.0-or-later** (`LICENSE`, SPDX headers in source files).
- FreeCAD and the FreeCAD logo are trademarks of the FreeCAD Project Association AISBL. The
  launcher ships no FreeCAD logo and credits the project (with a link to freecad.org) in the
  README/release docs per D-070.
- `THIRD_PARTY_NOTICES.md` generated from `pub deps` licenses for shipped dependencies
  (AppImage contains Flutter engine + GTK libs).
- FreeCAD addons/macros installed by the user keep their own licenses; the addon detail view
  shows the declared license when available.
- If a token or user content is ever included in crash reports, it must be redacted (NFR-5).

## 8. Release checklist

- [ ] `flutter analyze` and all tests green on the matrix
- [ ] CHANGELOG updated; version bumped in both places
- [ ] AppImage built, launches on a clean VM (with and without FUSE)
- [ ] Checksum file published and verified
- [ ] Fresh-install and upgrade-smoke tests (install a build, create profile, launch)
- [ ] No secrets in logs or release assets
