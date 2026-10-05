# PLAN M8 — Windows release in CI

> **Status**: **Windows release shipped** (2026-10-01): `v0.4.0` is published from CI with the
> portable `.zip` + AppImage after the full clean-machine smoke matrix passed (the earlier
> `v0.1.0`–`v0.3.0` releases were withdrawn; the `0.4.x` line continues). macOS packaging remains
> in M8-04. Written so the work can resume after an interruption; update the checkboxes as items
> land.

## Goal

Publish a Windows launcher artifact from GitHub CI for the `0.4.x` release line:
a portable `FreeCADLauncher-<ver>-windows-x86_64.zip` with a SHA-256 sidecar, next to the
existing Linux AppImage, built and smoke-tested on `windows-latest`, and verified on a clean
Windows machine.

## Confirmed decisions (recorded as D-091/D-092 in `DECISIONS.md`)

| Topic | Choice |
|---|---|
| Windows artifact | Portable `.zip` (OQ-1 option b); no installer, no code signing in v0.2 |
| SmartScreen | Documented warning; release notes/user guide state the binary is unsigned |
| Test gating | M8-06 first: `flutter test` must be green on Windows before a Windows release |
| MacroPath separator | Always `/` in `user.cfg` (FreeCAD/Qt accepts it; verify on the VM) |
| Verification | Clean-machine manual pass (accepted on a second Windows machine, R31) + CI artifact smoke tests |

## Baseline (what exists today)

- `ci.yml` (Linux + Windows): version check, codegen freshness, analyze, release builds.
  `flutter test` is Linux-only (`if: runner.os == 'Linux'`, D-082).
- `appimage-release.yml`: Linux AppImage only; manual inputs `create_release`/`tag`/`prerelease`;
  tag path `v*`. The GitHub Release creation path is still untested.
- `windows/CMakeLists.txt` does **not** install `third_party/7zip/7zr.exe`, but
  `SevenZipExtractor.bundled()` (`lib/platform/seven_zip_extractor.dart:15`) expects it next to
  `freecad_launcher.exe` → every Windows `.7z` install fails without it (D-018 claims the copy).
- `THIRD_PARTY_NOTICES.md` does not list 7-Zip (D-018 requires it).
- `windows/runner/resources/app_icon.ico` is the M1-02 Flutter template icon; R-02/D-070 only
  regenerated AppImage PNGs.
- No `packaging/windows/` script.

## Windows test failures to fix (M8-06) — run 110190364941, 20 failures

