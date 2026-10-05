# VERIFICATION

How to prove work is done. Run the relevant section at the end of every session; run the
milestone exit section before declaring a milestone complete.

## 1. Common commands

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after schema/model changes
flutter analyze
flutter test
flutter run -d linux          # or -d windows / -d macos
```

Codegen freshness (CI and locally before commit):

```sh
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code -- 'lib/**/*.g.dart'
```

Rules:

- No test may hit the network. HTTP is injected; fixtures live under `test/fixtures/`.
- Platform-specific tests are tagged `@Tags(['platform'])` and are allowed to spawn processes
  only in local/CI smoke runs, never in the fast unit suite.
- Never verify by "the UI looked fine" when a test can assert the behavior.

## 2. Milestone exit verification

### M1 — Foundation

- [ ] `flutter analyze` and `flutter test` green on Linux, Windows, macOS in CI
- [ ] `git diff --exit-code` after `build_runner` (generated files current)
- [ ] App starts and navigates all six sections on each OS
- [ ] In-memory drift tests cover every DAO
- [ ] Env-builder unit tests cover all three OS matrices

### M2 — Builds

- [ ] Stable build installs from the catalog on each OS and launches by hand
- [ ] Corrupted/mismatched SHA-256 is rejected and leaves no partial files
- [ ] Offline mode shows stale cached catalog with a warning; no crash
- [ ] Custom build import works for a local file (each OS) and a URL
- [ ] Custom executable import references the binary in place, rejects
      missing/non-executable files, and blocks non-executable picks (D-020)
- [ ] Custom executable Python is detected via the headless probe or the manual
      interpreter picker fallback (D-020)
- [ ] AppImage Python is detected without extraction via the headless macro probe (D-022)
- [ ] A local custom AppImage is symlinked into `builds/<id>/` (no duplicate bytes) and removing
      it leaves the original file intact (D-023)
- [ ] Importing a local file without a checksum performs no hashing; when a checksum is given,
      the UI shows the hashing stage/progress, then installing and detecting Python (D-024)
- [ ] Deleting a build used by a profile is blocked; unused build delete removes files
- [ ] Removing a build directory externally flips status to `missing` on restart
- [ ] Relabeling an installed build stores a trimmed label shown on every build surface
      (Installed tile, profile cards/detail, manifest picker, CLI `list`); clearing the field
      restores the version label (D-069)

Manual real-data test (Linux, network required, skipped by default):

```sh
FCL_REAL_INSTALL=1 flutter test test/manual/real_install_linux_test.dart
FCL_REAL_PROBE=1 flutter test test/manual/real_python_probe_test.dart
# override the probed binary: FCL_PROBE_BINARY=/path/to/FreeCAD
```

Windows equivalent (once a Windows machine/CI is available): run `7zr.exe` from
`third_party/7zip/` against the real FreeCAD `.7z`; macOS: verify `hdiutil` attach/copy/detach
and quarantine handling.

### M3 — Profiles and launch

- [ ] Two profiles on one build: `user.cfg`, `Mod/`, macros, `AdditionalPythonPackages`,
      `temp/` are independent (documented with paths in the session log)
- [ ] `freecad-launcher run "<profile>"` works from a fresh shell after wrapper install
- [ ] "Show launch command" output, when pasted into a shell, reproduces the launch
- [ ] AppImage on a FUSE-less system launches via the extract-and-run fallback
- [ ] macOS `.app` launches from `builds/` with quarantine handled

Manual real-data checks (Linux, skipped by default):

```sh
FCL_REAL_LAUNCH=1 flutter test test/manual/real_launch_linux_test.dart
FCL_REAL_WRAPPER=1 flutter test test/manual/cli_wrapper_linux_test.dart
FCL_REAL_ISOLATION=1 flutter test test/manual/isolation_e2e_linux_test.dart
# override the binary with FCL_LAUNCH_BINARY / FCL_WRAPPER_TARGET
```
- [ ] Create/duplicate failures leave no partial `profiles/<id>.part` directories or DB rows
      (D-028)
- [ ] Duplicate asks config-only vs full payload and copies the chosen contents

### M4 — Addons and Python

- [ ] Real workbench installs into `Mod/`, appears in FreeCAD's AddonManager, and only in
      that profile
- [ ] Addon with `requirements.txt`: consent flow shown; imported module resolves in FreeCAD
- [ ] Addon update creates a backup and leaves a working install
- [ ] Addon remove deletes only that profile's copy
- [ ] Concurrent downloads work; cancel leaves no `.part` files
- [ ] Module installed in profile A is not importable in profile B

### M5 — Collections, macros, config, export

- [ ] Bundle export → import on another machine/OS installs the same addon set
- [ ] Bundle apply preview matches executed actions
- [ ] Macro installed via catalog appears in FreeCAD's Macro menu only in its profile
- [ ] Config backup/restore round-trips `user.cfg`
- [ ] Manifest export/import recreates a profile; absolute-path issues are reported

### M6 — Updates and polish

- [ ] Addon and build update badges appear only when newer content exists
- [ ] Pinned addons never badge or update in that profile; other profiles still see their own
      updates; bundle apply reports them as skipped; the v3 → v4 migration opens an old DB
- [ ] Manifest export/import round-trips pinned addons
- [ ] Batch update applies only confirmed items and reports per-item results
- [x] All screens pass the state checklist below (see the M6-07 matrix)
- [x] Keyboard shortcuts from `../spec/03-ux.md` §4 work
- [x] Warm startup < 2 s measured on the dev machine (numbers recorded)

M6-09 timings (release build, warm data root, 3 runs): wall to first frame 553/559/561 ms;
in-process bootstrap 14–23 ms, first frame 142–186 ms; addon/macro catalog parses moved off the
UI isolate (176 addons, 262 macros).

### M6-07 state coverage pass (2026-09-20)

Legend: **live** = seen in the running app, **test** = widget/unit test, **code** = handled but
not exercised automatically, **n/a** = not applicable. Overflow means long text/rows do not
overflow (ellipsis/wrap or a regression test). "Offline/stale" means cached catalogs with a
stale banner; local DB screens are n/a.

| Screen | Loading | Empty | Filtered-empty | Error | Offline/stale | Partial data | Overflow |
|---|---|---|---|---|---|---|---|
| Home | n/a | live | n/a | n/a | n/a | n/a | live |
| Profiles list | code | test | n/a | test | n/a | code (missing/broken chips) | test |
| Profile → Overview | n/a | code | n/a | code | n/a | code | live |
| Profile → Addons | n/a | test | n/a | code (pin/remove snackbars) | n/a | test (icons fall back when the catalog is not cached) | test |
| Profile → Python | n/a | test | n/a | code (inline install errors) | n/a | code | test |
| Profile → Macros | n/a | code | n/a | code | n/a | live (reconcile drops missing files) | test |
| Profile → Config | n/a | code ("created on first launch") | n/a | code | n/a | live | live |
| Profile → Backups | code | code (no snapshots) | n/a | test (manifest import) | n/a | code | test |
| Versions → Installed | n/a | live | n/a | code (verify/remove snackbars; rename label validation) | n/a | code (missing/broken badges) | test (tile overflow, rename/reset) |
| Versions → Available | code (install progress) | code | n/a | code (catalog error state) | code (stale banner) | live (installed badge) | live |
| Versions → Custom | code (import stages) | n/a | n/a | code (validation + Python fallback dialog) | n/a | n/a | live |
| Addons → Catalog | code | live | live | code (catalog load failed state) | code (stale banner) | live (installed/update badges) | live |
| Addons → Collections | test | test | n/a | test | n/a | test (not-in-catalog items) | live |
| Addons → addon picker | code | n/a | code | test (catalog unavailable) | n/a | n/a | code |
| Macros → Installed | n/a | test | n/a | code | n/a | live | test |
| Macros → Catalog | code | live | code | code | code (stale banner) | live (installed-in-N chip) | live |
| Settings | n/a | n/a | n/a | live (wrapper/cache/bundle snackbars) + test (open-folder failure) | n/a | live (cache sizes 0 B when empty) | live |
| Jobs dialog | n/a | code (no jobs) | n/a | test (failed + retry) | n/a | n/a | live |
| Updates sheet | code | code (all up to date) | n/a | test (apply failures) | code (no catalog) | n/a | live |

Known gaps (not v0.1 blockers): spec 03 §2.1's "Guided setup" wizard and recent-jobs list on
Home are deferred (the dashboard, first-run checklist, stats, last-used launch, update check and
news feed landed in M6-12/D-067); the diagnostics `gatekeeper` result is `notApplicable` outside
macOS. The addon picker previously showed "No matching addons" even when the catalog was
unavailable; fixed in M6-07 with a widget test.

Fix (2026-09-21): open-folder/reveal buttons spawned `xdg-open` without the parent environment
and swallowed failures, so they did nothing on Linux. `FileActions` now inherits the environment
and throws `FileActionException` on non-zero exits; Settings and the profile Config tab show a
failure snackbar. Covered by `test/platform/file_actions_test.dart` (env inheritance, reveal
target, exception).

R-13 (2026-10-01, D-090): the profile Overview `Log` row is a clickable link that opens the
launch log with the OS default application (`FileActions.open`); failures show a snackbar.
Covered by `test/ui/profiles_view_test.dart` (asserts `xdg-open <log path>`).

### R-25 visual refresh (2026-10-03)

- [x] `flutter analyze` clean; `flutter test` 634 green (9 platform probes skipped); the suite
      includes `test/ui/app_theme_test.dart` (brand seed, `AppStatusColors`, card/button shape
      policy), `test/ui/compact_badge_test.dart` (six tones and the empty-state bubble) and the
      updated Home hero tests
- [x] `test/ui/a11y_test.dart` passes the labeled-tap-target, Android tap-target and text-contrast
      guidelines with the new theme (the dark hero gradient end was lightened so the quick
      actions keep ≥ 4.5:1 contrast)
- [x] Live Linux pass (2026-10-03, dev machine, 1280×720): app launched from the branch, all six
      sections rendered in dark and light with no overflow and zero runtime errors; the theme was
      switched to Light in Settings and survived a hot restart (persisted `theme_mode`)
- [x] README screenshots (`docs/images/*.jpg`) recaptured from the refreshed light theme

R-27 (2026-10-03, branch `profile-catalog-pickers`): profile-context catalog pickers for addons
and macros (D-107). `test/ui/profile_addons_picker_test.dart` (4 tests) and
`test/ui/profile_macros_picker_test.dart` (2 tests) cover the header/empty entry points,
text/`#tag` filtering, the installed badge/disabled rows, the requirements-consent gate (cancel
aborts) and the install call arguments; the install side effects stay covered by the controller
tests. `collections_view_test` and `addons_view_test` prove the shared-picker refactor is
behavior preserving. Live pass: the dialogs were opened from the real Addons and Macros tabs,
searched, and the installed/disabled rows verified without installing into the owner's profiles.

R-28 (2026-10-03, same branch): Profile ▸ Addons removal reuses the shared
`removeAddonFromProfile` dialog (also used by the catalog detail); the widget test in
`profile_addons_picker_test` covers cancel (no call) and confirm (remove called with the profile
id + `Addon removed` snackbar). The profile tab now matches the Macros/Python rows (card layout,
trash action, 8 px header separation) — R-27e.

R-26 (2026-10-03, same branch): addon/macro catalog bitmaps now render through the shared
`RasterIcon` at native resolution with `FilterQuality.high` and anti-aliasing (the pre-downscale
`cacheWidth` in `MacroIcon` is gone), while SVG detection is shared and BOM-safe; XPM/missing
icons still fall back per D-076. `test/ui/raster_icon_test.dart` covers the SVG detection, the
filter flags and the addon SVG/bitmap dispatch; a live GDK_SCALE=2 pass (DPR ≈ 1.6) on Macros
and the Addons catalog showed smooth upscaling and crisp vector icons.


### M7 — Linux v0.1 completion

- [x] Linux manual smoke matrix (`§4` Linux column) completed (M7-06, 2026-09-24)
- [x] AppImage builds reproducibly locally (S5/M7-01) and runs on the host with/without FUSE
- [x] `LICENSE` and `THIRD_PARTY_NOTICES.md` present; SPDX headers on sources; the AppImage
      ships both under `/usr/share/doc/freecad-launcher/` (M7-03/D-074, 2026-09-24)
- [x] README + user guide written, links checked, screenshots current (M7-04, 2026-09-24;
      screenshots recaptured from the current build 2026-10-01, R20)
- [x] No secrets or tokens in logs or artifacts — debug-bundle review (M6-06), notices/scripts
      scanned, v0.1 has no token support (OQ-3 deferred)

S5 (D-068) pre-checks: two consecutive local builds produced identical AppImage/zsync hashes
(`a83b1ffb…` / `9da830f1…`); host runs pass with FUSE and extract-and-run; clean ubuntu:24.04
and fedora:41 containers print the version and exit 0.

M7-01 (D-071) productionization checks (2026-09-21):

- [x] `packaging/check_version.sh` passes; a mismatched tag (`v0.2.0` vs `0.1.0`) fails; CI pins
      Flutter 3.41.4 and runs the check.
- [x] `build_appimage.sh` aborts on placeholder `APPIMAGE_OWNER`/`APPIMAGE_REPO` unless
      `ALLOW_PLACEHOLDER_UPDATE_INFO=1`.
- [x] Full hicolor icon tree (16–512 px) staged plus `.DirIcon`; `desktop-file-validate` OK.
- [x] Local build `721cdb2b…` (29,903,352 bytes): `sha256` sidecar verifies, host FUSE and
      extract-and-run `--version` exit 0, and three consecutive packaging runs produce identical
      AppImage/zsync hashes (`a5c38072…`).
- [x] Clean `ubuntu:24.04` and `fedora:41` (Xvfb + Mesa, the S5 desktop-baseline proxy): CLI
      `--version` exit 0, GUI window opens (first frame 53–104 ms), no gdk-pixbuf/GTK asset
      errors.
- Note: the GTK runner initializes before Dart `main`, so even `--version` needs a `DISPLAY`;
  the release smoke test runs under `xvfb-run`. Truly minimal headless containers cannot run the
  AppImage because `libX11` is treated as desktop baseline by the AppImage excludelist.
- Clean VMs remain open for M7-05.

### M8 — Packaging, CI & cross-platform release (deferred, D-072)

- [x] Manual GitHub run of `appimage-release.yml` (2026-10-01, run 36810294004): AppImage built,
      sidecar verified and smoke-tested on CI (`--version` under Xvfb); artifact downloaded and
      re-verified locally (29.9 MB, `sha256sum -c` OK, `FreeCAD Launcher 0.1.0`)
- [x] GitHub Release published with `FreeCADLauncher-<ver>-x86_64.AppImage` + SHA-256 + zsync
      (`v0.1.0` pre-release, 2026-10-01, created by the manual `appimage-release.yml` run
      36812429637; assets match the CI-built artifact)
- [x] Release workflow: matrix tests, changelog, release creation; release notes contain no
      tokens (generated by the workflow; checksums verified on CI and locally)
- [x] First CI matrix run green on GitHub (ubuntu + windows; macOS removed per D-083, tests
      Linux-only per D-082)
- [x] `flutter test` green on Windows and Linux in CI after the M8-06 portability fixes
      (run 36897077869, 2026-10-01; Windows 576 passed / 14 skipped)
- [x] Windows portable zip built by the release workflow (manual run 36898044793, 2026-10-01):
      `FreeCADLauncher-0.2.0-windows-x86_64.zip` (15.4 MB), `sha256sum -c` OK, POSIX zip entry
      names, `7zr.exe` present and hash-identical to D-018 (`ad4c82fa…`), license/notices/README
      bundled, `freecad_launcher.exe --version` smoke-tested on CI
- [x] Windows artifact extracted and launched on a clean Windows machine (2026-10-01, D-094):
      startup, every catalog load and downloads verified with the run 36907901612 artifact; after
      R-14/D-095, R-15/D-096 and R-17 the owner ran the full §4 smoke matrix with the run
      36941684639 artifact and all scenarios passed. The TLS-inspection VM was not re-checked
      (AV/TLS caveat documented in the user guide)
- [x] GitHub Release creation path exercised for tagged/manual publishes (both OS artifacts): the
      tag path with `v0.3.0` (run 36943644212) and the manual `workflow_dispatch`
      `create_release=true` input path with `v0.4.0` (run 36947395864)
- [x] Cross-platform release `v0.3.0` (tag push `v0.3.0` → `release.yml`, run 36943644212): the
      `publish` job created the release with `FreeCADLauncher-0.3.0-windows-x86_64.zip` +
      `.sha256` and `FreeCADLauncher-0.3.0-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars
      verified locally after download from the release page (release later withdrawn by the owner,
      D-100)
- [x] Pre-release `v0.4.0` (manual `create_release=true`, tag `v0.4.0`, `prerelease=true`, run
      36947395864): `FreeCADLauncher-0.4.0-windows-x86_64.zip` + `.sha256` and
      `FreeCADLauncher-0.4.0-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified from
      the release page; tag points at `b8e17f7` (Linux regression fixes R-18..R-20)
- [x] Pre-release `v0.4.1` (manual `create_release=true`, tag `v0.4.1`, `prerelease=true`, run
      36955018205): `FreeCADLauncher-0.4.1-windows-x86_64.zip` + `.sha256` and
      `FreeCADLauncher-0.4.1-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified from
      the release page; tag points at `0c61e25` (Python install-dialog fix R-22)
- [x] Pre-release `v0.4.2` (manual `create_release=true`, tag `v0.4.2`, `prerelease=true`, run
      37080913815): `FreeCADLauncher-0.4.2-windows-x86_64.zip` + `.sha256` and
      `FreeCADLauncher-0.4.2-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified from
      the release page, AppImage `--version` = 0.4.2 (exit 0) and the zip contains
      `7zr.exe`/license/notices; carries the Home “Recent profiles” work and cache guards
      (B-18, R-24, D-104/D-105)
- [x] Pre-release `v0.4.3` (manual `create_release=true`, tag `v0.4.3`, `prerelease=true`, run
      37148725010): `FreeCADLauncher-0.4.3-windows-x86_64.zip` + `.sha256` and
      `FreeCADLauncher-0.4.3-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after
      download, AppImage `--version` = 0.4.3 (exit 0) and the zip contains
      `7zr.exe`/license/notices; carries the R-25/R-26 visual refresh (D-106), squash-merged into
      `devel` (`1dc65b6`, bump `b9bdbed`)
- [x] Pre-release `v0.4.4` (manual `create_release=true`, tag `v0.4.4`, `prerelease=true`, run
      37162641299): `FreeCADLauncher-0.4.4-windows-x86_64.zip` + `.sha256` and
      `FreeCADLauncher-0.4.4-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after
      download, AppImage `--version` = 0.4.4 (exit 0) and the zip contains
      `7zr.exe`/license/notices; carries the profile-context catalog pickers (R-27/D-107), tab
      consistency (R-27e), addon remove (R-28) and the icon box-fit (R-26), fast-forward-merged
      into `devel` (`95bc3b7`, bump `f3ca5d4`)
- [x] Pre-release `v0.4.5` (manual `create_release=true`, tag `v0.4.5`, `prerelease=true`, run
      37263850706): `FreeCADLauncher-0.4.5-windows-x86_64.zip` + `.sha256` and
      `FreeCADLauncher-0.4.5-x86_64.AppImage` + `.sha256` + `.zsync`; appimage/windows/publish all
      green, both sidecars verified after download (`sha256sum -c` OK), AppImage `--version` =
      0.4.5 (exit 0) and the zip contains `7zr.exe`/`LICENSE`/`README.md`/notices; carries B-19
      (`<depend>` dependencies), B-20 (AppImage macro Python execution), R-29 (create profile →
      detail), R-30/D-113 (symlinks skipped with warnings) and the Windows env hardening
- [ ] macOS artifacts built, installed and launched on clean machines (M8-04, OQ-1)
- [ ] Clean-machine Linux first-run flow completes with the published AppImage (M8-05)
- Note (D-100): `v0.1.0`–`v0.3.0` releases were withdrawn by the owner; `v0.4.5` is the current
  release (pre-release) and the `0.4.x` line continues. The entries above document the
  historical verification; the tags still exist.

## 3. UI state checklist (per screen)

For every list/detail screen, verify all of: loading, empty, filtered-empty, error,
offline/stale, partial-data (some files missing), and long-content overflow.

For every job: queued, running, cancel requested, cancelled, failed (with retry), completed.

## 4. Manual smoke matrix (v0.1)

Record results in the `STATUS.md` session log (date, OS, FreeCAD version, result, notes).

| Scenario | Linux | Windows | macOS |
|---|---|---|---|
| Install latest stable build | ✅ 2026-09-24 — 1.1.3 AppImage (782.8 MiB), Python 3.11 detected (M7-06); post-upgrade re-run 2026-10-02 — real catalog install with the upgraded app (B-16, owner-verified, no issues) | ✅ 2026-10-01 — 1.1.3 `.7z` extracted with the bundled `7zr.exe`, Python probed (owner matrix pass, artifact run 36941684639) | |
| Install a weekly build | ✅ 2026-09-30 — real `weekly-2026.09.30` AppImage (767.3 MiB, checksum verified, Python 3.13 probed, headless `--version` = FreeCAD 26.3.0); two profiles created/launched isolated on it (B-01d) | | |
| Create two profiles, verify isolation | ✅ 2026-09-30 — real 1.0.2: distinct markers in `FREECAD_USER_HOME`/`TMPDIR`/`Mod`, inherited `HOME` passed through, no `home/` dir (R-09; M3-10) | ✅ 2026-10-01 (same pass) | |
| Launch from app | ✅ 2026-09-24 — GUI launch (1.1.3), running badge, log, exit tracking; headless M3-04/M3-05; post-upgrade profile launch smoke 2026-10-02 (B-16, owner-verified) | ✅ 2026-10-01 (same pass) | |
| Launch via CLI wrapper | ✅ 2026-09-19 — wrapper ran the built CLI (M3-09) | ✅ 2026-10-01 (same pass) | |
| Install addon from catalog | ✅ 2026-09-19 — real A2plus install (M4-03); catalog renders live 2026-09-24 | ✅ 2026-10-01 (same pass) | |
| Install addon requirement via pip | ✅ 2026-09-19 — real `six` install/uninstall (M4-06/M4-07) | ✅ 2026-10-01 (same pass) | |
| Install addon `<depend>` dependencies | ✅ 2026-10-04 — real Ondsel-Lens from the catalog: `<depend>` parsed (pyjwt/requests/tzlocal), probe skipped system-available `requests`/PyJWT, pip installed `tzlocal` into the profile, `python_packages` rows recorded with `source=addon:Ondsel-Lens`, `import tzlocal` verified (B-19, `real_addon_dependencies_test`); real catalog parse check: 67 addons with `<depend>`, Beltrami → Curves + numpy/scipy + part/sketcher/spreadsheet (`real_addon_catalog_test`) | | |
| Install dependent addons / optional checkboxes | ⚠ controller + widget tests (dependent addon ordering, optional addon/Python selection, failure leniency, removal warning); no live multi-addon install | | |
| Update an outdated addon | ✅ 2026-09-19 — real A2plus install → update (backup) → remove (M4-04) | | |
| Install addon from repository URL + ref | ✅ 2026-10-01 — real `https://github.com/obelisk79/FreeCAD-Nxt` @ `main` installed via Addons → Custom (`Mod/FreeCAD-Nxt`, package.xml 0.3.1, DB `source=repo`, stored URL); removed afterwards (B-10b) | ✅ 2026-10-01 (same pass) | |
| Install addon from a local archive | ✅ 2026-10-01 — real `nxt.zip` installed (`Mod/nxt`, DB `source=zip` + `sourcePath`); removed afterwards (B-10c) | ✅ 2026-10-01 (same pass) | |
| Dev-link a local addon folder | ✅ 2026-10-01 — working copy symlinked as `Mod/FreeCAD-Nxt`, live edit visible through the link, remove deleted only the link (source intact) (B-10d) | ✅ 2026-10-01 (same pass; Developer Mode) | |
| Install a custom addon into another profile | ✅ 2026-10-01 — copied the `FreeCAD-Nxt` dev link from Development into Production 1 via the Custom tab action (profile picker hides profiles that already have it); copy removed, original and source intact (B-10f) | | |
| Enable/disable an installed addon | ✅ 2026-10-01 — real toggles on Development: File Explorer (managed) and Nxt (dev link) wrote/removed `ADDON_DISABLED` (managed marker under the profile `Mod/`, dev-link marker in the working copy); UI shows the Disabled badge and dimmed row (B-15a) | ✅ 2026-10-01 (same pass) | |
| Apply a bundle | ⚠ planner/runner/UI tests only (M5-02); no live apply | | |
| Install + manage a macro | ✅ 2026-09-19 — real catalog install (M5-04/M5-05); Installed list live 2026-09-24 | ✅ 2026-10-01 (same pass) | |
| Export/import profile manifest | ✅ 2026-09-20 — codec/controller/UI + cross-OS test (M5-07) | ✅ 2026-10-01 (same pass) | |
| Offline start with cached catalog | ✅ 2026-09-19 — stale/cached states with warning (M4-01/M6-07) | ✅ 2026-10-01 (same pass) | |

Legend: ✅ verified (date, session) · ⚠ tests only · empty = not done. M7-06 (2026-09-24) findings
filed as R-03..R-07 and fixed the same day (unit/widget tests plus live re-checks); Windows/macOS
columns are deferred to M8.

Note (Windows, 2026-10-01, M8-03/D-094): on a clean Windows machine (different from the
TLS-inspection VM) the artifact from run 36907901612 started, loaded all catalogs and completed
downloads. The first full-matrix attempts exposed three blockers, all fixed and covered by tests:
R-14/D-095 (`FileSystemException` — colon build IDs used as directory names), R-15/D-096
(7zr `CreateProcessW` ERROR_INVALID_PARAMETER from an empty environment block) and R-17
(`PathNotFoundException` in the recursive size walk over a >260-char FreeCAD path). The owner
then ran the full smoke matrix with the artifact from run 36941684639 and **all scenarios
passed**. Windows rows not covered by that pass: weekly build install, addon update (needs an
outdated addon), custom-addon copy into another profile, and bundle apply (tests-only on every
OS). Known Windows caveats stay documented: unsigned zip/SmartScreen, dev links need Developer
Mode, Qt registry state is shared across profiles.

### B-19 (2026-10-04, branch `b19-addon-dependencies`)

FreeCAD `package.xml` `<depend>` support: parser + pure resolver (D-108), batched
`PythonPackageProbe` with stdlib fallback (D-110), unified install pipeline with dependency
ordering/provenance/leniency (D-111) and one consent dialog (D-109). Evidence:

- Unit/domain: `addon_dependencies_test` (14 cases: types, optional casing, internal
  normalization, automatic fallback, installed-addon recursion, cycles, ordering, dedupe,
  availability filter, merge), catalog parser wiring, stdlib list sanity.
- Platform: `python_package_probe_test` (parsing, PYTHONPATH, failure→null, no launch without
  candidates).
- Controller: `addons_controller_test` dependency group (dependent addon + pip ordering, probe
  skip, lenient dependent failure, cancel discard, `dependentsOf`, custom staged `<depend>`);
  `bundle_apply_controller_test`, `profile_manifest_controller_test` updated to selections.
- Widget: `addon_dependencies_dialog_test` (sections, optional checkboxes, addon-only/cancel,
  invalid/unresolved), `profile_addons_picker_test` (consent gating, “Required by” removal
  warning).
- Manual (gated): `real_addon_dependencies_test` (`FCL_REAL_DEPS=1`) — real Ondsel-Lens install
  from GitHub with probe skip + pip + import check, 3 s; `real_addon_catalog_test`
  (`FCL_REAL_CATALOG=1`) — real catalog dependency resolution (Ondsel-Lens, Beltrami).
- **Live desktop pass (2026-10-04, isolated `XDG_DATA_HOME`)**: real UI, profile `Tes2` on the
  stable 1.1.3 AppImage with no extracted tree — Profile ▸ Addons → Add addon → Ondsel-Lens →
  Install showed the dependency dialog in ~1 s (pyjwt/requests/tzlocal, no extraction); “Install
  dependencies” ran the AppImage extraction with `Preparing Python (N files)` job progress, the
  full probe filtered bundled `requests`, pip installed pyjwt+tzlocal (`source=addon:Ondsel-Lens`)
  and the addon appeared in the profile. This pass caught and verified the fix for the original
  owner report (silent extraction before consent, B19-2).
- Not yet live-checked: optional checkbox installs, dependent-addon load inside FreeCAD,
  bundle/batch optional selection.

### B-20 (2026-10-04, branch `b19-addon-dependencies`)

AppImage Python execution via headless macros (D-112), removing the persistent
`builds/<id>/extracted/` tree on FUSE systems. Evidence:

- Platform: `freecad_macro_runner_test` (headless args, isolated env, tagged payload, cleanup,
  FUSE fallback retry), `pip_runner_test` (in-image pip macro, log + result, failure, exactly-one
  target), `python_package_probe_test` (in-image availability, no payload → null),
  `python_execution_test` (FUSE/interpreter/legacy selection).
- Controller: `addons_controller_test` and `python_controller_test` assert the AppImage path is
  passed to pip (no interpreter resolution/extraction) when FUSE is available and the legacy
  interpreter path otherwise.
- Manual prototype on the real 1.1.3 AppImage: in-process pip installed `tzlocal` to `--target`;
  availability macro (`requests`, `math`) ran in **0.96 s**.
- **Live desktop pass** on an isolated `XDG_DATA_HOME` with a symlinked AppImage and no
  `extracted/`: catalog Ondsel-Lens install (dialog instant; macro pip installed pyjwt+tzlocal,
  bundled `requests` filtered; row `source=addon:Ondsel-Lens`, `has_requirements=1`) and Python
  tab `six` install (macro pip). The data root stayed at **7.5 MB** (no extraction; only
  `cache/pip` + logs) and no FreeCAD mount processes remained.
- Not verified live: FUSE-less fallback (unit-tested only).

### R-30 (2026-10-04, `devel`)

Archive symlink policy (D-113): the extractor skips symlink entries instead of failing, reports
them, and the addon install surfaces a “Some files were skipped” dialog. Evidence: unit tests
(extractor skip + report + rest extracted, installer propagation, controller `installWarnings`),
warnings-dialog widget test, and the real `HistoryWorkbench-release.zip` (495 entries) extracting
with the 3 expected skips and `package.xml` + workbench resources present.

### R-31 (2026-10-05, `devel`)

Windows portable zip self-containment (D-114): the zip bundles the Microsoft Visual C++ runtime
app-local so a clean machine without the system-wide redistributable can start
`freecad_launcher.exe`. Evidence:

- `packaging/windows/build_portable.ps1` resolves the VS x64 CRT redist folder via `vswhere`
  (`$env:VCToolsRedistDir` fallback), copies every `*.dll` from it next to `freecad_launcher.exe`,
  requires `vcruntime140.dll`/`vcruntime140_1.dll`/`msvcp140.dll` in the staged bundle and in the
  written zip, and fails the build otherwise (CI exercises the full path).
- `THIRD_PARTY_NOTICES.md` gained the “Microsoft Visual C++ runtime” section via
  `tool/generate_third_party_notices.dart` (regenerated, deterministic); the CI drift check runs
  on the committed file.
- `flutter analyze` clean; 698 tests green (10 platform probes skipped).
- Release workflow no-publish run **37323499192** (`devel` `0793158`): appimage/windows green, publish
  skipped; the downloaded `FreeCADLauncher-0.4.6-windows-x86_64.zip` sidecar verifies and the zip
  carries the full app-local runtime set (`concrt140`, `msvcp140`/`_1`/`_2`/`_atomic_wait`/
  `_codecvt_ids`, `vccorlib140`, `vcruntime140`/`_1`/`_threads`).
- `v0.4.6` publish run **37324089592** (manual `create_release=true`, tag `v0.4.6`,
  `prerelease=true`): all jobs green; both assets re-verified after download from the release page
  (`sha256sum -c` OK), AppImage `--version` = 0.4.6 (exit 0), release zip contains the runtime DLLs.
- Residual: no Windows machine without the redistributable was available for a live no-redist
  start; the app-local load path is Microsoft-documented and the DLLs are inside the zip.

## 5. When something fails

1. Capture the job log tail and app logs from `logs/`.
2. Do not mark the task `DONE`; set `WIP`/`BLOCKED` with the failure in `STATUS.md`.
3. If the failure reveals a bad assumption, record a new decision (or supersede the old one)
   before changing course.
