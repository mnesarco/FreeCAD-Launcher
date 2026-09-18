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
- [ ] Deleting a build used by a profile is blocked; unused build delete removes files
- [ ] Removing a build directory externally flips status to `missing` on restart

### M3 — Profiles and launch

- [ ] Two profiles on one build: `user.cfg`, `Mod/`, macros, `AdditionalPythonPackages`,
      `temp/` are independent (documented with paths in the session log)
- [ ] `freecad-launcher run "<profile>"` works from a fresh shell after wrapper install
- [ ] "Show launch command" output, when pasted into a shell, reproduces the launch
- [ ] AppImage on a FUSE-less system launches via the extract-and-run fallback
- [ ] macOS `.app` launches from `builds/` with quarantine handled

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
- [ ] Batch update applies only confirmed items and reports per-item results
- [ ] All screens pass the state checklist below
- [ ] Keyboard shortcuts from `../spec/03-ux.md` §4 work
- [ ] Warm startup < 2 s measured on the dev machine (numbers recorded)

### M7 — Release

- [ ] AppImage builds reproducibly in CI and launches on a clean VM with and without FUSE
- [ ] `FreeCADLauncher-<ver>-x86_64.AppImage` + SHA-256 published; checksums verified
- [ ] `LICENSE` and `THIRD_PARTY_NOTICES.md` present; SPDX headers on sources
- [ ] Clean-machine first-run flow completes (install build → profile → addon → launch)
- [ ] No secrets or tokens in logs or artifacts

## 3. UI state checklist (per screen)

For every list/detail screen, verify all of: loading, empty, filtered-empty, error,
offline/stale, partial-data (some files missing), and long-content overflow.

For every job: queued, running, cancel requested, cancelled, failed (with retry), completed.

## 4. Manual smoke matrix (v0.1)

Record results in the `STATUS.md` session log (date, OS, FreeCAD version, result, notes).

| Scenario | Linux | Windows | macOS |
|---|---|---|---|
| Install latest stable build | | | |
| Create two profiles, verify isolation | | | |
| Launch from app | | | |
| Launch via CLI wrapper | | | |
| Install addon from catalog | | | |
| Install addon requirement via pip | | | |
| Update an outdated addon | | | |
| Apply a bundle | | | |
| Install + manage a macro | | | |
| Export/import profile manifest | | | |
| Offline start with cached catalog | | | |

## 5. When something fails

1. Capture the job log tail and app logs from `logs/`.
2. Do not mark the task `DONE`; set `WIP`/`BLOCKED` with the failure in `STATUS.md`.
3. If the failure reveals a bad assumption, record a new decision (or supersede the old one)
   before changing course.