| Test | Root cause | Fix |
|---|---|---|
| `platform/debug_bundle_test.dart` (2) | `debug_bundle.dart:60` uses `p.join('logs', …)` → zip entries `logs\app.log` | **Code fix**: POSIX `/` entry names |
| `state/debug_bundle_controller_test.dart` | Diagnostics hardcoded `BuildPlatform.linux` → real `df` call throws on Windows | Use host platform in the test |
| `platform/freecad_preferences_test.dart` (3) | Code appends `Platform.pathSeparator` (`\`), test expects `/` | **Code fix** (D-092): normalize to `/` |
| `domain/launch_command_test.dart` | Hardcoded POSIX paths vs `ProfilePaths` native joins | Build expectations with `p.join`/paths fields |
| `platform/launch_test.dart` | Same (expected argv hardcoded POSIX) | Use `posixPaths` fields |
| `platform/cli_wrapper_test.dart` | Test passes `:`-separated PATH; Windows splits `;` | Platform separator in the test |
| `platform/python_probe_test.dart` (5) | (a) `freecad` dir vs `FreeCAD` file collide on case-insensitive FS; (b) 8.3 temp path vs `resolveSymbolicLinksSync` expanded path | Distinct fixture names; resolve expected paths |
| `state/builds_controller_test.dart` | `/bin/false` does not exist on Windows → early "File not found" | Use a real temp file |
| `state/profiles_controller_test.dart` (4) | Temp dir delete while launch log sink still open (Windows file locking) | Complete `ProfileLaunch.exitCode` after sink close (code), plus focused teardown |
| `ui/profiles_view_test.dart` | Expects `xdg-open` | Per-platform command expectation |

Note: the failure list predates commits `5a372ab`, `a9e3f1c`, `c0a00b9`; expect new Windows
failures until the CI job runs green.

## Implementation phases

### Phase 1 — M8-06 test portability (DONE, CI run 36897077869)

- [x] `debug_bundle.dart` zip entry names use `/` (keep `p.basename` for the file name)
- [x] `freecad_preferences.dart` normalizes the MacroPath value to `/` (D-092)
- [x] `profiles_controller.dart` completes `exitCompleter` after the log sink is flushed/closed
- [x] Portabilize the tests listed above (path expectations via `p.join`, host platform,
      per-platform commands, distinct fixture names, resolved temp paths)
- [x] Re-enable `flutter test` on Windows in `ci.yml` (drop the Linux-only `if`)
- [x] `flutter analyze` clean + full Linux suite green (587 tests, 9 skipped)
- [x] Push and iterate on Windows CI until green (run 36897077869: Windows 576 passed / 14
      skipped, second iteration fixed the last 6 failures)

### Phase 2 — Windows bundle completeness (done, plus VM-driven TLS fix)

- [x] `windows/CMakeLists.txt`: install `third_party/7zip/7zr.exe` + `license.txt` beside the exe
- [x] `tool/generate_third_party_notices.dart`: new "Bundled executables" section lists 7-Zip
      and embeds its license text; `THIRD_PARTY_NOTICES.md` regenerated (153 lines added)
- [x] Generate `windows/runner/resources/app_icon.ico` from
      `packaging/appimage/freecad-launcher.svg` via `packaging/windows/render_icon.sh`
      (7 sizes, 16–256 px, owner's rocket design; checked visually)
- [x] Windows TLS trust (found on the VM: `CERTIFICATE_VERIFY_FAILED`): load the Windows
      `ROOT`/`CA` stores via `crypt32` FFI plus an optional `<data dir>/ca-bundle.pem` into
      `SecurityContext.defaultContext` at startup (D-094), and surface causes in
      `DownloadException`
- [x] `packaging/windows/build_portable.ps1`: verifies the pinned `7zr.exe` SHA-256 (and that
      it is present), assembles the zip (`freecad_launcher.exe` bundle + `LICENSE` +
      `THIRD_PARTY_NOTICES.md` + README) and writes the `.sha256` sidecar (LF, zip is created
      with forward-slash entry names via `ZipFile.CreateFromDirectory`)

### Phase 3 — CI release integration (pipeline verified, publish path pending)

- [x] `appimage-release.yml`: `name: Release`, new `windows` job (build, package, `--version`
      smoke test with a 60 s timeout, artifact upload) and a shared `publish` job
      (`needs: [appimage, windows]`) that downloads both artifact sets and creates/uploads the
      GitHub Release (tag/version validation unchanged; `create_release`/`tag`/`prerelease`
      inputs apply to both)
- [x] Pipeline exercised with a no-publish manual run (36898044793): appimage ✓, windows ✓
      (15.4 MB zip, `sha256sum -c` OK, `7zr.exe` hash pinned, `--version` smoke test),
      `publish` correctly skipped; artifact downloaded and inspected locally
- [x] Publish path exercised end to end: tag push `v0.3.0` (stable, run 36943644212) and the
      manual `workflow_dispatch` `create_release=true` input with `v0.4.0` (`prerelease=true`,
      run 36947395864); both releases carry the AppImage + Windows zip and the sidecars were
      verified

### Phase 4 — Verification and docs

- [x] First clean-machine network pass (2026-10-01, artifact from run 36907901612, D-094):
      extracted zip starts, all catalogs load and downloads complete
- [x] Full Windows smoke matrix pass (2026-10-01, artifact run 36941684639): real FreeCAD 1.1.3
      `.7z` install + Python probe, two isolated profiles + launch, catalog/pip/custom addons,
      enable/disable, macros, manifest, offline catalog, CLI `.cmd` wrapper, reveal — all passed
      (after R-14/D-095, R-15/D-096 and R-17)
- [x] Rebuild the Windows artifact after R-14/D-095 (colon build-id directories were illegal on
      Windows and broke the first install attempt): Release run 36937972986 green, zip downloaded
      and checksum-verified locally
- [x] Rebuild the artifact after R-15/D-096 + R-17 and retest the `.7z` install row: Release run
      36941684639 green, zip downloaded and checksum-verified; the full matrix then passed;
      install failures now write `logs/install-<id>-<stamp>.log` (R-16)
- [x] Record the pass in `VERIFICATION.md` §2 (M8 checklist) and §4 (note)
- [ ] Close OQ-1 in `docs/spec/09-open-questions.md` (Windows published in `v0.4.0`; macOS
      remains for M8-04); spec 07 §2 artifact table updated for `v0.4.0`
- [x] README `Status` updated for the `0.4.x` line (Windows zip + AppImage; unsigned/SmartScreen
      notes already in the user guide)
- [x] Update `STATUS.md`/`TASKS.md` and append the session log (R31)

## Known risks / open items

- `7zr.exe` is x86 (D-018); runs under WoW64 on x64 Windows — verify on the VM.
- CLI mode output from the Windows GUI runner may not attach to the CI console; fall back to
  asserting the exit code if `--version` output is unavailable.
- Dev-link addon installs need symlink privileges (Developer Mode) on Windows (D-087).
- Qt registry state is shared across Windows profiles (documented limitation, D-005).
- `create_release`/tag release path has never run; first Windows release will exercise it.

## M8-07 follow-up (D-116, 2026-10-05)

Implemented: platform metadata alignment (`Runner.rc`/`AppInfo.xcconfig`), Windows data root
pinned to `%APPDATA%\org.freecad.ext.launcher` with a legacy-dir rename + fallback, and the
`check_version_info.ps1` guard wired into `ci.yml`/`release.yml`. Pending: the first Windows CI
run of the guard and a live upgrade retest over a `v0.4.7` data directory (no Windows machine;
the B-16 smoke is also on hold). Details in `TASKS.md` M8-07 and `DECISIONS.md` D-116.

## Resume protocol

1. Read this file, `STATUS.md` (in-progress row) and the M8 tables in `TASKS.md`.
2. `git status` — changes may be uncommitted after an interruption; keep going from the
   unchecked boxes above.
3. Run `flutter analyze` and the tests; continue with the first unchecked phase item.
