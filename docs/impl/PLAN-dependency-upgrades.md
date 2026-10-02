# PLAN — Dependency upgrades (post-M8)

> **Status**: **done** (2026-10-02). All automated checks are green: PR #2 (drift/flutter_svg/xml/
> signals 7.1 + R-23 fix) and PR #3 (B-17 `.watch()` cleanup) merged to `devel`, devel CI green,
> the no-publish release smoke (run 37063249302) built and verified both artifacts, and the
> owner verified a real Linux catalog install + isolated profile launch on the upgraded app.
> Only the owner-dependent Windows-machine smoke remains.

## Goal

Move the dependency set forward — patch/minor first, then selected majors — without regressing
verified behavior on Linux/Windows: catalog installs, profile launch/isolation, drift schema and
migrations, addons/pip/macros, config editing, and both release artifacts (AppImage + portable
zip).

## Baseline (2026-10-01, `v0.4.0`)

- Flutter pinned to **3.41.4** in CI (moved to **3.47.6** on 2026-10-02, D-103); Dart SDK
  constraint `^3.11.0`; `pubspec.lock` committed.
- `flutter pub outdated` snapshot (direct dependencies; *resolvable* = reachable after relaxing
  direct constraints):

| Package | Current | Resolvable | Latest | Notes |
|---|---|---|---|---|
| `archive` | 4.0.9 | 4.3.0 | 4.3.0 | minor, safe extractor / debug bundle / catalogs |
| `drift` | 2.34.4 | 2.34.4 | 2.35.1 | held back; codegen + schema v6 |
| `flutter_svg` | 2.2.3 | 2.3.0 | 2.3.0 | minor, FreeCAD logo SVG |
| `intl` | 0.20.2 | 0.20.2 | 0.20.3 | pinned by `flutter_localizations` |
| `path_provider` | 2.1.5 | 2.1.6 | 2.1.6 | minor |
| `signals_flutter` | 6.3.0 | **7.1.0** | 7.1.0 | **major**; whole state layer |
| `uuid` | 4.5.3 | 4.6.0 | 4.6.0 | minor |
| `xml` | 6.6.1 | **7.0.1** | 7.1.0 | **major**; `user.cfg`/`system.cfg`, `package.xml`, news |
| `build_runner` | 2.11.1 | 2.15.1 | 2.16.1 | dev; codegen output may change |
| `drift_dev` | 2.34.0 | 2.34.0 | 2.35.1 | held back with `drift` |
| `sqlite3` | 3.5.2 | 3.5.2 | 3.7.0 | dev; native-assets toolchain |

Notable transitives: `preact_signals` 1.9.4 → 6.3.1/7.0.0, `hooks` 1.0.1 → 2.x,
`code_assets` 1.0.0 → 2.x, `native_toolchain_c` 0.17.6 → 0.19.x, `objective_c` 9.3.0 → 9.5/9.6.

## Risk assessment

| Area | Why it is risky | What to verify |
|---|---|---|
| `signals_flutter` 6 → 7 (`preact_signals` 1 → 7) | Signal semantics / widget rebuild behavior are load-bearing in 31 files; silent state bugs are possible | Full widget suite + live click-through: Home, Profiles (all tabs), Versions, Addons (+Custom), Macros, Collections, Settings, Jobs dialog |
| `drift`/`drift_dev` + `sqlite3` | Generated DAOs/migrations change; native-assets pipeline affects bundling | `build_runner` diff; migration + CRUD on a **copy of the real DB** (v5→v6 verified path); sqlite loads in AppImage and Windows zip |
| `xml` 6 → 7 | Parses/writes FreeCAD config and addon metadata | `MacroPath` rewrite on a profile launch; `package.xml` install; news feed parse |
| Plugin platform packages (`path_provider`, `url_launcher`, `file_selector`, `flutter_svg`, `archive`) | May raise minimum Flutter/OS requirements | File pickers, open/reveal, zip extract, SVG assets; CI + artifacts on Linux/Windows |
| `--major-versions` itself | Rewrites `pubspec.yaml` constraints wholesale and bundles many majors in one change | Review `pubspec.yaml` + `pubspec.lock` diffs together; keep each group in its own commit so regressions are attributable |

`flutter pub upgrade --major-versions` is therefore **not a blind operation** on this project.
Patch/minor upgrades within the current constraints are much lower risk; majors must be isolated
and verified.

