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


### M7 — Linux v0.1 completion

- [x] Linux manual smoke matrix (`§4` Linux column) completed (M7-06, 2026-09-24)
- [x] AppImage builds reproducibly locally (S5/M7-01) and runs on the host with/without FUSE
- [x] `LICENSE` and `THIRD_PARTY_NOTICES.md` present; SPDX headers on sources; the AppImage
      ships both under `/usr/share/doc/freecad-launcher/` (M7-03/D-074, 2026-09-24)
- [x] README + user guide written, links checked, screenshots current (M7-04, 2026-09-24)
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
- [ ] Windows/macOS artifacts built, installed and launched on clean machines (OQ-1)
- [ ] Clean-machine Linux first-run flow completes with the published AppImage (M8-05)

## 3. UI state checklist (per screen)

For every list/detail screen, verify all of: loading, empty, filtered-empty, error,
offline/stale, partial-data (some files missing), and long-content overflow.

For every job: queued, running, cancel requested, cancelled, failed (with retry), completed.

## 4. Manual smoke matrix (v0.1)

Record results in the `STATUS.md` session log (date, OS, FreeCAD version, result, notes).

| Scenario | Linux | Windows | macOS |
|---|---|---|---|
| Install latest stable build | ✅ 2026-09-24 — 1.1.3 AppImage (782.8 MiB), Python 3.11 detected (M7-06) | | |
| Install a weekly build | ✅ 2026-09-30 — real `weekly-2026.09.30` AppImage (767.3 MiB, checksum verified, Python 3.13 probed, headless `--version` = FreeCAD 26.3.0); two profiles created/launched isolated on it (B-01d) | | |
| Create two profiles, verify isolation | ✅ 2026-09-30 — real 1.0.2: distinct markers in `FREECAD_USER_HOME`/`TMPDIR`/`Mod`, inherited `HOME` passed through, no `home/` dir (R-09; M3-10) | | |
| Launch from app | ✅ 2026-09-24 — GUI launch (1.1.3), running badge, log, exit tracking; headless M3-04/M3-05 | | |
| Launch via CLI wrapper | ✅ 2026-09-19 — wrapper ran the built CLI (M3-09) | | |
| Install addon from catalog | ✅ 2026-09-19 — real A2plus install (M4-03); catalog renders live 2026-09-24 | | |
| Install addon requirement via pip | ✅ 2026-09-19 — real `six` install/uninstall (M4-06/M4-07) | | |
| Update an outdated addon | ✅ 2026-09-19 — real A2plus install → update (backup) → remove (M4-04) | | |
| Apply a bundle | ⚠ planner/runner/UI tests only (M5-02); no live apply | | |
| Install + manage a macro | ✅ 2026-09-19 — real catalog install (M5-04/M5-05); Installed list live 2026-09-24 | | |
| Export/import profile manifest | ✅ 2026-09-20 — codec/controller/UI + cross-OS test (M5-07) | | |
| Offline start with cached catalog | ✅ 2026-09-19 — stale/cached states with warning (M4-01/M6-07) | | |

Legend: ✅ verified (date, session) · ⚠ tests only · empty = not done. M7-06 (2026-09-24) findings
filed as R-03..R-07 and fixed the same day (unit/widget tests plus live re-checks); Windows/macOS
columns are deferred to M8.

## 5. When something fails

1. Capture the job log tail and app logs from `logs/`.
2. Do not mark the task `DONE`; set `WIP`/`BLOCKED` with the failure in `STATUS.md`.
3. If the failure reveals a bad assumption, record a new decision (or supersede the old one)
   before changing course.