## Phase 1 — patch/minor within current constraints (low risk)

- [x] Branch from `devel`; run `flutter pub upgrade` (no constraint changes) and review the
      `pubspec.lock` diff (expected: `archive` 4.3.0, `flutter_svg` 2.3.0, `path_provider`
      2.1.6, `uuid` 4.6.0, `build_runner` 2.15.1, assorted transitives) — landed as `d7cf10b`
      (drift), `cdbbec2` (flutter_svg/xml) and PR #2 (`2b2cdf7` signals).
- [x] `dart run build_runner build --delete-conflicting-outputs`; review generated changes
      (run repeatedly through the sessions; `lib/**/*.g.dart` diff clean).
- [x] `flutter analyze` + `flutter test`; CI green on Linux **and** Windows (PR #2 run
      37047738009, devel push 37063237308, PR #3 run 37059277836).
- [x] Real smoke: install a build, launch a profile, load addon/macro catalogs, edit a config
      snapshot, export a debug bundle, build the AppImage. Owner-verified 2026-10-02 on Linux:
      a real catalog install with the upgraded app succeeded and an isolated profile launched
      (no issues); catalogs, config tabs and the AppImage build were verified in the sessions;
      a live config-snapshot write and the debug-bundle export remain test-covered only.
- [x] Commit if green; otherwise revert `pubspec.lock`/`pubspec.yaml` (no revert needed).

## Phase 2 — selected majors, one group at a time

Each group is a separate commit with its own verification; revert just the failing group.

- [x] `signals_flutter` 6 → 7 (with `signals_core`/`preact_signals`): adapted via the R-23 fix
      (`fcc90a7`), full widget tests, live UI click-through, PR #2 merged; the `.watch(context)`
      → implicit-tracking cleanup (B-17, D-101) landed in PR #3
      ([plan](PLAN-signals-implicit-migration.md)).
- [x] `xml` 6 → 7: config read/write, `package.xml` and news parse are unit/widget tested
      (`6a2c08f` completes the API adaptation); a real FreeCAD launch re-check stays with the
      Phase 3 catalog-install smoke.
- [x] `drift`/`drift_dev`/`sqlite3` (resolvable with Flutter 3.47.6, D-103): regenerated
      (`d7cf10b`), the real v6 dev database ran through the live passes, and sqlite loads in both
      artifacts (the AppImage GUI ran; the Windows zip ships `sqlite3.dll`/`dartjni.dll`).
- [x] Remaining minors already covered by Phase 1.
- [x] If a group cannot be stabilized, keep the working set and record the blocked bump in
      `TASKS.md` with the reason (nothing blocked).

## Phase 3 — packaging and release verification

- [x] Manual `release.yml` run (no publish): **run 37063249302 green** (appimage 103 s, windows
      221 s, publish skipped). Artifacts downloaded, `sha256sum -c` OK, AppImage `--version` =
      “FreeCAD Launcher 0.4.1” (exit 0), GUI launched and rendered the dashboard, and the
      Windows zip contains the portable bundle + `7zr.exe` + license/notices.
- [x] Real Linux install of a catalog build with the upgraded app (1.1.3 AppImage) —
  **owner-verified 2026-10-02** on a Linux machine: install + isolated profile launch, all
  passed, no issues.
- [ ] If a Windows machine is available: install + launch smoke (full matrix not required for a
      dependency-only change, but the binary must start and load catalogs) — needs the owner's
      machine.
- [ ] Only after Phase 3 may a `0.4.x` release be cut (D-100 line).

## Rollback

- One commit per phase/group; `git revert` the group or restore `pubspec.yaml` + `pubspec.lock`
  and re-run `build_runner` if generated files changed.
- Never mix dependency upgrades with feature work or release commits.

## Resume protocol

1. Read this plan, `STATUS.md` and `TASKS.md` **B-16**.
2. `git status` must be clean; start from the first unchecked item, one phase per session.
3. After each phase: `flutter analyze`, `flutter test`, `graphify update .`, update `STATUS.md`.

## Refs

`TASKS.md` B-16, `docs/impl/DECISIONS.md` (record any decision if a bump changes architecture),
`pubspec.yaml`, `pubspec.lock`, `.github/workflows/ci.yml` (Flutter pin: 3.47.6, D-103).
