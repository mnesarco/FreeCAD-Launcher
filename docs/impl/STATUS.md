# STATUS

> Live file. Every session updates this at start and end. Keep it short — details belong in
> `TASKS.md` and `DECISIONS.md`.

- **Updated**: 2026-10-08
- **Current milestone**: **M8 — Packaging, CI & cross-platform release: in progress**
  (M8-01/M8-02/**M8-03 DONE**/**M8-06 DONE**/**M8-07 DONE**/**M8-08 WIP**; **`v0.4.11` is the
  current release** (pre-release, 2026-10-08) with R-36/D-119 (installable release candidates via
  the `rc` channel); `v0.4.9` carried the platform metadata alignment (M8-07/D-116)
  and the data-root regression fix (M8-08/D-117; owner Windows retest pending); `v0.4.7` carried
  the self-contained Windows zip (R-31/D-114) and the R-32/D-115 addon-dependency pip fix; it also carries the B-19 `package.xml`
  `<depend>` dependency install (D-108..D-111), the B-20 AppImage macro Python execution without
  extraction (D-112), R-29 (create profile → detail) and R-30/D-113 (archive symlinks skipped
  with warnings) on top of the R-25..R-28 work shipped in `v0.4.2`–`v0.4.4`; releases before
  0.4.0 were withdrawn by the owner (D-100) and the `0.4.x` line continues; M8-04 needs macOS;
  M8-05 clean-VM Linux pass ready)
- **Active branch**: `devel` (public, pushed to `origin/devel`) — `main` is reserved for a future
  release line
- **Last session**: 2026-10-08
- **Plan**: `docs/impl/PLAN-M8-windows-release.md` — the session saves progress there and in
  `TASKS.md` so work can resume after an interruption.
- **Decisions this session**: **D-119** (release candidates get their own `rc` channel:
  `FreeCadVersion.rc`/`isPrerelease` with `26.3rc1 < 26.3rc2 < 26.3`, `BuildChannel.rc`,
  Available RC filter + badge + install warning, excluded from stable update checks and the
  catalog-derived stable line, no schema migration) — R-36; **D-118** (interpreter pip runs through a generated bootstrap that
  registers the interpreter's `bin`/`DLLs` via `os.add_dll_directory` on Windows, logs the
  interpreter and the `ssl` traceback, then runs pip via `runpy`; dependency errors are keyed per
  profile+addon and surfaced in the UI) — R-34; **D-117** (the Windows data root is never renamed;
  the legacy root stays in use when present and stale legacy-prefixed stored paths are repaired
  into the active root only when the mapped target exists) — M8-08; **D-116** (platform metadata
  aligned with the D-074 holder; Windows data root pinned to
  `%APPDATA%\org.freecad.ext.launcher`; its rename migration superseded by D-117) — M8-07; D-115
  (the asset-name `pyXY` hint is version metadata only, never an interpreter path; legacy stored
  FreeCAD paths are ignored and FreeCAD is only ever called with `-c`) — R-32.
- **Next action**: **R-36** (release candidate `26.3rc1` was not installable because the stable
  tag regex rejected the `rcN` suffix) is implemented, test-verified and shipped in **`v0.4.11`**
  — **D-119** adds the `rc` channel (`26.3rc1 < 26.3rc2 < 26.3`), the Available **RC** filter with
  badge + install warning, and excludes RCs from stable update checks and the stable line; analyze
  clean, 726 tests green (10 skipped), both release sidecars verified; the live catalog
  install/launch on the real `26.3rc1` build is still pending. Then **R-34** (weekly Windows addon `<depend>` install failed because the bundle's
  stale `ssl.py` imports `_ssl.RAND_pseudo_bytes`, removed in Python 3.13 — stable 3.11 still has
  it) is implemented, test-verified and shipped in **`v0.4.10`** (bootstrap aliases the symbol +
  per-profile error surfacing, D-118): waiting on the owner's Windows weekly retest with the
  published `v0.4.10` (the pip log must show `patched _ssl.RAND_pseudo_bytes …` +
  `freecad-launcher: ssl …` and the packages must install). Then **M8-08**
  (data-root regression fix, D-117) is implemented and shipped in the
  **`v0.4.9`** pre-release (run 37371511156; Windows job needed one rerun after a GitHub
  hosted-runner outage). Waiting on the owner's Windows retest: the install moved by 0.4.8 must
  show Installed builds again, and a legacy-only install must keep its directory untouched. Then
  **R-32** (Windows “unrecognised option '-m'”
  when installing an addon with dependencies) is fixed, test-verified and shipped in **`v0.4.7`** —
  retest on Windows with the published artifact (install an addon with `<depend>` packages and
  confirm the pip log shows `…\bin\python.exe`; existing builds are healed at install time, no
  reinstall required). Continue
  with the remaining B-19 live checks (optional checkbox install,
  dependent addon load in FreeCAD, removal warning UI) and the
  `v0.4.7` Linux AppImage retest (weekly install + open logs/folder + Python package install),
  then M8-05 (clean-VM Linux first-run) and M8-04 (macOS machine); the B-16 Windows-machine smoke
  is on hold (no machine). Next releases continue the `0.4.x` line. Backlog: `B-01` legacy
  channel, `B-14` CalVer readiness (before 27.1 branches, 2027-01-31), `B-02` in-place build
  updates, `R-21` (custom AppImage symlink cleanup), `B-16` dependency upgrades
  ([plan](PLAN-dependency-upgrades.md)) — B-18/R-24 shipped in `v0.4.2`, R-25/R-26 in `v0.4.3`,
  R-27/R-28 in `v0.4.4`, B-19/B-20/R-29/R-30 in `v0.4.5`, R-31 in `v0.4.6`, R-32 in `v0.4.7`,
  M8-07/M8-08 in `v0.4.9`.
- **Blockers**:
  - M8-04 needs a macOS machine. The Windows TLS-inspection VM is no longer a blocker.
  - The B-16 Phase 3 Windows-machine smoke is **on hold** (no Windows machine available as of
    2026-10-02); B-16 is otherwise complete. The same applies to the R-31 no-redist live check.
- **Current state**: `devel` is pushed to `origin/devel` at `bc91ea9` (R-36/D-119 `rc` channel
  `28faf1b` + 0.4.11 bump); **`v0.4.11` is published** as a pre-release (manual
  `create_release=true`, tag `v0.4.11` on `bc91ea9`, `prerelease=true`, run 37830243774;
  appimage/windows/publish all green) with
  `FreeCADLauncher-0.4.11-windows-x86_64.zip` + `.sha256` and
  `FreeCADLauncher-0.4.11-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after
  download (`sha256sum -c` OK), AppImage `--version` = 0.4.11 (exit 0) and the zip carries
  `7zr.exe`, license/notices and the app-local MSVC runtime. Earlier: **`v0.4.10` is published**
  as a pre-release (manual `create_release=true`, tag `v0.4.10` on `75803b5`, `prerelease=true`, run
  37397595261; appimage/windows/publish all green) with
  `FreeCADLauncher-0.4.10-windows-x86_64.zip` + `.sha256` and
  `FreeCADLauncher-0.4.10-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after
  download, AppImage `--version` = 0.4.10 (exit 0), the zip carries `7zr.exe`, license/notices and the
  app-local MSVC runtime. Earlier: **`v0.4.9` is published** as a pre-release (manual
  `create_release=true`, tag `v0.4.9` on `e3ca073`, `prerelease=true`, run 37371511156;
  appimage/windows/publish green after one Windows rerun during a GitHub hosted-runner outage)
  with `FreeCADLauncher-0.4.9-windows-x86_64.zip` + `.sha256` and
  `FreeCADLauncher-0.4.9-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after
  download, AppImage `--version` = 0.4.9 (exit 0). It carries M8-07/D-116 (metadata alignment +
  pinned root) and M8-08/D-117 (no automatic root move + stored-path repair). Earlier:
  **v0.4.7 is published** (manual `create_release=true`, tag `v0.4.7`, `prerelease=true`, run
  37341658955; appimage/windows/publish all green) with
  `FreeCADLauncher-0.4.7-windows-x86_64.zip` + `.sha256` and
  `FreeCADLauncher-0.4.7-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after
  download, AppImage `--version` = 0.4.7 (exit 0), the zip carries `7zr.exe`, license/notices and
  the app-local MSVC runtime (`vcruntime140.dll`, `vcruntime140_1.dll`, `msvcp140.dll`, …).
  `v0.4.7` carries **R-32/D-115** (the `pyXY` asset-name hint no longer stores the FreeCAD
  executable as `builds.pythonPath`; real interpreter discovery, legacy-path healing and the
  no-FreeCAD-as-Python guard) plus everything from `v0.4.6` (R-31/D-114 self-contained zip) and
  `v0.4.5` (B-19 `<depend>` dependencies D-108..D-111, B-20 AppImage macro Python execution
  D-112, R-29, R-30/D-113). Real E2E evidence: Ondsel-Lens
  installed from the catalog (probe skipped `requests`, pip installed `tzlocal`), real catalog
  check (67 addons with `<depend>`), real
  HistoryWorkbench archive extracted with 3 skipped links. The owner-reported “click install,
  nothing happens” (dialog-phase probe triggering a silent ~800 MB AppImage extraction) was fixed
  and re-verified live; B-20 removed the persistent `builds/<id>/extracted/` tree on FUSE
  systems. Remaining live checks (test-covered but not yet live): R-32 Windows retest, optional
  checkbox install, dependent addon loaded inside FreeCAD, removal warning UI; bundle/batch flows
  install required dependencies only. `R-19` live AppImage check, `R-21` and `B-16` remain.
- **M8-07 metadata + Windows data root** (D-116, DONE): `windows/runner/Runner.rc`
  `LegalCopyright` + macOS `PRODUCT_COPYRIGHT` now match the D-074 holder exactly and Windows
  `CompanyName` is `Frank Martínez`; the Windows data root is pinned to
  `%APPDATA%\org.freecad.ext.launcher` (D-016) computed from `APPDATA` instead of the exe
  VERSIONINFO; `check_version_info.ps1` asserts the exe VersionInfo in the CI and release Windows
  jobs; version bumped 0.4.7 → 0.4.8. `flutter analyze` clean, 709 tests green (10 skipped); five
  commits pushed to `origin/devel` and CI green on `09c4ded` (run 37362656403: `windows-latest`
  build + metadata guard, `ubuntu-latest`). The original one-time rename of the legacy
  `%APPDATA%\FreeCAD Launcher contributors\FreeCAD Launcher` was **replaced by D-117/M8-08**
  after owner testing showed it marks all installed builds Broken (stored absolute paths).
- **M8-08 data-root regression fix** (D-117, WIP): the Windows root is never moved — pinned
  `%APPDATA%\org.freecad.ext.launcher` is used when it has `config.db`, otherwise the legacy
  `%APPDATA%\FreeCAD Launcher contributors\FreeCAD Launcher`, otherwise pinned (fresh installs);
  `DataRootRepair` rewrites stale legacy-prefixed paths (`builds.localPath`/`pythonPath`,
  cache `payloadPath`, addon `sourcePath`, python `targetDir`) into the active root only when the
  mapped target exists, logged once after logger setup; new resolver/repair tests, version bumped
  0.4.8 → 0.4.9, analyze clean, 713 tests green (10 skipped). Pending: the owner's Windows retest
  (already-moved install recovers; legacy-only install untouched).
- **B-16 dependency upgrades** (done 2026-10-02): drift, flutter_svg/xml and signals 7.1 plus the
  R-23 fix and the Flutter 3.47.6 pin (D-103) merged to `devel` via PR #2 (`d7cf10b`, `cdbbec2`,
  `fcc90a7`, `2b2cdf7`, `6a2c08f`, `d0f5c1a`; devel CI green, run 37063237308), followed by the
  B-17 `.watch()` cleanup (PR #3, below). The no-publish release smoke (run 37063249302) built
  and verified the AppImage (`sha256` OK, `--version` = 0.4.1, GUI dashboard) and the Windows zip
  (portable bundle + `7zr.exe` + license/notices); the real Linux catalog install and an
  isolated profile launch were **owner-verified on a Linux machine 2026-10-02** (all passed, no
  issues) — only the Windows-machine smoke remains. Crash root cause and migration plan in D-101 /
  [PLAN-signals-implicit-migration.md](PLAN-signals-implicit-migration.md).
- **B-17 signals implicit-tracking migration** (branch `signals-implicit-migration`): all 127
  `.watch(context)` sites across 34 classes migrated in four batches (`6c9f375`, `f2c24ee`,
  `8009cfc`, B-17d commit pending); `flutter analyze` is back to **No issues found** and the
  `--no-fatal-infos` CI bridge is removed. B-17c found that implicit tracking drops unused
  subscriptions (the old `watch()` was sticky) and fixed `BundleDetailView`. 615 tests green;
  full live click-through incl. a live dark↔light theme switch, zero runtime errors; **merged to
  `devel`** (PR [#3](https://github.com/mnesarco/FreeCAD-Launcher/pull/3), run 37059277836
  green).
- **B-18 Home “Recent profiles” row** (branch `b18-home-recent-profiles`): `ProfilesController`
  gains a `recentProfiles` computed (used profiles with installed builds, newest first, cap 5)
  and Home's top section is a horizontally scrollable row of up to five compact cards — the whole
  card launches through the existing `launchProfile` guards and a chevron opens the profile
  detail via the new `ProfilesViewState.openProfile`/`AppShell` wiring. Spec 03 §2.1 and l10n
  updated (obsolete keys removed); 9 new tests (624 green, analyze clean); live pass verified the
  order, chevron navigation and the narrow-window horizontal scroll with zero runtime errors;
  PR/CI pending.
- **Recently completed**:
  - M1-01..M1-10 — foundation complete (schema, core, paths/env, process runner, shell,
    diagnostics, CI workflow, test harness).
  - S1 — **D-018**: bundle official 7-Zip standalone `third_party/7zip/7zr.exe`.
  - S2 — **D-019**: `.dmg` install via `hdiutil` + consent-based quarantine removal.
  - M2-01..M2-07 — releases client, version model/classifier, catalog cache, downloader,
    extractors/installer, Python probe, builds controller + Versions UI. Real Linux AppImage
    install verified end-to-end.
  - M2-08 — `BuildsController.importCustom` (local file, URL with optional checksum, custom
    executable registration) + Custom tab form with file picker and trust dialog.
  - M2-09 — `remove` now returns `Result` and is blocked while profiles use the build;
    `verify` re-checks files and AppImage hashes, updating `status`/`verified`; UI verify and
    remove feedback.
  - M2-10 — `reconcile()` on startup marks builds `missing`/`broken` from the filesystem;
    Installed tab shows status badges.
  - M2-11 — `DiagnosticsService.fuseAvailable()` and `LaunchEnvironment` support for
    `APPIMAGE_EXTRACT_AND_RUN=1` on Linux.
  - M2-12/M2-13 — **D-020**: custom builds accept any user-selected executable (all-files
    picker, exec-bit/missing validation, referenced in place, never copied/deleted); Python
    detection via near-binary probe or headless temp-macro run (`FreeCADCmd`/`--console`, stdin
    closed by `ProcessRunner.run`, probe env isolated to a temp home) with a manual interpreter
    picker fallback; `builds.pythonPath` added (schema v2 + `onUpgrade`). Real probe verified on
    the local 0.21.2 AppImage (version-only, transient mount) and on an extracted AppImage
    (interpreter path resolved).
  - M2-14 — **D-021**: support floor is FreeCAD 1.0+; pre-1.0 tags (0.19–0.21) are ignored at
    tag parse, `legacy` now means the older supported 1.0.x line, the `FreeCAD-Bundle` fallback
    and the `<= 0.20` flat pip target dir are dropped. Custom binaries are unconstrained.
  - M2-15 — **D-022**: AppImage Python detection fixed with the prototype's method — a tagged
    `.FCMacro` run headless (`-c -M <dir> <macro>`, JSON output, `sys.exit(0)`) with the
    asset-name hint as fallback; extracted `squashfs-root` interpreters are still used when
    present. Verified on real 1.0.2, dev (1.1) and 0.21.2 AppImages.
  - M2-16 — **D-023**: custom local AppImages are symlinked into `builds/<id>/` instead of
    copied (executable check, copy fallback if symlinks are unavailable, `remove` deletes only
    the link); URL AppImages and catalog installs keep managed copies.
  - M2-17 — **D-024**: hashing is now opt-in — imports/downloads hash only when a checksum is
    provided (local AppImage import dropped from ~10.3 s hashing to ~0.5 s install+probe);
    `InstallStage` gained `hashing` and `detectingPython` with 1%-throttled progress shown in
    both the Available list and the Custom tab.
  - M2-18 — **D-025**: successful catalog installs and custom imports switch to the Installed
    tab; failures stay on the current tab.
  - M2-19 — **D-026**: "download hangs" was a slow-link perception (GitHub release assets
    measured at ~55–75 KB/s here, ~4 h for 820 MB); the UI now shows transferred/total bytes and
    speed and the downloader coalesces updates to 1% steps.
  - M3-01 — **D-027**: `ProfilesRepository` + pure rules (`profile_rules.dart`) — trimmed
    1–64-char case-insensitively unique names; binding requires an installed build with a
    detected Python; `setBuild` reports `pythonChanged`. 17 new tests.
  - M3-02 — **D-028**: atomic profile directories (`profiles/<id>.part` → rename, DB insert
    after, rollback on failure); `delete` removes the directory then the row (FK cascades);
    `duplicate` copies config by default or the full payload on request (UI will ask);
    duplicating an unhealthy profile is allowed.
  - M3-03 — **D-029**: `LaunchPlanBuilder` composes the pure launch plan (executable + user args
    + `-u/-s` config flags + per-OS sanitized env, AppImage fallback flag); unit matrix covers
    Linux/Windows/macOS and asserts every env directory is part of the created layout.
  - M3-04 — **D-030**: `FreeCadRuntime` + `ProfilesController.launch` (blocks unhealthy builds,
    recreates dirs, records `lastUsedAt`); AppImage FUSE fallback via diagnostics; macOS
    quarantine consent flow; real Linux 1.0.2 AppImage launched headless (`--version`, exit 0).
  - M3-05 — **D-031**: refcounted running state (`runningProfiles`), per-launch log files
    (`logs/launch-<name>-<ts>.log` with command header), `lastExitCodes`, `ProfileLaunch.exitCode`;
    real manual launch asserts running true→false and log content.
  - M3-06 — **D-032**: Profiles UI — live cards (build/Python/counts/size/last-used/running),
    create/edit/duplicate/delete dialogs, launch with quarantine consent, detail page with six
    tabs (Overview functional, rest placeholders), loading/empty/error states; 3 widget tests.
  - M3-07 — **D-033**: "Show launch command" dialog (isolation overrides + removed vars,
    POSIX/Windows shell line, clipboard copy); `planFor` returns the plan without spawning;
    manual test runs the generated command via `/bin/sh -c` (exit 0).
  - M3-08 — **D-034**: CLI mode (`list`, `run`, `--version`, `--help`, `--` passthrough) with
    defined exit codes; Linux release shell checks pass; `run` launched the real Pixi profile
    (GUI build ignores `--version`).
  - M3-09 — **D-035**: CLI wrapper installer (`~/.local/bin/freecad-launcher` /
    `%LOCALAPPDATA%\…\freecad-launcher.cmd`), `$APPIMAGE`-aware target, PATH status report-only,
    Settings card with install/remove; manual Linux wrapper ran the built CLI (`--version`).
  - M3-10 — isolation E2E verified on Linux: two profiles on the same 1.0.2 AppImage wrote
    distinct markers into `FREECAD_USER_HOME`, `HOME`, `TMPDIR` and `Mod/`; deleting one profile
    left the other intact (paths in the session log). `HOME` isolation was later removed by
    D-075/R-09 (`HOME` is now inherited).
  - S3 — **D-036**: pip has no `--target` uninstall; `--upgrade` is mandatory and leaves old
    dist-info. Removal is RECORD-based (delete files inside the target, prune empty dirs);
    updates uninstall first then reinstall. Tested with Python 3.12 / pip 24.0.
  - M4-01 — **D-037**: addon domain models + `package.xml` parser, branch URL fallback to the
    CDN base, `AddonCatalog` with 6 h TTL / stale fallback / `addons:catalog` cache row.
    Real catalog parses to 167 addons / 175 branches (one entry has no install URL).
  - M4-02 — **D-038**: `AddonsController` (query/`#tag`, content, installed, FreeCAD-version
    filters + computed view, installed counts, branch selection) and the catalog UI (stale
    banner, lazy grid with icons, detail with metadata/branches; Install disabled until M4-03).
  - Fix — "Could not load the addon catalog": `Downloader` wrote to its own cache dir while
    `AddonCatalog` parsed `cache/addons/`; `download(directory:)` now targets the catalog dir
    (regression test uses separate directories). Orphaned downloads-cache zip removed.
  - Fix — catalog search retained its filter after visiting a detail but cleared the input
    (disposed `TextEditingController`); the field now lives in `AddonsView` and has a clear
    button, with a widget regression test.
  - M4-09 — desktop input theme: compact, rounded, fully outlined fields and dropdowns via
    `buildAppTheme`/`InputDecorationThemeData` (8 px radius); addon filter dropdowns wrapped in
    `InputDecorator`; theme regression test added.
  - M4-10 — addon content and installed-state filters are now multi-select checkable menu items
    (hamburger with active-count badge, clear action); empty or both-checked selections mean "no
    filter". The hamburger sits in the search/refresh row; the FreeCAD-version filter row only
    appears when installed versions exist. Controller and widget tests cover multiple checks.
  - M4-03 — **D-039**: `AddonInstaller` (download → safe extract → `Mod/<id>` atomic replace
    with `.old` backup, single-root stripping, zero-file guard) + `AddonsController.install`
    (DB row, installing/error signals) and a profile picker/Install button in the detail page.
    Real A2plus install verified (6.1 MB, `package.xml`/`InitGui.py`).
  - M4-11 — profile detail **Addons** tab now lists installed addons (name, version, branch,
    installed date) from `ProfilesController.installedAddons`, with the standard empty state
    (previously a placeholder, which made successful installs look lost).
  - M4-04 — **D-040**: update detection (catalog timestamp/version), pre-update backups in
    `<profile>/backups/addon-<id>-<ts>/`, reinstall via the atomic installer, and remove
    (files + DB row, backups kept); detail page shows Update/Remove for installed addons.
    Real A2plus E2E verified: install → update (backup contains `package.xml`) → remove.
  - M4-05/M4-06 — **D-041**: requirements parser (extras/specifiers/markers, invalid options),
    consent dialog (install packages / addon only / cancel), interpreter resolution
    (`pythonPath` → nearby → bundled → AppImage extraction), `PipRunner` with sanitized env,
    per-run logs, output tail and a global serialization queue; `python_packages` rows recorded
    per requirement. Real `six` install verified via the extracted interpreter.
  - M4-07 — **D-042**: RECORD-based `PythonUninstaller` (normalized dist-info lookup, unsafe
    path rejection, empty-dir pruning) + `PythonController` (manual pip install with
    `source=manual` rows, uninstall files + row, per-profile signals) and the profile **Python**
    tab (install dialog, list, remove). Real `six` install + uninstall verified (9 files).
  - M4-08 — **D-043**: `Job`/`JobsController` queue (downloads 2, install+pip 1), `JobContext`
    (progress/detail/log/fail/token), cancel/retry/clear, `CancellationToken.addListener` so
    build/addon downloads abort and delete `.part` files, and the status-bar summary + jobs
    dialog (progress, log path, Cancel/Retry). Builds install, addon install/update and manual
    pip install are wired through the shared queue; 13 new tests (incl. cancel cleanup).
  - S4 — **D-044**: macro catalog source verified — official `addons.freecad.org/macro_cache.zip`
    (+`.sha256`, same pattern as the addon catalog; 262 macros with embedded code/metadata/license,
    generated from `FreeCAD/FreeCAD-macros` + wiki). Placement confirmed on real FreeCAD 1.0.2
    (`getUserMacroDir` == profile root under `FREECAD_USER_HOME`); license is per macro (172/262
    unlicensed) and will be shown and persisted (schema v3 in M5-05). No API/rate-limit concerns.
  - M5-01 — **D-045**: bundles controller and Collections tab (list, create/edit, optional seed
    from a profile's installed addons, addon picker with catalog search, per-item branch, remove,
    delete); async name validation mirrors profile rules; `BundlesDao.save` now clears nullable
    fields. Apply/export/import deferred to M5-02/M5-03. 12 new tests.
  - M5-02 — **D-046**: pure `planBundleApply` (install/update/skip/unavailable, shared update
    rule with `isUpdateAvailable`), `BundleApplyController` (sequential execution, progress
    signals, summary, failure-tolerant) and the Apply dialog (profile picker, action chips,
    one-shot requirements consent, progress, summary). 12 new tests.
  - M5-03 — **D-047**: pure bundle JSON codec (schema 1, validation, trimming, malformed-entry
    skipping), `exportJson`/`importJson` with dedupe and `unresolvedAddonIds`, and the
    Import/Export UI (file picker dialogs, editable name to resolve clashes, unresolved
    warnings). 10 new tests.
  - M5-04 — **D-048**: `MacroCatalog` (official `macro_cache.zip` + `.sha256`, sidecar hash
    short-circuit, verified zip) and `parseMacroCatalog`; `MacroInstaller` (atomic code write,
    base64 aux files, XPM/icon) and `MacrosController` (jobs-wrapped install, catalog rows); the
    Macros screen lists the catalog with search/profile picker/install. 18 new tests.
  - M5-05 — **D-049**: schema v3 (`macros.license`, `macros.sizeBytes`), `MacroScanner` (root +
    legacy `Macro/`), startup reconciliation (insert/update/delete), delete with file removal,
    `MacroFileActions` (open/reveal via argument arrays) and the tabbed Macros screen
    (Installed/Catalog). 5 new tests.
  - M5-06 — **D-050**: `ConfigSnapshotService` (user.cfg/system.cfg timestamped snapshots,
    newest-first listing, restore, delete, cap 10), `ProfilesController` snapshot signal/actions,
    `FileActions.openDirectory` and the wired Config/Backups profile tabs. 6 new tests.
  - M5-08 — **D-051**: installed-macro list extracted to `InstalledMacrosList` and wired into
    the profile detail **Macros** tab (self-start + reconcile on mount); all six detail tabs are
    functional and `_ComingSoonTab` is gone. 1 new test.
  - Fix — **D-052**: macros now live in `<profile>/Macros/` (installer, scanner, delete, list
    paths, profile layout); spec 04/06 updated. Startup reconciliation ignores root-level files.
  - Fix — **D-053**: `ProfilesController.launch` now forces FreeCAD's
    `BaseApp/Preferences/Macro/MacroPath` to `<profile>/Macros/` in `user.cfg` (minimal config
    created when missing, corrupt files untouched); verified on real 1.0.2
    (`getUserMacroDir(True)` = `<profile>/Macros/`).
  - Fix — **D-054**: Macros Catalog drops the top profile dropdown; Install opens a target
    profile dialog (installed profiles disabled, list scrollable for many profiles), rows show
    an `Installed in N profile(s)` chip.
  - M5-07 — **D-055**: manifest JSON export/import — pure codec + absolute-path scanner
    (`domain/profiles/profile_manifest.dart`), `ProfileManifestController` (export/preview/
    import), embedded `user.cfg`/`system.cfg` text (≤ 4 MiB), contained-bundle names, build
    version/channel match with picker fallback, `<name> (imported)` clash handling, optional
    reinstall of addons and source-grouped pip packages, `MacroPath` rewrite via D-053, and the
    Profiles header/card/Backups-tab actions. `PythonController.install` gained a `source` param.
    Cross-OS (Linux export → Windows-configured launcher import) and UI tests included.
  - Fix — Versions → Available install progress was a `ListTile` trailing `Column` (progress bar,
    bytes/speed, stage + Cancel) and overflowed the tile bottom; the progress bar/stage/detail now
    live in the subtitle (which grows the tile) with only Cancel in the trailing. Regression widget
    test `test/ui/builds_view_test.dart` overflows on the old layout.
  - M6-10 — **D-056**: addon pinning/freeze per profile: schema v4 (`installed_addons.pinnedAt`
    + migration), `AddonsController.pin`/`unpin`, hard freeze (update blocked, `UpdatesController`
    skips pinned rows, `planBundleApply` reports pinned as skip), pin/unpin UI in the profile
    Addons tab, Pinned chip in the catalog detail, `addons[].pinned` in the manifest (export and
    import re-pin). Per-profile scope: other profiles still see their own updates.
  - M6-01 — **D-057**: `UpdatesController` (addon checks against the cached catalog, per-profile
    `outdated`/`outdatedByProfile`, persisted `updates.addons.lastCheckedAt`) and badges on all
    surfaces: status-bar chip + summary sheet (grouped by profile, Check action), profile cards,
    profile Addons tab rows and catalog cards, plus a Check action in the addons header.
    Notify-only, no auto-install; pinned addons are excluded per profile.
  - M6-02 — **D-058**: build update checks + badges: `UpdatesController` gained `BuildsController`,
    `outdatedBuilds` (stable, non-custom, same asset kind, installed, parseable version) and
    `outdatedCount`; `check()` loads both catalogs cache-first and stamps
    `updates.addons.lastCheckedAt` + `updates.builds.lastCheckedAt` (`lastCheckedAt` is now the
    max of the two). Notify-only: a "1.1.3 → 2.0.0" chip on Versions → Installed tiles and a
    FreeCAD-builds section in the status summary sheet; no update button (B-02 is v0.2).
  - M6-11 — **D-059**: desktop form style back to the prototype: 4 px outlined inputs (dense
    default padding) and a shared `FormRow`/`FormTextField`/`FormDropdown`
    (`lib/ui/widgets/form_row.dart`) with a fixed 130 px label column; migrated profile
    create/edit + duplicate, custom build import (640 px form), manifest import, bundle
    create/edit/apply/import, Python specs and the addon install target. Search and filter rows
    stay compact; dialog widths 420 → 480.
  - M6-03 — **D-060**: batch addon updates: `UpdatesController.applyUpdates` runs the selected
    items sequentially through `AddonsController.update` (shared job queue per item), tracks
    progress/current item and returns an `AddonUpdateApplySummary` (updated/failed + error). The
    summary sheet pre-checks every outdated addon, offers per-item toggles + "Update selected (N)",
    shows aggregate progress during the run and a summary with "Retry failed" afterwards; builds
    stay informational until B-02.
  - 435 tests green (8 manual probes skipped), analyze clean, app builds and launches. Visual
    check: temporary golden renders of the real profile dialog (label-left geometry, 4 px outlined
    fields) were inspected and removed; runtime pass via the Dart/Flutter MCP/VM service on the
    real dev DB: v3 → v4 migration applied, badge rendered with an aged unpinned addon and
    disappeared when only a pinned addon was outdated (temporary dev-data changes were restored
    exactly afterwards).
  - Fix — UI polish pass (inspector-verified live): shared `CompactDropdown` (addons filter
    extracted; version filter moved into the search row with matching field heights), profile
    Macros tab top padding, shared `CompactBadge` replacing every list/grid/dialog `Chip`,
    `FormRow` label column 130 → 195 px (D-059), prototype `freecad-launcher-icons` font ported
    to `lib/ui/icons.dart` (Versions tiles + nav rail show the FreeCAD glyph), and branch
    selection in the addon detail now watches `selectedBranches` (previously the radio only
    refreshed after an unrelated `setState`, i.e. the install-target dropdown).
  - Fix — installed addons in the profile Addons tab now show their catalog icon via an offline
    cache-only load (`AddonCatalog.cachedAddons`, `AddonsController.ensureCachedCatalog`);
    visiting Addons still refreshes the catalog normally.
  - M6-04 — **D-061**: settings screen with persisted theme (`theme_mode`), update cadence
    (`update_check_interval`) and log level (`log_level`) in the `settings` table; theme applied
    app-wide via a signal, log level applied to `appLogger` live, cadence triggers a due-only
    startup update check (`UpdatesController.checkIfDue`). Section cards (General/Logs/CLI
    wrapper/About/Diagnostics) use the D-059 form style; data dir and logs folder open in the
    file manager. Cache deferred to M6-05, debug bundle to M6-06, GitHub token to B-07. Manual
    pass on the dev app (live light↔dark switch, dropdowns, diagnostics) plus domain/controller/
    widget tests.
  - Fix — **D-062**: `LaunchPlanBuilder` now prepends `--console` whenever `--version` is passed
    to FreeCAD, so GUI builds print the version and exit instead of opening a window (the Pixi
    build observed in M3-08); all other arguments stay verbatim.
  - M6-05 — **D-063**: cache management — `CacheService` reports per-category sizes, clears a
    category (payloads + `catalog_cache` row, so the next load refetches) and prunes downloads
    older than the persisted `cache_retention_days` (Forever/7/30/90, default 30); startup prune
    in `AppShell`, manual "Clean up now", and Clear/Clean-up disabled while jobs run. Settings
    Cache card verified live (downloads 823.8 MiB, GitHub releases cleared 3.1 MiB → 0 B);
    integration test asserts a cleared catalog refetches on the next load.
  - M6-06 — **D-064**: debug bundle export — `DebugBundleService` writes a zip with
    `system.txt` (launcher/Dart/OS, data dir, builds + profiles inventory), `diagnostics.txt`
    and every `logs/` file line-redacted through `redactSensitive`; Settings → Logs export via
    save dialog with a Reveal action. Real export reviewed: 14 files / ~12 KB, useful content,
    no secret patterns; no DB file.
  - M6-07 — state coverage pass: per-screen matrix added to `VERIFICATION.md` (loading, empty,
    filtered-empty, error, offline/stale, partial data, overflow) with live checks for Home,
    Versions Installed/Custom, Addons Catalog/Collections/detail, Macros Catalog/Installed,
    Profiles + all detail tabs, Settings, and widget/unit-test evidence elsewhere. Fixed the
    Collections addon picker so it reports an unavailable catalog instead of "no matches"
    (regression test). Noted gaps: Home dashboard (spec 03 §2.1 normal state) is not in v0.1.
  - M6-08 — **D-065**: keyboard shortcuts and a11y — spec 03 §4 map implemented in `AppShell`
    (`Ctrl/Cmd+1..6` sections, `Ctrl/Cmd+N` create profile, `F5` context-aware refresh,
    `Ctrl/Cmd+F` search focus with Macros tab switch, `Esc` closes dialogs) via a
    `SectionShortcuts` interface + `GlobalKey`s; a11y guideline tests (labeled tap targets,
    Android tap targets, text contrast) pass on all six sections; Settings paths switched from
    `SelectableText` to `Text` to fix the tap-target finding. Shortcuts verified live
    (Ctrl+2/Ctrl+4/Ctrl+F) and by widget tests.
  - M6-09 — **D-066**: performance pass — startup timing logs (`perf` tag) and off-thread
    catalog parsing via `Isolate.run` in the addon/macro/releases catalogs. Measured on the
    release build with a warm data root (3 runs): wall to first frame **553/559/561 ms**,
    in-process bootstrap 14–23 ms, first frame 142–186 ms; previously the addon (190 ms) and
    macro (390 ms) parses blocked the UI isolate right after startup. **M6 complete.**
  - M6-12 — **D-067**: Home dashboard — five stat tiles (builds/profiles/addons/macros/packages)
    navigating via the new `ShellController`, a last-used-profile launch card, an updates card
    that runs a check and opens the summary sheet, a first-run 3-step checklist, and a cached
    RSS/Atom news feed (default `https://blog.freecad.org/feed/atom/`, verified Atom; the
    previously planned `https://freecad.org/news.rss` is not published yet) with a
    `news_feed_url` setting and a fifth cache category.
    Shell navigation moved from local state to `ShellController`; widget tests for Home
    (stats/checklist/news error); 482 tests green.
  - S5 — **D-068**: reproducible AppImage build — `packaging/appimage/` (AppRun, .desktop,
    generated icon, pinned appimagetool 1.9.1 + type-2 runtime with SHA-256 checks, vendored
    excludelist + forced font/text libs, glib-family symlink fix for `path_provider`), a release
    workflow on `v*` tags, and a deterministic zsync. Two consecutive builds produced identical
    hashes (AppImage `a83b1ffb…`, 29.9 MB, 69 libs). Verified on the host with/without FUSE and
    in clean ubuntu:24.04 + fedora:41 containers (`--version` exit 0) plus a GUI launch from the
    AppImage.
  - Fix — open-folder/reveal buttons did nothing on Linux because `FileActions` spawned
    `xdg-open` with `includeParentEnvironment: false` (no `DISPLAY`/Wayland/DBus); it now inherits
    the parent environment, surfaces non-zero exits as `FileActionException`, and Settings and the
    profile Config tab show a failure snackbar (Macros already did). 3 new tests in
    `test/platform/file_actions_test.dart`; 485 tests green (8 manual probes skipped), analyze
    clean.
  - R-01 — **D-069**: installed builds can be relabeled. Schema v5 adds the nullable
    `builds.label` column (verified live: the real v4 dev DB migrated to v5 with the column, no
    data change); `version` stays load-bearing for update checks, manifest matching, the addons
    FreeCAD-version filter and the unique key. A `Build.displayLabel` extension (`label ??
    version`) is used on every surface (Installed tile and remove dialog, profile cards/detail/
    dialogs, manifest import picker, Home last-used card, CLI `list`, debug-bundle inventory).
    The pencil action on an Installed tile opens a small dialog pre-filled with the current
    label; clearing it restores the version label. Pure `build_label_rules.dart` (trim, ≤ 64
    chars, control-character rejection) + `BuildsController.relabel` with `BuildsDao.updateLabel`
    (a whole-row upsert cannot clear a nullable column, drift keeps absent columns unchanged).
    492 tests green (8 manual probes skipped), analyze clean.
  - R-02 — **D-070**: original launcher icon. The owner authored the design (red rocket with a
    white outline on a Tufts Blue rounded square); `packaging/appimage/freecad-launcher.svg` is
    the editable master and `render_icons.sh` regenerates the committed 512/256 PNGs the
    AppImage/desktop build consumes (D-068's FreeCAD-glyph placeholder is gone; no FPA logo
    involved). Visual checks at 512/256/64/32 px; the owner-created in-app font glyphs
    (`assets/fonts/freecad-launcher-icons.ttf`, `lib/ui/icons.dart`) are untouched. Trademark
    attribution still lands with M7-03/M7-04.
  - M7-01 — **D-071**: AppImage pipeline productionized. `packaging/check_version.sh` enforces
    `constants.dart` == `pubspec.yaml` and tag == version (wired into CI and the build script);
    CI is pinned to Flutter 3.41.4; `build_appimage.sh` refuses placeholder update-info unless
    `ALLOW_PLACEHOLDER_UPDATE_INFO=1`; `render_icons.sh` produces the full 16–512 px set and the
    AppDir ships the hicolor tree + `.DirIcon`; the tag workflow installs `zsync`/`xvfb`,
    verifies the sha256 sidecar and smoke-tests `--version` under `xvfb-run`. Local artifact
    `721cdb2b…` (29,903,352 bytes), three consecutive packaging runs identical
    (zsync `a5c38072…`); clean ubuntu:24.04 and fedora:41 (Xvfb + Mesa) pass CLI + GUI with no
    gdk-pixbuf/GTK asset errors. GitHub tag execution stays blocked on OQ-7.
  - M7-06 — Linux manual functional pass (2026-09-24): real 1.1.3 catalog install (782.8 MiB,
    Python 3.11 detected; ~8 min with a 1–2 min stall at 100%), custom executable import + trust
    dialog + "Python interpreter not detected" dialog, profile create/edit/rename and GUI launch
    (running badge, per-launch log, exit tracking on process end). `VERIFICATION.md` §4 Linux
    column filled. Findings filed: R-03 (Available does not auto-load on first visit), R-04
    (remove-dialog wording for in-place custom builds), R-05 (duplicate custom import raises a raw
    SqliteException), R-06 ("Choose Python…" picker unreachable after import), R-07 (download can
    stall at 100% with no timeout). Test build/profile/downloads were removed afterwards — the
    dev data root is back to its pre-session state.
  - Fix — R-03..R-07 from the M7-06 pass (2026-09-24, re-verified live): Available loads the
    catalog on first visit (with a guard so pre-seeded lists are not overwritten); the remove
    dialog uses in-place wording for referenced builds (custom executables, locally imported
    AppImages); re-importing a custom file reuses the existing row (no `UNIQUE constraint`
    crash); the post-import "Choose Python…" picker opens (Custom tab kept alive via
    `AutomaticKeepAliveClientMixin`, form state preserved); the downloader completes once the
    declared size is reached and rejects a stream that ends early. 6 new tests; 498 tests green
    (8 manual probes skipped), analyze clean; live checks confirmed R-03/R-04/R-05/R-06.
  - M7-03 — **D-074**: licensing artifacts. `LICENSE` is the verbatim GPL-3.0 text; 231
    hand-written sources (Dart + packaging scripts) carry
    `SPDX-License-Identifier: GPL-3.0-or-later`; `tool/generate_third_party_notices.dart`
    generates `THIRD_PARTY_NOTICES.md` from `dart pub deps --json` for the shipped closure
    (78 packages / 32 distinct license texts, deterministic) with bundled-system-library and
    FreeCAD trademark sections; the AppImage ships `LICENSE` + notices under
    `/usr/share/doc/freecad-launcher/` (local build + `sha256sum -c` + `--version` exit 0).
  - M7-04 — README + `docs/user-guide.md` (install, first run, builds, profiles, addons,
    collections, Python, macros, config/backups, manifest, updates, settings, CLI, shortcuts,
    data locations, troubleshooting, v0.1 limitations) with five current screenshots in
    `docs/images/`; relative links checked. **M7 complete** (M7-05 → M8-05).
  - R-08 — "Open profile folder" icon in the profile detail header (shared
    `openProfileFolder` helper in `profile_actions.dart`, same `xdg-open`/`open`/`explorer`
    command as the Config tab, failure snackbar); widget test asserts the command; hot-reloaded
    and header screenshot inspected in the running dev app.
  - R-09 — **D-075**: profile launches no longer override `HOME`. The inherited value passes
    through on Linux/macOS; `<profile>/home` was dropped from `ProfilePaths`/`directoriesFor`
    (existing dirs untouched). `FREECAD_USER_HOME`, XDG, AppData and temp overrides still isolate
    FreeCAD config/data. 500 tests green (8 manual probes skipped), analyze clean; manual
    isolation E2E re-run on the real 1.0.2 AppImage (distinct `FREECAD_USER_HOME`/`TMPDIR`/`Mod`
    markers, inherited `HOME` observed inside the profile, no `home/` created).
  - R-10 — **D-076**: macro icons from the catalog (147 PNG / 52 SVG of 262 entries) rendered in
    both Macros lists via `MacroIcon`, backed by `MacroIconCache` (16 MiB memory LRU +
    content-addressed `cache/macros/icons/<sha256>.<ext>`, pruned on catalog refresh, cleared
    with the macros cache). XPM/iconless macros keep the generic icon. 505 tests green (8 manual
    probes skipped), analyze clean; live dev-app check rendered real icons and persisted 166
    cache files (3.3 MB).
  - UI polish (same session): Addons filter button icon (`filter_list`), profile Config
    "Open profile folder" right-aligned, Macros defaults to the Catalog tab.
  - Home news excerpts (2026-09-30, post-R4): each news item shows a short excerpt (180-char
    word-boundary truncation in `NewsItem.excerpt`) above the date, with the title in the primary
    accent color (semibold) so posts stand out; the card lists up to 10 posts. 508 tests green,
    analyze clean; live dev-app check showed all five latest posts with excerpts.
  - B-01 weekly part — **D-077**: dated weekly builds work end-to-end. B-01a catalog collection
    (`weeklyBuilds` signal, one candidate per release via `selectFor`, rolling `weeklies`
    skipped); B-01b Available channel filter (Stable default) with "Weekly YYYY-MM-DD" labels,
    dev badges and an install confirmation warning; B-01c notify-only weekly update badges by
    tag date (stable/weekly never mixed, humanized in chips/summary); B-01d real verification —
    `weekly-2026.09.30` AppImage installed on Linux (767.3 MiB, SHA-256 verified, Python 3.13
    probed, headless `--version` = **FreeCAD 26.3.0**) and two profiles created/launched isolated
    on it. 514 tests green (9 manual probes skipped), analyze clean. Legacy (1.0.x) remains in
    B-01.
  - Weekly list cap (2026-09-30, post-R8): Versions → Available ▸ Weekly now shows at most the
    latest 52 dated builds (one year), newest first (`BuildsController.weeklyBuildLimit`).
  - R-11 — **D-079**: copyright notices. `SPDX-FileCopyrightText: 2026 Frank Martínez
    <mnesarco at gmail>` added above the license identifier in all 240 SPDX-tagged files
    (234 Dart, 4 shell, 2 Markdown; generated files untouched), README and Settings › About
    show the holder line, and `tool/generate_third_party_notices.dart` emits it in the notices
    header (regenerated, diff is the single line). 516 tests green (9 manual probes skipped),
    analyze clean.
  - R-12 — **D-080**: About dialog with the official FreeCAD logo. The official
    `org.freecad.FreeCAD.svg` (extracted from the official 1.1.3 AppImage) is bundled at
    `assets/images/freecad-logo.svg`; Settings › About opens a dialog showing the 96 px logo,
    version/license/copyright, the FPA trademark notice and the independent-project statement
    (Frank D. Martínez, aka mnesarco). README and the notices generator switched from "ships no
    FreeCAD artwork" to the attribution-only logo wording; notices regenerated. 517 tests green
    (9 manual probes skipped), analyze clean; live dialog verified.
  - Publishing prep (2026-09-30, **D-081**): repo is `mnesarco/FreeCAD-Launcher`; branch `v2`
    renamed to `devel` (public default; `main` left behind); CI runs on `devel`/`main` and now
    fails on `THIRD_PARTY_NOTICES.md` drift; the manual **Release AppImage** workflow gained
    `create_release`/`tag`/`prerelease` inputs and an optional GitHub Release step (artifacts
    always); README/user-guide point to the Releases page; the 4 MB prototype
    `addon_catalog_cache.json` was removed from the tree. Push/CI/release execution pending
    (M8-01/M8-02).
  - GitHub push + first CI (2026-10-01): `devel` pushed to `mnesarco/FreeCAD-Launcher` (public,
    default branch). First Linux job was green; a fresh-checkout issue (untracked empty
    `assets/macros/`) was fixed (`b3b58a2`). Windows/macOS failed 20/8 tests on POSIX
    assumptions, so per **D-082** `flutter test` is Linux-only for now while analyze and release
    builds stay on all three OSes; portability is tracked as **M8-06**. The macOS job was then
    disabled from the matrix per **D-083** (slow runners, dedicated work in M8-04); CI is now
    Linux + Windows with the Linux test job and both release builds, and the last run before
    the removal was fully green (ubuntu 3m07s, macOS 8m34s, windows 4m53s).
  - Manual AppImage workflow on GitHub (2026-10-01): the `release-appimage.yml` path silently
    refused registration on GitHub (stale parse cache; identical content under another filename
    registers), so it was renamed to **`appimage-release.yml`**. The first runs exposed two
    workflow bugs — missing `ninja-build libgtk-3-dev` and a stale rolling `continuous` runtime
    pin — both fixed (runtime now pinned to the dated `20251108` release, **D-084**). The
    subsequent manual run succeeded end-to-end (run 36810294004, 1m54s): AppImage 29.9 MB,
    sidecar verified, Xvfb smoke test, artifact uploaded; the artifact was downloaded and
    re-verified locally (`sha256sum -c` OK, `--version` = FreeCAD Launcher 0.1.0). M8-02 is
    DONE; the GitHub Release creation path (`create_release`/`tag`/`prerelease`) is still
    untested.
  - First release (2026-10-01): `v0.1.0` **pre-release** published via the manual workflow
    (run 36812429637) — [release page](https://github.com/mnesarco/FreeCAD-Launcher/releases/tag/v0.1.0)
    with `FreeCADLauncher-0.1.0-x86_64.AppImage` (29.9 MB), `.sha256` and `.zsync`; notes are
    GitHub-generated (no tokens). M8-01 and M8-02 are DONE. Next: M8-05 clean-VM pass with this
    published AppImage, then M8-03/M8-04 (Windows/macOS, need machines).
  - Docs refresh (2026-10-01, R20): README intro now states that multiple builds coexist and each
    can back any number of isolated profiles; the **Stable | Weekly** channel is documented in
    Features, Quick start and Updates; all five README screenshots were recaptured from the
    current build (light theme, 1280×720; Versions shows Available/Stable). No code changes.
  - Planning (2026-10-01, R21): custom addon installs specified in
    `docs/impl/PLAN-B10-custom-addons.md` — repository URL + branch (updateable), local zip/tar
    (FR-4.8), and dev symlink (live, link-only remove); backlog `B-10` expanded into
    `B-10a..B-10e`. Owner choices captured; decisions D-085..D-088 to be recorded at kickoff.
    No code changes.
  - Version bump (2026-10-01, R24): project version raised to **0.2.0** (`pubspec.yaml` +
    `core/constants.dart`, checked by `packaging/check_version.sh`); README status, the status-bar
    spec mock and the user-guide limitation labels updated. No behavior change.
  - Addon enable/disable (2026-10-01, R23): Profile → Addons rows gained a switch that
    writes/removes FreeCAD's `ADDON_DISABLED` marker (D-089, B-15a); state is derived from disk
    (no schema change), disabled rows show a badge and dimmed title, and the marker is also
    visible to FreeCAD's own Addon Manager. Live check on Development: File Explorer (managed)
    and Nxt (dev link) toggled on/off with the expected marker paths. 586 tests green, analyze
    clean; committed (`a9e3f1c`).
  - B-10 implementation (2026-10-01, R22): schema v6 `installed_addons.source`/`sourcePath`
    (live v5→v6 migration verified), domain helpers (package.xml parser extraction, addon id
    rules, GitHub/GitLab/Gitea archive URL builder), `AddonInstaller.prepare/commit` +
    `linkDirectory`, custom install/update/reinstall flows with conflict blocking and
    pre-placement requirements consent, Addons → **Custom** tab (repository/archive/dev-link
    forms + custom list with update/reinstall/reveal/remove and **Install in another profile…**),
    manifest `source` marker with import skip, and D-085..D-088. 582 tests green, analyze clean.
    Live verification through the UI: real `obelisk79/FreeCAD-Nxt` @ `main` repository install
    (`source=repo`, removed), local `nxt.zip` install (`source=zip`, removed), dev-symlink
    install (live edit visible, link-only removal, source intact) and the copy action (dev link
    copied Development → Production 1, picker hid the source profile; copy removed, original and
    working copy intact). Committed (`5a372ab`).
  - R-13 (2026-10-01, D-090): the Profile → Overview `Log` row is now a clickable link that
    opens the launch log with the system default text editor (`FileActions.open`), with a
    localized label/tooltip and a failure snackbar; `_InfoRow` gained an optional `onTap`.
    587 tests green (9 manual probes skipped), analyze clean; committed (`c0a00b9`). Widget
    test asserts the `xdg-open <log>` command.
  - R-14 (2026-10-01, **D-095**): the first real Windows `.7z` install failed with a raw
    `FileSystemException` during extraction because catalog build IDs (`stable:1.1.3:windows:x86_64`)
    were joined directly as directory names (`:` is illegal on Windows). New
    `lib/core/path_segments.dart` (`safePathSegment`: trim, ASCII-safe runs, edge dot/dash
    removal, Windows reserved-name guard) now feeds `AppPaths.buildDir`, launch-log names, macro
    file/icon names and addon backup directories; helper tests plus `buildDir` tests with POSIX
    and Windows path contexts. 604 tests green, analyze clean; committed (`031cc0e`), artifact
    rebuilt (run 36937972986) and the Windows retest confirmed the sanitized
    `stable_1.1.3_windows_x86_64.part` path (the install then hit R-15).
  - R-15 (2026-10-01, **D-096**): the retest reached 7zr and failed with
    `ProcessException: El parámetro no es correcto` (ERROR_INVALID_PARAMETER) at
    `process_win.cc:577`; `IoProcessLauncher` sent an empty environment with
    `includeParentEnvironment: false`, which Dart turns into a malformed one-wchar block that
    `CreateProcessW` rejects. On Windows, empty spec environments now inherit the parent
    environment; a Windows-only real-process test covers it. 606 tests green on Linux, analyze
    clean; artifact rebuild + Windows retest pending.
  - R-16 (2026-10-01): build installs now write `logs/install-<id>-<stamp>.log` (header, stages,
    error + stack trace), attach it to the job (`logPath`, shown in the Jobs dialog) and mirror
    failures to `app.log` via `appLogger.error`; 2 new tests.
  - R-17 (2026-10-01): the next retest got through 7zr and failed while measuring the install
    size — recursive listing aborted on FreeCAD paths over the Windows 260-char limit
    (`pkg_resources` test fixtures). New shared `platform/directory_size.dart` walks level by
    level and skips unreadable subtrees; `BuildInstaller` and `ProfilesController` use it.
    609 tests green, analyze clean; artifact rebuild + Windows retest pending.
  - M8-03 Windows matrix (2026-10-01): the owner ran the full clean-machine smoke matrix with the
    artifact from run 36941684639 and **all scenarios passed**; `VERIFICATION.md` §2/§4 Windows
    column filled.
  - Release (2026-10-01, **D-097**): version bumped to `0.3.0`, workflow renamed
    `appimage-release.yml` → `release.yml` (badge updated), tag `v0.3.0` pushed; the tag path ran
    the full workflow (run 36943644212: windows + appimage + publish all green) and the `publish`
    job created the GitHub Release with the Windows zip + AppImage (+ sidecars/zsync). Both
    sidecars re-verified after downloading from the release. **M8-03 DONE.**
  - Linux fixes + pre-release (2026-10-01): R-18 (probe-directory cleanup), R-19/D-098 (sanitized
    opener environment) and R-20/D-099 (pre-D-095 build directories) landed; version bumped to
    `0.4.0` and published as a **pre-release** through the manual `create_release=true` path
    (run 36947395864) with the Windows zip + AppImage; both sidecars verified.
  - R-22 (2026-10-01): Python-tab install dialog owned its `TextEditingController` in a
    `_PythonInstallDialog` StatefulWidget (use-after-dispose cascaded into the
    `_dependentsIsEmpty` assertion); verified live with a Flutter driver click-through and a
    regression widget test; released in `v0.4.1` (pre-release, run 36955018205).

## Session log

| Date | Session | Summary | Tasks | Touched |
|---|---|---|---|---|
| 2026-09-18 | planning | Requirements Q&A, cross-platform FreeCAD research, spec, implementation plan | — | `docs/spec/**`, `docs/impl/**`, `AGENTS.md` |
| 2026-09-18 | M0 | Resolved OQ-2/OQ-6, spec approved, workflow confirmed | M0-01..M0-04 | `docs/impl/DECISIONS.md`, `docs/spec/**` |
| 2026-09-18 | M1 | Prototype freeze, v2 branch, skeleton, l10n, platform runners | M1-01, M1-02 | `lib/**`, `test/**`, `linux/**`, `windows/**`, `macos/**`, `pubspec.yaml`, `l10n.yaml` |
| 2026-09-18 | M1 | Core result/errors/logging/constants | M1-03 | `lib/core/**`, `lib/main.dart`, `lib/ui/shell/**`, `test/core/**` |
| 2026-09-18 | M1 | Drift schema v1 + DAOs + tests | M1-04 | `lib/data/**`, `lib/domain/**`, `test/data/**` |
| 2026-09-18 | M1 | Profile paths + launch env + AppPaths | M1-05 | `lib/domain/profiles/**`, `lib/platform/paths.dart`, `test/domain/**`, `test/platform/**` |
| 2026-09-18 | M1 | Process runner | M1-06 | `lib/platform/process.dart`, `test/platform/process_test.dart` |
| 2026-09-18 | M1 | AppServices/AppScope, shell, empty states | M1-07 | `lib/state/**`, `lib/ui/**`, `lib/app.dart`, `lib/l10n/**` |
| 2026-09-18 | M1 | Diagnostics service + settings panel | M1-08 | `lib/platform/diagnostics.dart`, `lib/ui/settings/**`, `test/helpers/**` |
| 2026-09-18 | M1 | CI workflow + test harness | M1-09, M1-10 | `.github/workflows/ci.yml`, `test/helpers/**`, `test/fixtures/**` |
| 2026-09-18 | M2 | Spikes S1/S2, D-018/D-019, bundled 7zr | S1, S2 | `third_party/7zip/**`, `docs/impl/DECISIONS.md` |
| 2026-09-18 | M2 | Releases client, model/classifier, catalog cache | M2-01..M2-03 | `lib/data/catalog/**`, `lib/domain/builds/**`, `test/**` |
| 2026-09-18 | M2 | Downloader, extractors, installer, Python probe | M2-04..M2-06 | `lib/platform/**`, `test/platform/**`, `test/manual/**` |
| 2026-09-18 | M2 | Builds controller + Versions UI | M2-07 | `lib/state/**`, `lib/ui/builds/**`, `test/state/**` |
| 2026-09-18 | M2 | Custom import, verify/guard, reconciler, FUSE fallback | M2-08..M2-11 | `lib/state/builds_controller.dart`, `lib/ui/builds/**`, `lib/domain/profiles/**`, `lib/platform/diagnostics.dart`, `test/**` |
| 2026-09-19 | M2 | D-020 custom executable import + Python detection; schema v2 `pythonPath`; probe env/stdin fixes | M2-12, M2-13 | `docs/impl/DECISIONS.md`, `docs/spec/**`, `lib/data/**`, `lib/platform/process.dart`, `lib/platform/python_probe.dart`, `lib/platform/build_installer.dart`, `lib/state/builds_controller.dart`, `lib/ui/builds/builds_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M2 | D-021 FreeCAD 1.0+ support floor; legacy = 1.0.x; pre-1.0 fixtures now ignored | M2-14 | `docs/impl/DECISIONS.md`, `docs/spec/**`, `lib/domain/builds/freecad_version.dart`, `test/domain/**` |
| 2026-09-19 | M2 | D-022 AppImage Python detection via prototype headless macro; probe rewrite + tests | M2-15 | `docs/impl/DECISIONS.md`, `docs/spec/04-architecture.md`, `lib/platform/python_probe.dart`, `test/platform/python_probe_test.dart` |
| 2026-09-19 | M2 | D-023 custom local AppImages symlinked in place instead of copied | M2-16 | `docs/impl/DECISIONS.md`, `docs/spec/02-requirements.md`, `docs/spec/03-ux.md`, `docs/spec/05-data-model.md`, `lib/platform/build_installer.dart`, `lib/state/builds_controller.dart`, `test/**` |
| 2026-09-19 | M2 | D-024 opt-in hashing + progress stages for imports | M2-17 | `docs/impl/DECISIONS.md`, `docs/spec/**`, `lib/platform/checksum.dart`, `lib/platform/downloader.dart`, `lib/state/builds_controller.dart`, `lib/ui/builds/builds_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M2 | D-025 navigate to Installed tab after successful install/import | M2-18 | `docs/impl/DECISIONS.md`, `docs/spec/03-ux.md`, `lib/ui/builds/builds_view.dart` |
| 2026-09-19 | M2 | D-026 download bytes/speed feedback; downloader progress coalescing | M2-19 | `docs/impl/DECISIONS.md`, `docs/spec/03-ux.md`, `lib/platform/downloader.dart`, `lib/state/builds_controller.dart`, `lib/ui/builds/builds_view.dart`, `test/**` |
| 2026-09-19 | M3 | D-027 profile repository, name validation and binding rules | M3-01 | `docs/impl/DECISIONS.md`, `docs/spec/02-requirements.md`, `docs/spec/05-data-model.md`, `lib/domain/profiles/profile_rules.dart`, `lib/data/repositories/profiles_repository.dart`, `lib/state/app_services.dart`, `test/**` |
| 2026-09-19 | M3 | D-028 atomic lifecycle (create/duplicate/delete) + payload duplication | M3-02 | `docs/impl/DECISIONS.md`, `docs/spec/02-requirements.md`, `docs/spec/03-ux.md`, `docs/spec/05-data-model.md`, `docs/impl/VERIFICATION.md`, `lib/data/repositories/profiles_repository.dart`, `lib/state/app_services.dart`, `test/**` |
| 2026-09-19 | M3 | D-029 pure launch plan (executable + argv + env) with per-OS matrix tests | M3-03 | `docs/impl/DECISIONS.md`, `docs/spec/04-architecture.md`, `lib/domain/profiles/launch_plan.dart`, `test/domain/launch_plan_test.dart` |
| 2026-09-19 | M3 | D-030 launch runtime, profiles controller, FUSE fallback and quarantine consent | M3-04 | `docs/impl/DECISIONS.md`, `docs/spec/02-requirements.md`, `docs/spec/04-architecture.md`, `lib/platform/launch.dart`, `lib/state/profiles_controller.dart`, `lib/state/app_services.dart`, `test/**` |
| 2026-09-19 | M3 | D-031 process tracking: running signal, launch logs, exit codes | M3-05 | `docs/impl/DECISIONS.md`, `lib/state/profiles_controller.dart`, `test/state/profiles_controller_test.dart`, `test/manual/real_launch_linux_test.dart` |
| 2026-09-19 | M3 | D-032 profiles UI: cards, dialogs, detail tabs skeleton | M3-06 | `docs/impl/DECISIONS.md`, `lib/state/profiles_controller.dart`, `lib/data/daos/**`, `lib/ui/profiles/**`, `lib/l10n/**`, `test/ui/**` |
| 2026-09-19 | M3 | D-033 launch command viewer with isolation overrides and copy | M3-07 | `docs/impl/DECISIONS.md`, `lib/domain/profiles/launch_command.dart`, `lib/state/profiles_controller.dart`, `lib/platform/launch.dart`, `lib/platform/paths.dart`, `lib/ui/profiles/**`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M3 | D-034 CLI mode (list/run/help/version, passthrough, exit codes) | M3-08 | `docs/impl/DECISIONS.md`, `lib/cli/cli.dart`, `lib/main.dart`, `test/cli/cli_test.dart` |
| 2026-09-19 | M3 | D-035 CLI wrapper installer + settings card + PATH reporting | M3-09 | `docs/impl/DECISIONS.md`, `docs/spec/03-ux.md`, `lib/platform/cli_wrapper.dart`, `lib/state/settings_controller.dart`, `lib/state/app_services.dart`, `lib/ui/settings/settings_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M3 | AGENTS.md refresh (tracked again) + M3-10 isolation E2E on Linux | M3-10 | `AGENTS.md`, `docs/impl/STATUS.md`, `docs/impl/VERIFICATION.md`, `test/manual/isolation_e2e_linux_test.dart` |
| 2026-09-19 | M4 | S3 pip-uninstall spike; RECORD-based removal decision | S3 | `docs/impl/DECISIONS.md`, `docs/spec/06-integrations.md` |
| 2026-09-19 | M4 | D-037 addon catalog models, parser and cached client | M4-01 | `docs/impl/DECISIONS.md`, `lib/domain/addons/addon.dart`, `lib/data/catalog/addon_catalog*.dart`, `lib/state/app_services.dart`, `test/**` |
| 2026-09-19 | M4 | D-038 addon catalog controller and UI (search/filters/grid/detail) | M4-02 | `docs/impl/DECISIONS.md`, `lib/state/addons_controller.dart`, `lib/ui/addons/**`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M4 | Fix addon catalog download/parse directory mismatch | M4-02 | `lib/platform/downloader.dart`, `lib/data/catalog/addon_catalog.dart`, `test/data/addon_catalog_test.dart` |
| 2026-09-19 | M4 | Fix catalog search state after detail navigation | M4-02 | `lib/ui/addons/addons_view.dart`, `test/ui/addons_view_test.dart` |
| 2026-09-19 | M4 | Compact rounded outlined input theme; bordered dropdown filters | M4-09 | `docs/spec/03-ux.md`, `lib/app.dart`, `lib/ui/addons/addons_view.dart`, `test/ui/app_theme_test.dart` |
| 2026-09-19 | M4 | Multi-select checkable filter menu for addon content/installed filters | M4-10 | `docs/spec/03-ux.md`, `lib/state/addons_controller.dart`, `lib/ui/addons/addons_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M4 | D-039 addon install engine (safe extract, atomic Mod placement, DB row) | M4-03 | `docs/impl/DECISIONS.md`, `docs/spec/06-integrations.md`, `lib/platform/addon_installer.dart`, `lib/state/addons_controller.dart`, `lib/ui/addons/addons_view.dart`, `test/**` |
| 2026-09-19 | M4 | Profile detail Addons tab lists installed addons | M4-11 | `lib/state/profiles_controller.dart`, `lib/ui/profiles/profile_detail_view.dart`, `test/ui/profiles_view_test.dart` |
| 2026-09-19 | M4 | D-040 addon update detection, backups and removal | M4-04 | `docs/impl/DECISIONS.md`, `lib/state/addons_controller.dart`, `lib/ui/addons/addons_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M4 | D-041 requirements parser, consent and pip installation | M4-05, M4-06 | `docs/impl/DECISIONS.md`, `lib/domain/python/**`, `lib/platform/python_*.dart`, `lib/platform/pip_runner.dart`, `lib/state/addons_controller.dart`, `lib/ui/addons/**`, `test/**` |
| 2026-09-19 | M4 | D-042 Python packages tab and RECORD-based uninstall | M4-07 | `docs/impl/DECISIONS.md`, `lib/platform/python_uninstaller.dart`, `lib/state/python_controller.dart`, `lib/state/app_services.dart`, `lib/ui/profiles/profile_detail_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M5 | D-054 macro catalog install picks the profile in a dialog | Fix | `docs/impl/DECISIONS.md`, `lib/ui/macros/macros_view.dart`, `lib/l10n/**`, `test/ui/macros_view_test.dart` |
| 2026-09-19 | M5 | D-053 force FreeCAD `MacroPath` to `<profile>/Macros` at launch | Fix | `docs/impl/DECISIONS.md`, `docs/spec/04-architecture.md`, `docs/spec/06-integrations.md`, `lib/platform/freecad_preferences.dart`, `lib/state/profiles_controller.dart`, `test/platform/freecad_preferences_test.dart` |
| 2026-09-19 | M5 | D-052 macro directory corrected to `<profile>/Macros` | Fix | `docs/spec/04-architecture.md`, `docs/spec/06-integrations.md`, `docs/impl/DECISIONS.md`, `lib/domain/profiles/profile_paths.dart`, `lib/platform/macro_scanner.dart`, `lib/state/macros_controller.dart`, `lib/ui/macros/installed_macros.dart`, `test/**` |
| 2026-09-19 | M5 | D-051 profile detail Macros tab wiring (shared installed list, reconcile on mount) | M5-08 | `docs/impl/DECISIONS.md`, `lib/ui/macros/installed_macros.dart`, `lib/ui/macros/macros_view.dart`, `lib/ui/profiles/profile_detail_view.dart`, `test/ui/profiles_view_test.dart` |
| 2026-09-19 | M5 | D-050 config paths, snapshots and backup cap | M5-06 | `docs/impl/DECISIONS.md`, `lib/platform/config_snapshots.dart`, `lib/platform/file_actions.dart`, `lib/state/profiles_controller.dart`, `lib/state/app_services.dart`, `lib/ui/profiles/config_snapshots_view.dart`, `lib/ui/profiles/profile_detail_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M5 | D-049 macro scanner, schema v3 and installed-macro actions | M5-05 | `docs/impl/DECISIONS.md`, `lib/data/tables/macros.dart`, `lib/data/database.dart`, `lib/data/database.g.dart`, `lib/platform/macro_scanner.dart`, `lib/platform/macro_file_actions.dart`, `lib/state/macros_controller.dart`, `lib/state/app_services.dart`, `lib/ui/macros/**`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M5 | D-048 macro catalog client, installer and Macros screen | M5-04 | `docs/impl/DECISIONS.md`, `lib/domain/macros/**`, `lib/data/catalog/macro_catalog.dart`, `lib/data/daos/macros_dao.dart`, `lib/platform/macro_installer.dart`, `lib/platform/paths.dart`, `lib/state/macros_controller.dart`, `lib/state/app_services.dart`, `lib/ui/macros/**`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M5 | D-047 bundle JSON export/import with validation and unresolved handling | M5-03 | `docs/impl/DECISIONS.md`, `lib/domain/bundles/bundle_json.dart`, `lib/state/bundles_controller.dart`, `lib/ui/addons/collections_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M5 | D-046 bundle apply planner, sequential runner and preview dialog | M5-02 | `docs/impl/DECISIONS.md`, `lib/domain/addons/addon_update_rules.dart`, `lib/domain/bundles/bundle_planner.dart`, `lib/state/bundle_apply_controller.dart`, `lib/state/addons_controller.dart`, `lib/state/app_services.dart`, `lib/ui/addons/collections_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M5 | D-045 bundles controller + Collections tab (create/edit/items, profile seed) | M5-01 | `docs/impl/DECISIONS.md`, `lib/domain/bundles/bundle_rules.dart`, `lib/state/bundles_controller.dart`, `lib/state/app_services.dart`, `lib/data/daos/bundles_dao.dart`, `lib/ui/addons/collections_view.dart`, `lib/ui/addons/addons_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | S4 | D-044 macro catalog source: addons.freecad.org cache, format, placement and license handling | S4 | `docs/impl/DECISIONS.md`, `docs/spec/06-integrations.md` |
| 2026-09-19 | M4 | D-043 job queue (controller, cancel/retry, status bar + jobs dialog) and wiring for builds/addons/pip | M4-08 | `docs/impl/DECISIONS.md`, `docs/impl/TASKS.md`, `lib/domain/jobs/job_types.dart`, `lib/state/jobs_controller.dart`, `lib/state/*_controller.dart`, `lib/state/app_services.dart`, `lib/core/cancellation.dart`, `lib/platform/addon_installer.dart`, `lib/ui/jobs/jobs_dialog.dart`, `lib/ui/shell/app_shell.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-20 | M5 | D-055 profile manifest export/import (codec, controller, UI, cross-OS test); M5 complete | M5-07 | `docs/impl/DECISIONS.md`, `docs/spec/05-data-model.md`, `lib/domain/profiles/profile_manifest.dart`, `lib/state/profile_manifest_controller.dart`, `lib/state/python_controller.dart`, `lib/state/app_services.dart`, `lib/ui/profiles/profile_manifest_dialogs.dart`, `lib/ui/profiles/profiles_view.dart`, `lib/ui/profiles/config_snapshots_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-20 | Fix | Versions/Available install progress moved into the tile subtitle, fixing bottom overflow | Fix | `lib/ui/builds/builds_view.dart`, `test/ui/builds_view_test.dart` |
| 2026-09-20 | M6 | D-056 addon pinning per profile (schema v4, pin/unpin UI, update block, bundle skip, manifest) | M6-10 | `docs/impl/DECISIONS.md`, `docs/spec/02-requirements.md`, `docs/spec/03-ux.md`, `docs/spec/05-data-model.md`, `lib/data/**`, `lib/domain/addons/addon_update.dart`, `lib/domain/bundles/bundle_planner.dart`, `lib/domain/profiles/profile_manifest.dart`, `lib/state/**`, `lib/ui/**`, `lib/l10n/**`, `test/**` |
| 2026-09-20 | M6 | D-057 addon update checks + badges on all surfaces (UpdatesController, status-bar sheet, profile/addon badges, check action) | M6-01 | `docs/impl/DECISIONS.md`, `docs/impl/VERIFICATION.md`, `docs/spec/03-ux.md`, `lib/domain/addons/addon_update.dart`, `lib/state/updates_controller.dart`, `lib/state/app_services.dart`, `lib/ui/updates/**`, `lib/ui/shell/app_shell.dart`, `lib/ui/profiles/**`, `lib/ui/addons/addons_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-20 | M6 | D-058 build update checks + badges (stable, same kind, notify-only; per-kind timestamps) | M6-02 | `docs/impl/DECISIONS.md`, `docs/spec/03-ux.md`, `lib/domain/builds/build_update.dart`, `lib/state/updates_controller.dart`, `lib/state/app_services.dart`, `lib/ui/builds/builds_view.dart`, `lib/ui/updates/updates_summary_sheet.dart`, `lib/ui/updates/updates_status_chip.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-20 | M6 | D-059 desktop form style: label-left `FormRow`, 4 px outlined inputs, migrated dialogs/inline forms | M6-11 | `docs/impl/DECISIONS.md`, `docs/spec/03-ux.md`, `lib/app.dart`, `lib/ui/widgets/form_row.dart`, `lib/ui/profiles/**`, `lib/ui/builds/builds_view.dart`, `lib/ui/addons/**`, `lib/l10n/**`, `test/**` |
| 2026-09-20 | M6 | D-060 batch addon updates: pre-checked per-item toggles, sequential job-queue run, progress + retry failed | M6-03 | `docs/impl/DECISIONS.md`, `lib/domain/addons/addon_update.dart`, `lib/state/updates_controller.dart`, `lib/ui/updates/updates_summary_sheet.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-20 | M6 | UI polish: shared CompactBadge/CompactDropdown, catalog icons on installed addons, branch-selection and layout fixes, label column 195 px (D-059), FreeCAD icon font | Fix | `docs/impl/DECISIONS.md`, `docs/impl/STATUS.md`, `lib/ui/**`, `lib/state/addons_controller.dart`, `lib/data/catalog/addon_catalog.dart`, `lib/ui/icons.dart`, `test/**` |
| 2026-09-20 | M6 | D-061 settings screen (persisted theme/cadence/log level, startup cadence check) and D-062 `--console` with `--version` | M6-04, Fix | `docs/impl/DECISIONS.md`, `docs/impl/TASKS.md`, `docs/impl/STATUS.md`, `lib/domain/settings/**`, `lib/state/settings_controller.dart`, `lib/state/updates_controller.dart`, `lib/state/app_services.dart`, `lib/app.dart`, `lib/main.dart`, `lib/domain/profiles/launch_plan.dart`, `lib/ui/settings/**`, `lib/ui/shell/app_shell.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-20 | M6 | D-063 cache management: per-category sizes/clear, retention pruning, Cache card in Settings | M6-05 | `docs/impl/DECISIONS.md`, `docs/impl/TASKS.md`, `docs/impl/STATUS.md`, `lib/domain/cache/cache_types.dart`, `lib/domain/settings/app_settings.dart`, `lib/platform/cache_service.dart`, `lib/state/cache_controller.dart`, `lib/state/app_services.dart`, `lib/state/settings_controller.dart`, `lib/ui/settings/settings_view.dart`, `lib/ui/shell/app_shell.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-20 | M6 | D-064 debug bundle export: redacted logs + DB-free inventory + diagnostics, Settings export row | M6-06 | `docs/impl/DECISIONS.md`, `docs/impl/TASKS.md`, `docs/impl/STATUS.md`, `lib/platform/debug_bundle.dart`, `lib/state/debug_bundle_controller.dart`, `lib/state/app_services.dart`, `lib/data/daos/installed_addons_dao.dart`, `lib/ui/settings/settings_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-20 | M6 | M6-07 state coverage pass: per-screen matrix in VERIFICATION.md, live checks, addon-picker catalog-unavailable fix | M6-07 | `docs/impl/VERIFICATION.md`, `docs/impl/TASKS.md`, `docs/impl/STATUS.md`, `lib/ui/addons/collections_view.dart`, `test/ui/collections_view_test.dart` |
| 2026-09-20 | M6 | D-065 keyboard shortcuts (spec 03 §4) + a11y guideline tests/fixes | M6-08 | `docs/impl/DECISIONS.md`, `docs/impl/TASKS.md`, `docs/impl/STATUS.md`, `docs/impl/VERIFICATION.md`, `lib/ui/shell/**`, `lib/ui/addons/addons_view.dart`, `lib/ui/macros/macros_view.dart`, `lib/ui/builds/builds_view.dart`, `lib/ui/profiles/profiles_view.dart`, `lib/ui/settings/settings_view.dart`, `test/**` |
| 2026-09-20 | M7 | D-066 performance pass: startup `perf` logs, off-thread catalog parsing, measured warm startup 553–561 ms | M6-09 | `docs/impl/DECISIONS.md`, `docs/impl/TASKS.md`, `docs/impl/STATUS.md`, `docs/impl/VERIFICATION.md`, `lib/main.dart`, `lib/core/log.dart`, `lib/data/catalog/*.dart`, `lib/state/*catalog*`, `test/**` |
| 2026-09-21 | M7 | D-067 Home dashboard: stats tiles, last-used launch, update check, cached RSS/Atom news feed + `news_feed_url` setting, first-run checklist, `ShellController` | M6-12 | `docs/impl/DECISIONS.md`, `docs/impl/TASKS.md`, `docs/impl/STATUS.md`, `docs/impl/VERIFICATION.md`, `lib/domain/news/**`, `lib/data/catalog/news_feed.dart`, `lib/state/{shell,news}_controller.dart`, `lib/state/{app_services,settings_controller}.dart`, `lib/ui/home/home_view.dart`, `lib/ui/settings/settings_view.dart`, `lib/platform/{paths,cache_service}.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-21 | M7 | D-068 reproducible AppImage build spike: packaging script, pinned tools, deterministic hashes, clean-distro checks, release workflow | S5 | `docs/impl/DECISIONS.md`, `docs/impl/TASKS.md`, `docs/impl/STATUS.md`, `packaging/appimage/**`, `.github/workflows/release-appimage.yml` |
| 2026-09-21 | Fix | Open-folder/reveal buttons: `FileActions` parent-env inheritance + `FileActionException`, failure snackbars in Settings/Config, unit tests | Fix | `lib/platform/file_actions.dart`, `lib/ui/settings/settings_view.dart`, `lib/ui/profiles/config_snapshots_view.dart`, `lib/l10n/**`, `test/platform/file_actions_test.dart`, `docs/impl/{STATUS,VERIFICATION}.md` |
| 2026-09-21 | R1 | D-069 relabel installed builds: schema v5 `builds.label`, display extension on all surfaces, rename dialog + rules/controller/DAO, tests; migration verified on the real dev DB | R-01 | `docs/impl/{DECISIONS,TASKS,STATUS,VERIFICATION}.md`, `docs/spec/{03-ux,05-data-model}.md`, `AGENTS.md`, `lib/data/{database,tables/builds,daos/builds_dao}.dart`, `lib/domain/builds/build_label_rules.dart`, `lib/state/{builds_controller,debug_bundle_controller}.dart`, `lib/ui/builds/builds_view.dart`, `lib/ui/profiles/**`, `lib/ui/home/home_view.dart`, `lib/cli/cli.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-21 | R2 | D-070 original launcher icon: editable master SVG + render script, owner's rocket design rendered to the 512/256 AppImage/desktop PNGs | R-02 | `docs/impl/{DECISIONS,TASKS,STATUS}.md`, `docs/spec/{07-distribution,README}.md`, `packaging/appimage/{freecad-launcher.svg,render_icons.sh,freecad-launcher.png,freecad-launcher-256.png}` |
| 2026-09-21 | M7 | D-071 AppImage productionization: version/tag check, CI Flutter pin, placeholder guard, full hicolor icon set, workflow checksum + `--version` smoke test; local build and clean ubuntu/fedora container verification | M7-01 | `docs/impl/{DECISIONS,TASKS,STATUS,VERIFICATION}.md`, `packaging/check_version.sh`, `packaging/appimage/{build_appimage.sh,render_icons.sh,freecad-launcher-{16,32,48,64,128,256,512}.png}`, `.github/workflows/{ci,release-appimage}.yml` |
| 2026-09-24 | planning | D-072: Linux-first completion; CI, release workflow and Windows/macOS deployment moved to deferred phase M8 | — | `docs/impl/{TASKS,STATUS,DECISIONS,VERIFICATION}.md`, `docs/spec/{08-roadmap,09-open-questions}.md` |
| 2026-09-24 | M7 | M7-06 Linux manual functional pass: real 1.1.3 install, custom executable import + Python fallback dialog, profile create/edit/GUI launch with running badge/log/exit tracking; `VERIFICATION.md` §4 Linux column filled; findings filed R-03..R-07; dev data root restored | M7-06 | `docs/impl/{TASKS,STATUS,VERIFICATION}.md` |
| 2026-09-24 | M7 | R-03..R-07 fixes (Available auto-load, in-place remove wording, duplicate custom import, Choose Python picker, download completion/truncation); 6 tests, live re-check, dev data restored | R-03..R-07 | `lib/{platform/downloader,data/daos/builds_dao,state/builds_controller,ui/builds/builds_view}.dart`, `lib/l10n/**`, `test/**`, `docs/impl/{TASKS,STATUS}.md` |
| 2026-09-24 | M7 | M7-03 licensing (LICENSE, SPDX headers, generated notices, AppImage doc files) and M7-05 → M8-05 deferral (D-073, D-074) | M7-03, M7-05 | `LICENSE`, `THIRD_PARTY_NOTICES.md`, `tool/generate_third_party_notices.dart`, `packaging/appimage/build_appimage.sh`, `lib/**`, `test/**`, `docs/impl/**` |
| 2026-09-24 | M7 | M7-04 README + user guide with 5 screenshots; M7 (Linux v0.1) complete | M7-04 | `README.md`, `docs/user-guide.md`, `docs/images/**` |
| 2026-09-27 | R | R-08 "Open profile folder" in the profile detail header (shared helper, widget test, live hot-reload check) | R-08 | `lib/ui/profiles/profile_actions.dart`, `lib/ui/profiles/profile_detail_view.dart`, `test/ui/profiles_view_test.dart`, `docs/impl/{TASKS,STATUS}.md` |
| 2026-09-30 | R3 | D-075/R-09: profile launches no longer override `HOME`; `<profile>/home` dropped from the layout; unit suite green (500) + real 1.0.2 isolation E2E re-run | R-09 | `docs/impl/{DECISIONS,TASKS,STATUS,VERIFICATION}.md`, `docs/spec/{04-architecture,05-data-model}.md`, `docs/user-guide.md`, `lib/domain/profiles/{launch_environment,profile_paths}.dart`, `test/**` |
| 2026-09-30 | R4 | D-076/R-10 macro catalog icons (two-level cache, catalog+installed, prune) + UI polish (filter icon, folder button alignment, Macros defaults to Catalog); 505 tests green, live dev-app check | R-10 | `docs/impl/{DECISIONS,TASKS,STATUS}.md`, `docs/spec/03-ux.md`, `docs/user-guide.md`, `lib/platform/{paths,macro_icon_cache}.dart`, `lib/state/{app_services,macros_controller}.dart`, `lib/ui/macros/**`, `lib/ui/addons/addons_view.dart`, `lib/ui/profiles/config_snapshots_view.dart`, `test/**` |
| 2026-09-30 | R5 | Home news excerpts (2-line, 180-char word-boundary truncation) with widget/domain tests; 508 tests green, live check | — | `lib/domain/news/news_item.dart`, `lib/ui/home/home_view.dart`, `test/domain/news_item_test.dart`, `test/ui/home_view_test.dart`, `docs/user-guide.md`, `docs/impl/STATUS.md` |
| 2026-09-30 | R6 | Weekly builds analyzed and planned (D-077): dated `weekly-YYYY.MM.DD` only, Available channel filter with dev warning, notify-only update checks, apply deferred to B-02; tasks B-01a..B-01d recorded | — | `docs/impl/{DECISIONS,TASKS,STATUS}.md` |
| 2026-09-30 | R7 | CalVer transition verified against FEP-0003 (`YY.N` three/year, patches `YY.N.P`, first 26.3 branched 2026-09-30, RCs ignored until final): D-078, spec 06 §1.3/§1.5, FR-1.7 and backlog task B-14 recorded | — | `docs/spec/{02-requirements,06-integrations}.md`, `docs/impl/{DECISIONS,TASKS,STATUS}.md` |
| 2026-09-30 | R8 | B-01 weekly builds (D-077) implemented: `weeklyBuilds` catalog signal, Available channel filter + dev warning, notify-only weekly update badges, humanized weekly labels; real `weekly-2026.09.30` install verified (checksum, Python 3.13 probe, `--version` = 26.3.0); docs updated | B-01a..B-01d | `lib/state/{builds_controller,updates_controller}.dart`, `lib/ui/builds/builds_view.dart`, `lib/ui/updates/updates_summary_sheet.dart`, `lib/ui/widgets/build_version_label.dart`, `lib/l10n/app_en.arb`, `lib/l10n/gen/**`, `test/**`, `docs/{spec/03-ux.md,user-guide.md}`, `docs/impl/{TASKS,STATUS,VERIFICATION}.md` |
| 2026-09-30 | R9 | Cap the weekly list at the latest 52 (one year), newest first (`BuildsController.weeklyBuildLimit`); controller test + spec/user-guide wording | B-01 | `lib/state/builds_controller.dart`, `test/state/builds_controller_test.dart`, `docs/spec/03-ux.md`, `docs/user-guide.md`, `docs/impl/STATUS.md` |
| 2026-09-30 | R10 | Home news card extended from 5 to 10 posts (`_NewsCard.maxItems`); widget test asserts the limit | — | `lib/ui/home/home_view.dart`, `test/ui/home_view_test.dart`, `docs/impl/STATUS.md` |
| 2026-09-30 | R11 | D-079 copyright notices: `SPDX-FileCopyrightText` in 240 SPDX-tagged files, README/About/notices holder line, notices regenerated; 516 tests green | R-11 | `docs/impl/{DECISIONS,TASKS,STATUS}.md`, `README.md`, `THIRD_PARTY_NOTICES.md`, `tool/generate_third_party_notices.dart`, `lib/l10n/app_en.arb`, `lib/ui/settings/settings_view.dart`, `lib/**`, `test/**`, `packaging/**` |
| 2026-09-30 | R12 | D-080 About dialog: bundled official FreeCAD logo, FPA trademark notice and independent-project statement, opened from Settings › About; README/notices wording updated; 517 tests green, live check | R-12 | `docs/impl/{DECISIONS,TASKS,STATUS}.md`, `README.md`, `THIRD_PARTY_NOTICES.md`, `tool/generate_third_party_notices.dart`, `assets/images/freecad-logo.svg`, `pubspec.yaml`, `lib/ui/settings/{about_dialog.dart,settings_view.dart}`, `lib/l10n/**`, `test/ui/settings_view_test.dart` |
| 2026-09-30 | R13 | D-081 GitHub publishing prep: repo `mnesarco/FreeCAD-Launcher`, `v2` renamed `devel` (public default), CI on devel/main + notices drift check, manual Release AppImage workflow with optional GitHub Release, README/user-guide Releases links, removed 4 MB prototype artifact | M8-01 | `.github/workflows/{ci,release-appimage}.yml`, `AGENTS.md`, `README.md`, `docs/spec/07-distribution.md`, `docs/user-guide.md`, `docs/impl/{DECISIONS,TASKS,STATUS}.md`, `addon_catalog_cache.json` |
| 2026-10-01 | R14 | Published to `mnesarco/FreeCAD-Launcher`: pushed `devel`, first CI run (Linux green; empty `assets/macros/` fixed), Windows/macOS test gating (**D-082**, M8-06) | M8-02 | `docs/impl/{DECISIONS,TASKS,STATUS}.md`, `.github/workflows/ci.yml`, `pubspec.yaml` |
| 2026-10-01 | R15 | CI fully green (ubuntu/macOS/windows); macOS job then removed from the matrix (**D-083**, returns with M8-04); Linux+Windows remain with Linux tests and both release builds | M8-02 | `.github/workflows/ci.yml`, `docs/impl/{DECISIONS,TASKS,STATUS}.md` |
| 2026-10-01 | R16 | Manual AppImage workflow: renamed to `appimage-release.yml` (GitHub refused the old path), fixed missing GTK/ninja deps and pinned the type-2 runtime to the dated `20251108` release (**D-084**) | M8-01 | `.github/workflows/appimage-release.yml`, `packaging/appimage/build_appimage.sh`, `README.md`, `docs/impl/{DECISIONS,STATUS,VERIFICATION}.md` |
| 2026-10-01 | R17 | First CI-built AppImage from GitHub verified: run 36810294004 built/uploaded `FreeCADLauncher-0.1.0-x86_64.AppImage` (29.9 MB) + sha256 + zsync; artifact re-verified locally; M8-02 DONE | M8-01, M8-02 | `docs/impl/{TASKS,STATUS,VERIFICATION}.md` |
| 2026-10-01 | R18 | First release: `v0.1.0` pre-release published from the manual workflow (run 36812429637) with AppImage + sha256 + zsync; M8-01 DONE; tag fetched locally | M8-01 | `docs/impl/{TASKS,STATUS,VERIFICATION}.md` |
| 2026-10-01 | R19 | History cleanup: dropped the temporary `ping`/`bisect` CI commits with `git-filter-repo` (tree unchanged), force-pushed `devel` and moved `v0.1.0` to the rewritten commit; CI and the tag-path release workflow re-ran green (runs 36815947311 / 36815948224) | — | `docs/impl/STATUS.md` |
| 2026-10-01 | R20 | README accuracy pass: intro clarified (multiple builds, each backing many profiles), Stable\|Weekly channel documented in Features/Quick start/Updates, all five screenshots recaptured from the current build (Available/Stable for Versions), AI-assistance disclosure added | — | `README.md`, `docs/images/*.jpg`, `docs/impl/STATUS.md`, `docs/impl/VERIFICATION.md` |
| 2026-10-01 | R21 | B-10 planning: custom addon installs (repo URL + branch, local zip/tar, dev symlink) written up with owner-confirmed choices; B-10 expanded into B-10a..B-10e; no code | B-10 | `docs/impl/PLAN-B10-custom-addons.md`, `docs/impl/TASKS.md`, `docs/impl/STATUS.md` |
| 2026-10-01 | R22 | B-10 implementation (uncommitted pending review): schema v6 source/sourcePath, domain helpers, installer prepare/commit + linkDirectory, custom install/update/reinstall + conflicts + pre-placement requirements consent, Addons Custom tab with install-in-another-profile action, manifest source skip, D-085..D-088, tests, live Nxt repo/zip/symlink installs and cross-profile copy verified | B-10a..B-10f | `lib/domain/addons/{addon_source,package_xml,addon_id_rules,repository_archive}.dart`, `lib/platform/{addon_installer,addon_manifest_reader}.dart`, `lib/state/{addons_controller,updates_controller,profile_manifest_controller}.dart`, `lib/ui/addons/{addons_view,custom_addons_view}.dart`, `lib/ui/profiles/profile_manifest_dialogs.dart`, `lib/{data,domain,ui,l10n}/**`, `test/**`, `docs/{spec/02-requirements,spec/03-ux,spec/05-data-model,spec/06-integrations,user-guide}.md`, `docs/impl/{DECISIONS,TASKS,STATUS,VERIFICATION}.md` |

| 2026-10-01 | R23 | Addon enable/disable per profile (B-15a, D-089): `ADDON_DISABLED` toggle on Profile → Addons rows, state derived from disk, disabled badge/dim; controller + widget tests and a live managed/dev-link check | B-15a | `lib/state/addons_controller.dart`, `lib/ui/profiles/profile_detail_view.dart`, `lib/l10n/app_en.arb`, `lib/l10n/gen/**`, `test/state/addons_controller_test.dart`, `test/ui/profiles_view_test.dart`, `docs/{spec/02-requirements,spec/03-ux,user-guide}.md`, `docs/impl/{DECISIONS,TASKS,STATUS,VERIFICATION}.md` |

| 2026-10-01 | R24 | Version bump to 0.2.0 (`pubspec.yaml`, `core/constants.dart`) + README/spec/user-guide current-version labels and debug-bundle test | — | `pubspec.yaml`, `lib/core/constants.dart`, `test/state/debug_bundle_controller_test.dart`, `README.md`, `docs/spec/03-ux.md`, `docs/user-guide.md`, `docs/impl/STATUS.md` |
| 2026-10-01 | R25 | R-13 launch-log link (D-090): Profile → Overview `Log` row opens the launch log with the system default text editor via `FileActions.open`, localized label/tooltip, failure snackbar; widget test asserts `xdg-open <log>`; 587 tests green, analyze clean | R-13 | `lib/ui/profiles/{profile_detail_view,profile_actions}.dart`, `lib/l10n/app_en.arb`, `lib/l10n/gen/**`, `test/ui/profiles_view_test.dart`, `docs/impl/{DECISIONS,TASKS,STATUS,VERIFICATION}.md` |
| 2026-10-01 | R26 | Windows release plan saved (`PLAN-M8-windows-release.md`); **D-091** (unsigned portable zip, OQ-1 Windows resolved) and **D-092** (MacroPath `/`); M8-06 fixes: debug-bundle zip separators, log-sink close before exitCode, test portability (path joins, host platform, per-platform openers, case-insensitive fixture names, canonical temp paths); Windows tests re-enabled in `ci.yml`; M8-03 bundle: 7zr+license in CMake, 7-Zip notices, rocket `.ico`, `packaging/windows/build_portable.ps1`; release workflow now has a Windows job + shared publisher; 587 tests green, analyze clean; committed (`005a6c3`, `1c12218`) | M8-03, M8-06 | `docs/impl/PLAN-M8-windows-release.md`, `docs/impl/{DECISIONS,TASKS,STATUS,VERIFICATION}.md`, `docs/spec/{07-distribution,09-open-questions}.md`, `README.md`, `docs/user-guide.md`, `.github/workflows/{ci,appimage-release}.yml`, `windows/CMakeLists.txt`, `windows/runner/resources/app_icon.ico`, `packaging/windows/**`, `tool/generate_third_party_notices.dart`, `THIRD_PARTY_NOTICES.md`, `lib/{platform/debug_bundle,platform/freecad_preferences,state/profiles_controller}.dart`, `test/**` |
| 2026-10-01 | R27 | **M8-06 DONE**: CI run 36897077869 green on Ubuntu + Windows with `flutter test` on both (Windows 576 passed / 14 skipped); second iteration portabilized the remaining 6 failures (host-platform wrapper PATH, normalized MacroPath expectations in prefs/manifest tests, larger surface for the launch-log widget test) and moved `actions/checkout` to v5 (Node 24, deprecation annotation gone). **M8-03 CI pipeline verified**: manual Release run 36898044793 built the Windows job (portable zip, 7zr hash, `--version` smoke test) and the AppImage; `publish` skipped as requested. Artifact downloaded and verified locally: `FreeCADLauncher-0.2.0-windows-x86_64.zip` 15.4 MB, POSIX entry names, `sha256sum -c` OK, `7zr.exe` = `ad4c82fa…`, license/notices/README present | M8-06, M8-03 | `.github/workflows/{ci,appimage-release}.yml`, `test/{platform/cli_wrapper_test,platform/freecad_preferences_test,state/profile_manifest_controller_test,ui/profiles_view_test}.dart`, `docs/impl/{TASKS,STATUS,VERIFICATION}.md` |
| 2026-10-01 | R28 | Windows VM first run: catalogs failed with an opaque `CatalogUnavailableException` caused by a machine-side network block (firewall/AV; Linux build works). Hardening per **D-093**: catalog exception `toString()` includes the cause, catalog load failures are logged with stack traces, `DiagnosticsService` gained a **Network** check (GitHub API + `addons.freecad.org` + news feed, injectable probe, 5 s timeout, not-applicable without probe), Settings label/l10n, README/user-guide firewall + proxy-limitation docs. 591 tests green, analyze clean | M8-03, D-093 | `lib/platform/diagnostics.dart`, `lib/state/{app_services,builds_controller,addons_controller,macros_controller}.dart`, `lib/data/catalog/{releases_catalog,addon_catalog,macro_catalog,news_feed}.dart`, `lib/ui/settings/settings_view.dart`, `lib/l10n/**`, `test/platform/diagnostics_test.dart`, `docs/user-guide.md`, `README.md`, `docs/impl/{DECISIONS,STATUS}.md` |
| 2026-10-01 | R29 | Logs revealed the real cause: `CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate` (Dart uses Mozilla roots on Windows, ignoring the Windows store, so the VM's TLS-inspection/AV root failed). Fix per **D-094**: `lib/platform/tls_trust.dart` loads the Windows `ROOT`/`CA` stores via `crypt32` FFI and optionally `<data dir>/ca-bundle.pem` into `SecurityContext.defaultContext` at startup (non-fatal, logged with counts; no insecure bypass); `DownloadException` now shows its cause; `ffi` dependency added; Windows-only CI test validates store loading; user guide/README updated. 595 tests green on Linux, analyze clean | M8-03, D-094 | `lib/platform/tls_trust.dart`, `lib/main.dart`, `lib/platform/downloader.dart`, `pubspec.{yaml,lock}`, `test/platform/tls_trust_test.dart`, `test/fixtures/test_ca.pem`, `docs/user-guide.md`, `README.md`, `docs/impl/{DECISIONS,STATUS,PLAN-M8-windows-release}.md` |
| 2026-10-01 | R30 | VM still failed after R29 with only `24 system` certificates: `CertOpenSystemStoreW` reads the current-user stores only, while the TLS-inspection root is machine-wide. Switched to `CertOpenStore` with `CERT_SYSTEM_STORE_LOCAL_MACHINE` + `CERT_SYSTEM_STORE_CURRENT_USER` for `ROOT`/`CA` (deduplicated, machine first); Windows-only test raised to `>40` certificates and green in CI (run 36907956427), proving the machine store is loaded. Rebuilt artifact run 36907901612 (15.4 MB, checksum OK) | M8-03, D-094 | `lib/platform/tls_trust.dart`, `test/platform/tls_trust_test.dart`, `docs/impl/{DECISIONS,STATUS}.md` |
| 2026-10-01 | R31 | Clean Windows machine (different from the TLS-inspection VM) with the D-094 artifact from run 36907901612: app started, all catalogs loaded and downloads completed. Owner accepted this as the M8-03 clean-machine verification, so the TLS-inspection VM is no longer a blocker (AV/TLS caveat stays documented). Remaining M8-03 gate: exercise the GitHub Release publish path with a `v0.2.0` prerelease; the other smoke rows (`.7z` install, probe, profiles, addons/pip/macros, wrapper, reveal) were not exercised | M8-03, D-094 | `docs/impl/{STATUS,VERIFICATION,TASKS,PLAN-M8-windows-release}.md` |
| 2026-10-01 | R32 | First real Windows `.7z` install (1.1.3) failed with `FileSystemException` on the staging path: catalog build IDs contain `:` and were used as directory names. **D-095/R-14**: shared `safePathSegment` makes dynamic path segments portable ASCII; applied to build dirs, launch logs, macro file/icon names and addon backups; helper + `buildDir` tests (POSIX + Windows contexts). 604 tests green, analyze clean; artifact rebuild + Windows retest pending | R-14, M8-03 | `lib/core/path_segments.dart`, `lib/platform/paths.dart`, `lib/state/{profiles,addons}_controller.dart`, `lib/domain/macros/macro_catalog_entry.dart`, `test/core/path_segments_test.dart`, `test/platform/paths_test.dart`, `docs/impl/{DECISIONS,TASKS,STATUS,VERIFICATION,PLAN-M8-windows-release}.md` |
| 2026-10-01 | R33 | R-14 committed and pushed (`031cc0e`); manual Release run 36937972986 green (windows + appimage jobs; publish skipped as requested). `windows-portable` artifact downloaded to `~/Downloads/freecad-launcher-windows-r36937972986/` (15.4 MB, `sha256sum -c` OK); Windows install retest pending | R-14, M8-03 | `docs/impl/{STATUS,PLAN-M8-windows-release,TASKS}.md` |
| 2026-10-01 | R35 | R-15 retest log: 7zr extraction OK, then `PathNotFoundException` from the recursive size walk on a FreeCAD path over the 260-char Windows limit. **R-17**: shared tolerant `directorySize` (per-directory error handling) used by `BuildInstaller` and `ProfilesController`; 3 new tests. 609 tests green, analyze clean; artifact rebuild + Windows retest pending | R-17, M8-03 | `lib/platform/directory_size.dart`, `lib/platform/build_installer.dart`, `lib/state/profiles_controller.dart`, `test/platform/directory_size_test.dart`, `docs/impl/{TASKS,STATUS,VERIFICATION,PLAN-M8-windows-release}.md` |
| 2026-10-01 | R36 | **M8-03 clean-machine verification passed**: owner ran the full Windows smoke matrix with the R-17 artifact (run 36941684639) — 1.1.3 `.7z` install + Python probe, two isolated profiles + launch, catalog/pip/custom addons, enable/disable, macros, manifest, offline catalog, CLI wrapper, reveal. `VERIFICATION.md` §2/§4 Windows column filled; M8-03 only needs the `v0.2.0` prerelease publish | M8-03 | `docs/impl/{VERIFICATION,STATUS,TASKS,PLAN-M8-windows-release}.md` |
| 2026-10-01 | R37 | **v0.3.0 released** (**D-097**): version bump to 0.3.0, workflow renamed to `release.yml`, tag `v0.3.0` pushed → run 36943644212 (windows + appimage + publish all green); GitHub Release created with `FreeCADLauncher-0.3.0-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.3.0-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified from the downloaded release. **M8-03 DONE**; M8-04/M8-05 remain | M8-03, D-097 | `pubspec.yaml`, `lib/core/constants.dart`, `.github/workflows/{appimage-release.yml => release.yml}`, `README.md`, `docs/spec/03-ux.md`, `test/state/debug_bundle_controller_test.dart`, `docs/impl/{DECISIONS,TASKS,STATUS,VERIFICATION,PLAN-M8-windows-release}.md` |
| 2026-10-01 | R38 | README/user-guide Windows coverage: supported-platform line, Windows checksum command, data root (`%APPDATA%\FreeCAD Launcher contributors\FreeCAD Launcher`), CLI wrapper path/`freecad-launcher.cmd`, Windows local build and troubleshooting entries; user guide limitations retitled v0.3 | M8-03 | `README.md`, `docs/user-guide.md`, `docs/impl/STATUS.md` |
| 2026-10-01 | R39 | Two Linux regressions from the v0.3.0 AppImage: weekly install failed with `ENOTCONN` deleting the probe dir (FUSE mount inside probe `TMPDIR` still tearing down) → **R-18** best-effort cleanup with retries; "open logs folder" opened the browser because openers inherited the AppImage `LD_LIBRARY_PATH` (system `gio` undefined symbol) → **R-19/D-098** `openerEnvironment` scrub. Reproduced the `gio` failure locally with the AppImage libs; 611 tests green, analyze clean; artifact retest pending | R-18, R-19, D-098 | `lib/platform/python_probe.dart`, `lib/platform/file_actions.dart`, `test/platform/file_actions_test.dart`, `docs/impl/{DECISIONS,TASKS,STATUS}.md` |
| 2026-10-01 | R40 | **Linux regression audit** of the Windows-support changes (baseline `c0a00b9`): every shared-code change reviewed; only D-095 had a real Linux regression — pre-D-095 managed builds resolved to a sanitized (missing) directory, so they were reported `missing` and orphaned on remove → **R-20/D-099** `existingBuildDir`/`buildDirCandidates` fallback in status/reconcile/verify/remove and Python resolution. R-18 verified against the real `weekly-2026.10.01` AppImage (Python 3.13 detected, probe dir removed); D-096 is Windows-guarded; opener env equivalent outside an AppImage; tls_trust is Windows-guarded plus the optional `ca-bundle.pem`; directorySize values unchanged. Filed **R-21** (custom AppImage symlink dirs not cleaned on remove — pre-existing at `c0a00b9`). 613 tests green, analyze clean | R-18..R-21, D-099 | `lib/platform/paths.dart`, `lib/state/{builds,python,addons}_controller.dart`, `test/platform/paths_test.dart`, `test/state/builds_controller_test.dart`, `test/data/test_fixtures.dart`, `docs/impl/{DECISIONS,TASKS,STATUS}.md` |
| 2026-10-01 | R41 | **v0.4.0 pre-release published** (manual `create_release=true`, tag `v0.4.0`, `prerelease=true`, run 36947395864; publish job green): `FreeCADLauncher-0.4.0-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.4.0-x86_64.AppImage` + `.sha256` + `.zsync`, both `sha256sum -c` verified after download; tag at `b8e17f7` includes the R-18..R-20 Linux fixes. Version bumped 0.3.0 → 0.4.0 | M8-03 | `lib/core/constants.dart`, `pubspec.yaml`, `README.md`, `docs/spec/{03-ux,07-distribution}.md`, `docs/impl/{VERIFICATION,TASKS,STATUS,PLAN-M8-windows-release}.md` |
| 2026-10-01 | R42 | Owner withdrew all releases before `v0.4.0`; `v0.4.0` is the only available release and the `0.4.x` line continues (**D-100**). README/spec/plan/VERIFICATION/STATUS updated; tags `v0.1.0`–`v0.3.0` remain for history | D-100 | `README.md`, `docs/spec/07-distribution.md`, `docs/impl/{DECISIONS,VERIFICATION,STATUS,PLAN-M8-windows-release}.md` |
| 2026-10-01 | R43 | Planning: dependency-upgrade plan saved ([PLAN-dependency-upgrades.md](PLAN-dependency-upgrades.md), backlog **B-16**) with the `pub outdated` snapshot, per-package risk table, phased patch/minor → majors process, packaging verification and rollback rules; no code change | B-16 | `docs/impl/{PLAN-dependency-upgrades,TASKS,STATUS}.md` |
| 2026-10-01 | R44 | Python-tab package install crashed the UI: the dialog's `TextEditingController` was disposed when `showDialog` returned while the closing route still rebuilt the `TextField` (use-after-dispose → `InheritedElement.debugDeactivated`/`_dependentsIsEmpty` assert). **R-22**: controller moved into a `_PythonInstallDialog` StatefulWidget. Reproduced live with a temporary Flutter driver entrypoint (installs `six`); after the fix the flow completes with the success snackbar and no exceptions; regression widget test fails on the old code. 614 tests green, analyze clean; temporary driver files/pubspec reverted | R-22 | `lib/ui/profiles/profile_detail_view.dart`, `test/ui/profiles_view_test.dart`, `docs/impl/{TASKS,STATUS}.md` |
| 2026-10-01 | R45 | **v0.4.1 pre-release published** (manual `create_release=true`, tag `v0.4.1`, run 36955018205; publish job green): `FreeCADLauncher-0.4.1-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.4.1-x86_64.AppImage` + `.sha256` + `.zsync`, both `sha256sum -c` verified after download; tag at `0c61e25` includes the R-22 fix. Version bumped 0.4.0 → 0.4.1; README/spec/VERIFICATION/STATUS updated | R-22, M8-03 | `lib/core/constants.dart`, `pubspec.yaml`, `README.md`, `docs/spec/{03-ux,07-distribution}.md`, `docs/impl/{VERIFICATION,TASKS,STATUS}.md` |

| 2026-10-02 | R46 | Signals 7.1 crash root-caused (**R-23**): `refreshConfigSnapshots` wrote during `didChangeDependencies`; 7.1 effects call `markNeedsBuild()` synchronously (6.x deferred to `endOfFrame`) and implicit `SignalWidget`/`SignalStatefulWidget` fail identically in the same `TabBarView` structure, so `.watch()` is not the cause. Fix: post-frame refresh at both Config/Backups mounts + widget regression test (fails on the old code). Also wrote the B-17 implicit-tracking migration plan (**D-101**): 127 sites / 34 classes, API mapping, traps, per-batch process. 615 tests green, analyze unchanged (127 B-17 deprecations) | R-23, B-17, D-101 | `docs/impl/PLAN-signals-implicit-migration.md`, `docs/impl/{DECISIONS,TASKS,STATUS,PLAN-dependency-upgrades}.md`, `lib/ui/profiles/config_snapshots_view.dart`, `test/ui/config_snapshots_view_test.dart` |

| 2026-10-02 | R47 | **B-16 signals group landed**: `[dep] upgrade signals_flutter` 6.3.1 → 7.1.0 (`2b2cdf7`, pubspec/lock only) after dropping `signals_lint` — latest 7.1.0 caps `analyzer <14` and would downgrade analyzer 14.4.0→13.3.0 / `_fe_analyzer_shared` 108→103 / `source_gen` 4.3.0→4.2.4 (**D-102**). Verified codegen fresh, 615 tests green, analyze only the 127 B-17 `.watch` deprecations, and a live xdotool/MCP click-through of Home, Profiles + all six detail tabs (including R-23 Config → Backups), Versions ×3, Addons ×3, Macros ×2 and Settings with zero runtime errors and a successful hot reload | B-16, D-102 | `pubspec.{yaml,lock}`, `docs/impl/{DECISIONS,PLAN-signals-implicit-migration,TASKS,STATUS}.md` |

| 2026-10-02 | R48 | B-16 PR prepared on `deps-upgrade-1`: xml 7 `XmlName.parts` cleanup (`6a2c08f`), branch pushed, draft PR [#2](https://github.com/mnesarco/FreeCAD-Launcher/pull/2) opened. First CI run (37044201129) failed at `pub get` — drift 2.35.1 needs `meta ^1.18.3` while the Flutter 3.41.4 pin ships 1.17.0 — so CI/release moved to Flutter 3.47.6 (`d0f5c1a`, **D-103**, supersedes D-071's pin clause); re-run pending | B-16, D-103 | `.github/workflows/{ci,release}.yml`, `lib/platform/freecad_preferences.dart`, `docs/{user-guide,impl/{DECISIONS,PLAN-dependency-upgrades,TASKS,STATUS}}.md` |

| 2026-10-02 | R49 | PR [#2](https://github.com/mnesarco/FreeCAD-Launcher/pull/2) second CI run (37045958881) reached tests on Flutter 3.47.6 but failed on (a) `THIRD_PARTY_NOTICES.md` drift from the upgraded dependency set and (b) Windows `flutter analyze` exit 1 on the 127 tracked `.watch` infos. Regenerated the notices and set `flutter analyze --no-fatal-infos` in CI until B-17 removes the deprecated calls; third run 37046623647 **green on Ubuntu (4m36s) + Windows (9m2s)** | B-16, B-17 | `.github/workflows/ci.yml`, `THIRD_PARTY_NOTICES.md`, `docs/impl/{PLAN-signals-implicit-migration,TASKS,STATUS}.md` |

| 2026-10-02 | R50 | **B-17 signals migration done locally**: all 127 `.watch()` sites in 34 classes moved to `SignalWidget`/`SignalStatefulWidget` in four batches (`6c9f375`, `f2c24ee`, `8009cfc`, B-17d commit); `flutter analyze` back to 0 issues, `--no-fatal-infos` bridge removed; B-17c found implicit tracking drops unused subscriptions (old sticky `watch()`) and fixed `BundleDetailView`; 615 tests green; full live pass incl. a live dark↔light theme switch, zero runtime errors; PR #3 CI **green on Ubuntu + Windows** (run 37058324255), merge on owner approval | B-17, D-101 | `lib/**`, `.github/workflows/ci.yml`, `docs/impl/{PLAN-signals-implicit-migration,TASKS,STATUS}.md` |

| 2026-10-02 | R51 | B-17 PR #3 merged to `devel` (rebase, branch deleted); **B-16 Phase 3 no-publish release smoke** (run 37063249302) green — appimage 103 s / windows 221 s / publish skipped; artifacts downloaded and verified (`sha256sum -c` OK, AppImage `--version` = 0.4.1 exit 0 + GUI dashboard rendered, Windows zip = portable bundle + `7zr.exe` + license/notices). Remaining B-16 Phase 3: real 1.1.3 catalog install and the Windows-machine smoke (owner-dependent) | B-16, B-17, D-103 | `docs/impl/{PLAN-dependency-upgrades,STATUS,TASKS}.md` |

| 2026-10-02 | R52 | Owner verified the upgraded app on a Linux machine: real catalog install + isolated profile launch, **all passed, no issues** (B-16 Phase 3). `VERIFICATION.md` §4 Linux cells and the plan updated; only the Windows-machine smoke remains | B-16, D-103 | `docs/impl/{PLAN-dependency-upgrades,VERIFICATION,STATUS,TASKS}.md` |

| 2026-10-02 | R53 | B-16 Phase 3 Windows-machine smoke placed **on hold** (no Windows machine available); B-16 is otherwise complete (Windows CI job + portable-zip build green). Recorded in the plan, TASKS and the blockers list; next work is the `v0.4.1` Linux retest | B-16 | `docs/impl/{PLAN-dependency-upgrades,TASKS,STATUS}.md` |

| 2026-10-02 | R54 | Planning: **B-18** Home “Recent profiles” row — up to 5 recent-profile cards at the top of Home, whole card launches, chevron opens the profile detail, unhealthy builds hidden, horizontal scroll; owner choices captured in **D-104** (supersedes D-067's last-used-card clause), plan [PLAN-B18-home-recent-profiles.md](PLAN-B18-home-recent-profiles.md) and B-18a..d breakdown recorded; no code | B-18, D-104 | `docs/impl/{PLAN-B18-home-recent-profiles,DECISIONS,TASKS,STATUS}.md` |

| 2026-10-02 | R55 | **B-18 Home “Recent profiles” row implemented** (branch `b18-home-recent-profiles`): `ProfilesController.recentProfiles` computed (used + installed only, newest first, cap 5), top row of compact cards (whole card launches, chevron opens the detail through the new `ProfilesViewState.openProfile`/`AppShell` callback), l10n keys, spec 03 §2.1; 9 new tests (624 green, analyze clean); live pass (order, chevron → detail, narrow-window horizontal scroll, zero runtime errors); follow-ups in the same branch: the Status counters row was removed from Home and the Versions Installed/Available rows were restyled to the Profiles card style (spec 03 §2.1/§2.2 and plan updated; 624 tests green, live-verified); PR/CI pending | B-18, D-104 | `lib/state/profiles_controller.dart`, `lib/ui/{home/home_view,profiles/profiles_view,shell/app_shell,builds/builds_view}.dart`, `lib/l10n/**`, `docs/spec/03-ux.md`, `test/**`, `docs/impl/**` |

| 2026-10-02 | R56 | **R-24/D-105 cache deletion guards**: Settings ▸ Cache “Build downloads” Clear and “Clean up now” now show confirmation dialogs (size/retention, installed versions/profiles unaffected; Forever shows an info-only dialog); other regenerable categories stay one-click. New l10n + 3 widget tests (627 green, analyze clean); the live Cache card was checked, the dialog click-through was deferred to avoid disturbing the user's session on the dev machine | R-24, D-105 | `lib/ui/settings/settings_view.dart`, `lib/l10n/**`, `docs/spec/03-ux.md`, `test/ui/settings_view_test.dart`, `docs/impl/{DECISIONS,TASKS,STATUS}.md` |

| 2026-10-02 | R57 | **v0.4.2 pre-release published**: PR [#4](https://github.com/mnesarco/FreeCAD-Launcher/pull/4) (Home “Recent profiles” row B-18/D-104, Versions row style, cache delete guards R-24/D-105) CI green (run 37080374866) then rebase-merged; version bumped 0.4.1 → 0.4.2 and the manual `release.yml` run 37080913815 published the GitHub pre-release with `FreeCADLauncher-0.4.2-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.4.2-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after download, AppImage `--version` = 0.4.2 (exit 0), Windows zip complete (`7zr.exe`, license, notices) | B-18, R-24, D-104, D-105 | `lib/core/constants.dart`, `pubspec.yaml`, `README.md`, `docs/spec/{03-ux,07-distribution}.md`, `docs/impl/{VERIFICATION,STATUS,TASKS}.md` |

| 2026-10-03 | R58 | **R-25 visual refresh implemented** on branch `visual-refresh` off `devel` (D-106): brand scheme seeded from Tufts Blue `#418FDE` with the M3 fidelity variant, `AppStatusColors` theme extension, component themes (cards/rail/chips/tiles/dialogs/tabs/buttons/tooltip/scrollbar) and a tuned type scale in `lib/ui/theme/`; shell tonal status bar (the initial rail brand mark was dropped as redundant, owner request); semantic `CompactBadge` tones across the call sites; tinted `EmptyState`; slim Home hero (live summary + New profile/Check updates); R-25a..e one commit each; 634 tests green, analyze clean, a11y contrast green; live Linux pass dark↔light (all six sections, theme persisted over restart, zero runtime errors) and README screenshots recaptured | R-25, D-106 | `lib/ui/theme/**`, `lib/ui/{home,shell,profiles,builds,addons,macros,updates,jobs,widgets}/**`, `lib/app.dart`, `lib/l10n/**`, `test/ui/**`, `docs/images/*.jpg`, `docs/spec/03-ux.md`, `docs/impl/{DECISIONS,TASKS,VERIFICATION,STATUS}.md` |

| 2026-10-03 | R59 | **R-26 catalog icon sharpness** (visual-refresh follow-up): shared `RasterIcon` (native decode + `FilterQuality.high` + anti-aliasing, BOM-safe `looksLikeSvg`) replaces the duplicated raster paths in `AddonIcon`/`MacroIcon`; `MacroIcon`'s device-pixel `cacheWidth` pre-downscale removed so HiDPI upscaling is cubic; 3 new tests (637 green), analyze clean; live DPR≈1.6 pass on Macros/Addons shows smooth upscaling; theme persistence re-verified during the pass (Settings wrote `theme_mode` to `config.db`, restored to dark afterwards) | R-26, R-10, R-25 | `lib/ui/{addons/addon_icon,macros/macro_icon,widgets/raster_icon}.dart`, `test/ui/raster_icon_test.dart`, `docs/impl/{TASKS,VERIFICATION,STATUS}.md` |

| 2026-10-03 | R60 | **v0.4.3 pre-release published** (owner request): visual refresh (R-25/R-26, D-106) squash-merged into `devel` as `1dc65b6` on top of `5954098`; version bumped 0.4.2 → 0.4.3 (`b9bdbed`; `check_version.sh` OK, analyze clean, 637 tests green) and pushed; manual `release.yml` run 37148725010 (`create_release=true`, tag `v0.4.3`, `prerelease=true`) green and published the GitHub pre-release with `FreeCADLauncher-0.4.3-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.4.3-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after download, AppImage `--version` = 0.4.3 (exit 0), Windows zip checked for `7zr.exe`/license/notices | R-25, R-26, D-106 | `lib/core/constants.dart`, `pubspec.yaml`, `README.md`, `docs/spec/{03-ux,07-distribution}.md`, `docs/impl/{STATUS,VERIFICATION}.md` |

| 2026-10-03 | R61 | **R-27 profile-context catalog pickers** on branch `profile-catalog-pickers` off `devel` (D-107): shared `AddonPickerDialog` (from Collections) + `installAddonIntoProfile` (requirements consent; also used by the Addons catalog tab); Profile ▸ Addons gets header/empty-state `Add addon` (search + `#tag`, installed rows marked/disabled, primary branch, install into that profile); a matching `MacroPickerDialog` + `InstalledMacrosList` header/empty-state `Add macro` covers Profile ▸ Macros and Macros ▸ Installed; R-27a..d one commit each; analyze clean, 6 new widget tests (`profile_addons_picker_test`, `profile_macros_picker_test`, spy controllers) and the test/ui suite green; live pass on the real Addons/Macros tabs (dialogs, search, installed badges) without installing into the owner's profiles; PR/CI pending | R-27, D-107 | `lib/ui/addons/{addon_picker_dialog,addon_install_flow,collections_view,addons_view}.dart`, `lib/ui/profiles/profile_detail_view.dart`, `lib/ui/macros/{macro_picker_dialog,installed_macros}.dart`, `lib/l10n/**`, `test/ui/**`, `docs/spec/03-ux.md`, `docs/impl/**` |

| 2026-10-03 | R62 | **R-27 follow-ups + R-28** on the same branch: profile tab list consistency (installed addons as `Card` rows `74f12bb`; 8 px header/list separation and Python tab card rows `9e0bf21`, live-verified on Demo) and the missing Profile ▸ Addons remove action (`removeAddonFromProfile` confirmation/snackbar flow shared with the catalog detail; row Remove button); `profile_addons_picker_test` now 5 tests green, analyze clean | R-27e, R-28 | `lib/ui/profiles/profile_detail_view.dart`, `lib/ui/macros/installed_macros.dart`, `lib/ui/addons/{addon_remove_flow,addons_view}.dart`, `test/ui/profile_addons_picker_test.dart`, `docs/impl/{TASKS,VERIFICATION,STATUS}.md` |

| 2026-10-03 | R63 | **v0.4.4 pre-release published** (owner request): `profile-catalog-pickers` (R-27a..e, R-28, D-107) fast-forward-merged into `devel` plus the icon box-fit (R-26); version bumped 0.4.3 → 0.4.4 (`check_version.sh` OK, analyze clean, 644 tests green); manual `release.yml` run 37162641299 (`create_release=true`, tag `v0.4.4`, `prerelease=true`) green and published the GitHub pre-release with `FreeCADLauncher-0.4.4-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.4.4-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after download, AppImage `--version` = 0.4.4 (exit 0), Windows zip checked for `7zr.exe`/license/notices | R-27, R-28, R-26, D-107 | `lib/core/constants.dart`, `pubspec.yaml`, `README.md`, `docs/spec/{03-ux,07-distribution}.md`, `docs/impl/{STATUS,VERIFICATION}.md` |

| 2026-10-04 | B19-1 | **B-19 FreeCAD `<depend>` support implemented** on branch `b19-addon-dependencies` off `devel` (not committed): owner Q&A (unified deps dialog with optional checkboxes, version attributes parsed but ignored, batched Python availability probe, lenient failures, all install paths, reverse-dep removal warning, missing-only on update), plan + **D-108..D-111** + tasks **B-19a..B-19f** (all DONE). Domain: `AddonDependency` parsing, pure resolver (automatic→addon/internal/python, installed-addon recursion, PEP 503 dedupe, post-order), `mergeDependencyPlans`; platform: `PythonPackageProbe` + generated stdlib fallback; controller: staged `package.xml` union, `prepareDependencies`/selection API, ordered dependency installs in one job, `source=addon:<declarer>`, per-package pip retry, `dependentsOf`; UI: unified dialog (required/optional/internal/invalid), detail row, “Required by” removal warning; bundle/batch/manifest wiring. 672 tests green, analyze clean; real Ondsel-Lens E2E (probe skipped requests/PyJWT, pip installed tzlocal, import verified) + real catalog check (67 addons with `<depend>`, Beltrami → Curves + numpy/scipy). Remaining live checks: optional checkbox install, dependent addon load in FreeCAD, removal warning UI | B-19, D-108..D-111 | `lib/domain/addons/{package_xml,addon,addon_dependencies}.dart`, `lib/domain/python/{python_names,python_stdlib_names}.dart`, `lib/platform/{python_package_probe,addon_manifest_reader}.dart`, `lib/state/{addons,bundle_apply,updates,profile_manifest,app_services}_controller.dart`/`app_services.dart`, `lib/ui/addons/**`, `lib/ui/updates/updates_summary_sheet.dart`, `lib/l10n/**`, `test/**`, `docs/**` |
| 2026-10-04 | B20-1 | **B-20 AppImage macro Python execution implemented** (D-112) on the same branch: `FreeCadMacroRunner` (generated `.FCMacro`, isolated home/temp, tagged JSON, `runAppImage` FUSE retry), `PipRunner.install({pythonPath?\|appImagePath?})` running pip in-process inside the mounted image (log + `PIP_CACHE_DIR`), `PythonPackageProbe.availablePackagesInFreeCad`, `PythonExecutionResolver` (AppImage-in-place when `diagnostics.fuseAvailable`, one-time extraction fallback otherwise); `AddonsController`/`PythonController`/`AppServices` wired, dependency consent preview stays instant. **Live pass** on an isolated data root with a symlinked stable AppImage and no extraction: catalog Ondsel-Lens install (pyjwt+tzlocal via macro pip, bundled requests filtered, `source=addon:Ondsel-Lens`) and Python-tab `six`; no `extracted/` dir created, data root 7.5 MB, no leftover mounts. 692 tests green (17 new), analyze clean; spec 06 §4.1/§4.2 + D-112 + VERIFICATION updated; FUSE-less fallback unit-tested only | B-20, D-112 | `lib/platform/{freecad_macro_runner,pip_runner,python_package_probe,python_execution}.dart`, `lib/state/{addons,python,app_services}_controller.dart`/`app_services.dart`, `test/platform/**`, `test/state/**`, `docs/**` |
| 2026-10-04 | B19-2 | **Owner-reported live bug fixed** (new profile → Profile ▸ Addons → Add addon → Ondsel-Lens → Install “did nothing”): the dialog-phase availability probe resolved the AppImage interpreter with extraction allowed, so the first click silently ran an ~800 MB `--appimage-extract`. Fix: `PythonEnvResolver.resolve(allowExtraction: false)` for consent previews (fast fallback list), full probe re-resolved **after** consent with `Preparing Python (N files)` job progress, only successful probe results cached (fallback no longer blocks the real probe), UI `try/catch` + error snackbar and `appLogger` before the job starts, and `installed_addons.hasRequirements` now derives from the resolved plan (covers `automatic` Python deps). Live desktop pass on an isolated data root (real UI, stable 1.1.3, empty extraction): dialog appeared in ~1 s with pyjwt/requests/tzlocal and no extraction; after “Install dependencies” the job extracted, filtered bundled `requests`, pip-installed pyjwt+tzlocal (`source=addon:Ondsel-Lens`) and the addon appeared in Tes2; no runtime errors. 675 tests green, analyze clean | B-19, D-110, D-111 | `lib/platform/python_env.dart`, `lib/state/addons_controller.dart`, `lib/ui/addons/addon_install_flow.dart`, `test/platform/python_env_test.dart`, `test/state/addons_controller_test.dart`, `test/helpers/fake_pip.dart`, `docs/impl/**` |

| 2026-10-04 | R-30 | **History Workbench install fixed** (owner report): its GitHub archive carries 3 git symlinks (one absolute to the author's machine), and the D-039 extractor hard-failed on any symlink. **D-113** changes the policy to *skip and report*: `SafeArchiveExtractor` never creates links and emits `SkippedArchiveEntry{path,target}` via `onWarning`; `AddonInstaller` propagates them; `AddonsController.installWarnings` + `appLogger.warn` + job detail; addon installs show a “Some files were skipped” dialog listing each path→target (custom flows and build archives log too). Verified against the real `HistoryWorkbench-release.zip` (3 skips, `package.xml` and workbench resources extracted, no link files). Extractor/installer/controller/widget tests updated (+4); 698 tests green, analyze clean | R-30, D-113 | `lib/platform/{archive_extract,addon_installer,build_installer,seven_zip_extractor}.dart`, `lib/state/addons_controller.dart`, `lib/ui/addons/{addon_install_flow,custom_addons_view,addon_install_warnings_dialog}.dart`, `lib/l10n/**`, `test/**`, `docs/{spec/06-integrations,user-guide}.md`, `docs/impl/{DECISIONS,TASKS,STATUS}.md` |

| 2026-10-05 | R64 | **v0.4.5 pre-release published** (owner request): `devel` pushed to `origin` (`68289a6..f6b5ac4`, 6 commits: B-19/B-20, R-29, Windows hardening b412b76, R-30, version bump); version 0.4.4 → 0.4.5 (`check_version.sh` OK, analyze clean, 698 tests green); manual `release.yml` run 37263850706 (`create_release=true`, tag `v0.4.5`, `prerelease=true`) green on appimage/windows/publish and published the GitHub pre-release with `FreeCADLauncher-0.4.5-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.4.5-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after download, AppImage `--version` = 0.4.5 (exit 0), zip checked for `7zr.exe`/license/notices | B-19, B-20, R-29, R-30, D-108..D-113 | `lib/core/constants.dart`, `pubspec.yaml`, `README.md`, `docs/spec/{03-ux,07-distribution}.md`, `docs/impl/{STATUS,VERIFICATION}.md` |

## Standing notes for the next agent

- The prototype is frozen at tag `prototype-final`; do not resurrect its code or schema.
- Read `docs/impl/DECISIONS.md` before proposing alternatives to anything already decided.
- Support floor is FreeCAD 1.0+ (D-021); pre-1.0 catalog tags are ignored. `legacy` is
  catalog-derived (D-078): supported stable lines older than the newest one present. Weekly
  builds are exposed in Versions → Available (D-077); release candidates have their own `rc`
  channel (D-119) and never feed stable update checks. CalVer readiness is backlog B-14.
- Publishing (D-081): public repo `mnesarco/FreeCAD-Launcher`, branch `devel`, releases only
  from CI (`release.yml`, tag push or manual `workflow_dispatch` with optional `create_release`).
  CI runs Linux + Windows with tests on both; macOS is disabled per D-083 until M8-04.
  `v0.4.6` is the current release (published as a pre-release; D-100); the `0.4.x` line continues.
- `AGENTS.md` is tracked again (no longer git-excluded); keep it in sync with `docs/impl/`
  when conventions or the project state change.

| 2026-10-04 | R-29 | **Create profile → open its detail view** (owner request): `showProfileFormDialog` now returns the created/edited `Profile` (the `ProfileFormResult` wrapper is gone); `ProfilesView._createProfile` selects the new profile and Home's hero/first-run `New profile` routes through `onOpenProfile`, so both entry points (and `Ctrl+N`) land on the detail view. 2 widget tests added (Profiles tabs, Home callback); spec 03 §3.3 and TASKS updated; analyze clean, full suite green | R-29 | `lib/ui/profiles/{profile_dialogs,profiles_view}.dart`, `lib/ui/home/home_view.dart`, `test/ui/{profiles_view,home_view}_test.dart`, `docs/spec/03-ux.md`, `docs/impl/{TASKS,STATUS}.md` |

| 2026-10-05 | R65 | **R-31/D-114: Windows zip is self-contained**: users on machines without the system-wide Visual C++ Redistributable could not start `freecad_launcher.exe` (`VCRUNTIME140.dll`/`MSVCP140.dll` not found). `packaging/windows/build_portable.ps1` now resolves the VS x64 CRT redist folder via `vswhere` (`$env:VCToolsRedistDir` fallback), stages every `*.dll` next to the executable and fails the build unless `vcruntime140.dll`/`vcruntime140_1.dll`/`msvcp140.dll` are in the bundle and the zip; `THIRD_PARTY_NOTICES.md` gained a Microsoft Visual C++ runtime section (generator + drift check); spec 07 §2, spec 06 §1.4, README and the user guide updated. No-publish release run 37323499192 verified the artifact (sidecar `sha256sum -c` OK, 10 runtime DLLs in the zip, CI smoke `--version` green); version bumped 0.4.5 → 0.4.6 and the manual `release.yml` run 37324089592 (`create_release=true`, tag `v0.4.6`, `prerelease=true`) published the pre-release; both assets re-verified after download, AppImage `--version` = 0.4.6 (exit 0), release zip carries the runtime DLLs. `flutter analyze` clean, 698 tests green (10 skipped); residual: no no-redist Windows machine for a live start check | R-31, D-114 | `packaging/windows/build_portable.ps1`, `tool/generate_third_party_notices.dart`, `THIRD_PARTY_NOTICES.md`, `README.md`, `lib/core/constants.dart`, `pubspec.yaml`, `docs/spec/{06-integrations,07-distribution}.md`, `docs/user-guide.md`, `docs/impl/{DECISIONS,TASKS,VERIFICATION,STATUS}.md` |
| 2026-10-05 | R66 | **R-32/D-115: Windows addon-dependency pip dialog fixed** (owner report + screenshot): installing an addon with `<depend>` Python packages ran `FreeCAD.exe -m pip …` and FreeCAD popped “unrecognised option '-m'”. Root cause: the catalog asset-name hint (`py311`) short-circuited `ProcessPythonProbe.detect`, which returned `BundledPython(executablePath: FreeCAD.exe, version: hint)`; `PipRunner` then treated the FreeCAD exe as the interpreter. Fix: the hint now only fills the version when no interpreter can be probed (never `pythonPath`); `detect` always discovers/probes the bundled interpreter (Windows `bin\python.exe` per spec 06 §4.1) and probes with a sanitized Python env; `PythonEnvResolver` ignores legacy stored paths equal to the build executable or naming `FreeCAD`/`FreeCADCmd`/`AppRun`; `PipRunner` refuses to run a FreeCAD executable as Python (FreeCAD is only ever called with `-c`). 5 new/updated tests, 703 tests green (10 skipped), `flutter analyze` clean; spec 06 §4.1, D-115, TASKS R-32 and VERIFICATION updated; Windows live retest pending | R-32, D-115 | `lib/platform/{python_probe,python_env,pip_runner}.dart`, `test/platform/{python_probe,python_env,pip_runner}_test.dart`, `docs/spec/06-integrations.md`, `docs/impl/{DECISIONS,TASKS,VERIFICATION,STATUS}.md` |
| 2026-10-05 | R67 | **v0.4.7 pre-release published** (owner request): fix commit `33027ca` + version bump `e21ce1d` pushed to `origin/devel`; manual `release.yml` run 37341658955 (`create_release=true`, tag `v0.4.7`, `prerelease=true`) green on appimage/windows/publish and published the GitHub pre-release with `FreeCADLauncher-0.4.7-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.4.7-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars verified after download, AppImage `--version` = 0.4.7 (exit 0), zip carries `7zr.exe`/license/notices + the app-local MSVC runtime DLLs. `check_version.sh` OK, analyze clean, 703 tests green | R-32, D-115 | `lib/core/constants.dart`, `pubspec.yaml`, `README.md`, `docs/spec/07-distribution.md`, `docs/impl/{DECISIONS,TASKS,VERIFICATION,STATUS}.md` |
| 2026-10-05 | R68 | **M8-07/D-116: platform metadata + Windows data-root decoupling**: `windows/runner/Runner.rc` `LegalCopyright` and macOS `PRODUCT_COPYRIGHT` now match the D-074 holder exactly (`Copyright 2026 Frank Martínez <mnesarco at gmail>`) and Windows `CompanyName` is `Frank Martínez`; the Windows data root is pinned to `%APPDATA%\org.freecad.ext.launcher` (D-016) computed from `APPDATA` instead of the exe VERSIONINFO, with a one-time rename of the legacy `%APPDATA%\FreeCAD Launcher contributors\FreeCAD Launcher`, pinned-root precedence, and a logged fallback to the legacy root when the move fails (retried next start, never a partial copy); `AppPaths.migrationWarning` is logged after the logger is configured; new `packaging/windows/check_version_info.ps1` wired into `ci.yml` + `release.yml`; 6 new resolver tests, 709 tests green (10 skipped), analyze clean; D-116 recorded, D-016 amended, spec 05/README/user-guide updated; version 0.4.7 → 0.4.8. Pending: Windows CI run + live upgrade retest (no machine) | M8-07, D-116 | `lib/platform/paths.dart`, `lib/main.dart`, `windows/runner/Runner.rc`, `macos/Runner/Configs/AppInfo.xcconfig`, `packaging/windows/check_version_info.ps1`, `.github/workflows/{ci,release}.yml`, `test/platform/paths_test.dart`, `lib/core/constants.dart`, `pubspec.yaml`, `README.md`, `docs/spec/05-data-model.md`, `docs/user-guide.md`, `docs/impl/**` |
| 2026-10-05 | R69 | **M8-07 verified on Windows CI and pushed** (owner request): the five M8-07 commits (`34438af`, `df3cf00`, `a2a26a9`, `5767553`, `09c4ded`) pushed to `origin/devel`; CI run 37362656403 green on both jobs — `windows-latest` (build release + `check_version_info.ps1` asserting `LegalCopyright`/`CompanyName`/`ProductName`/`ProductVersion`) and `ubuntu-latest` (version check, codegen/notices freshness, analyze, 709 tests, Linux build). M8-07 marked DONE in `TASKS.md`; residual: live upgrade retest over a `v0.4.7` data dir (no machine) | M8-07, D-116 | `docs/impl/{TASKS,VERIFICATION,STATUS,PLAN-M8-windows-release}.md` |
| 2026-10-05 | R70 | **M8-08/D-117: data-root regression fixed** (owner report: all installed builds Broken after the M8-07 rename on Windows): the 0.4.8 migration moved `config.db` + `builds/` but the DB is an index storing absolute paths, invalidating every `builds.localPath` (`BuildsController._statusFor` marks Broken when the executable is missing). Fix: `AppPaths.resolve` never moves the root — pinned `%APPDATA%\org.freecad.ext.launcher` when it contains `config.db`, else the legacy `%APPDATA%\FreeCAD Launcher contributors\FreeCAD Launcher`, else pinned (fresh installs) — and exposes `legacyRoot`; new `DataRootRepair` rewrites legacy-prefixed `builds.localPath`/`pythonPath`, `catalog_cache.payloadPath`, `installed_addons.sourcePath` and `python_packages.targetDir` into the active root only when the mapped target exists (idempotent, logged once via `AppServices.startupWarning` after logger setup); `PythonPackagesDao.getAll` added. 5 resolver + 4 repair tests, analyze clean, 713 tests green (10 skipped); D-117 recorded, D-116 amended, README/user-guide/spec 05/PLAN/TASKS/VERIFICATION updated; version 0.4.8 → 0.4.9. Pending: owner Windows retest + CI artifact | M8-08, D-117 | `lib/platform/paths.dart`, `lib/data/data_root_repair.dart`, `lib/data/daos/python_packages_dao.dart`, `lib/state/app_services.dart`, `lib/main.dart`, `test/platform/paths_test.dart`, `test/data/data_root_repair_test.dart`, `lib/core/constants.dart`, `pubspec.yaml`, `README.md`, `docs/user-guide.md`, `docs/spec/05-data-model.md`, `docs/impl/**` |
| 2026-10-05 | R71 | **v0.4.9 pre-release published** (owner request): the M8-08/D-117 commits (`afe9032` fix, `77b8201` docs, `e3ca073` bump) pushed to `origin/devel`; manual `release.yml` run 37371511156 (`create_release=true`, tag `v0.4.9`, `prerelease=true`) — appimage green, windows cancelled once by a GitHub hosted-runner acquisition outage ("job was not acquired by Runner of type hosted") and green on rerun, publish green; GitHub pre-release `v0.4.9` created with `FreeCADLauncher-0.4.9-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.4.9-x86_64.AppImage` + `.sha256` + `.zsync`; both sidecars re-verified after download (`sha256sum -c` OK) and AppImage `--version` = 0.4.9 (exit 0). Windows artifact 0.4.9 also repacked to `.7z` for the owner's retest (local `/tmp/opencode/fcl-win-0.4.9`, sha256 `a31b225c…8d89`) | M8-07, M8-08, D-116, D-117 | `docs/impl/{STATUS,VERIFICATION,TASKS}.md` |
| 2026-10-05 | R72 | **R-33: Windows `Bad state: StreamSink is closed` console spam fixed** (owner report; app kept working): `ProfilesController._trackLaunch` closed the launch log `IOSink` after the 5 s stdout/stderr drain timeout, but `Future.timeout` does not cancel the `listen(logSink.add)` subscriptions, so a late pipe chunk (Windows stdio pipes outlive the process via inherited write handles) hit the closed sink (`_Socket._onData` → `_StreamSinkImpl.add`). Fix: cancel both subscriptions before flush/close; `logDrainTimeout` is injectable (default 5 s) for a deterministic regression test using the new `FakeProcessHandle.exitWithoutClosingStreams` (verified to fail on the old code). `flutter analyze` clean, 714 tests green (10 skipped); TASKS R-33 + VERIFICATION §R-33 added; Windows live retest pending | R-33 | `lib/state/profiles_controller.dart`, `test/helpers/fake_process.dart`, `test/state/profiles_controller_test.dart`, `docs/impl/{TASKS,VERIFICATION,STATUS}.md` |
| 2026-10-05 | R73 | **R-34/D-118: weekly Windows addon dependencies fixed and dependency failures surfaced** (owner report: Ondsel-Lens `<depend>` install worked on stable but failed on the weekly profile). Owner evidence: pip log `WARNING: Disabling truststore since ssl support is missing` + `The 'ssl' module is unavailable but required for HTTPS URLs`; the bootstrap diagnostics pinned it to `ImportError: cannot import name 'RAND_pseudo_bytes' from '_ssl'` at `Lib/ssl.py:109`. Root cause: both 1.1 bundles ship the same stale Python 3.11-era `ssl.py` (byte-identical), but 3.11's `_ssl` still exports `RAND_pseudo_bytes` while 3.13 removed it — stable works, weekly fails. Fix: interpreter pip now runs a generated bootstrap that aliases the removed symbol (`_ssl.RAND_pseudo_bytes = _ssl.RAND_bytes`) before importing `ssl`, registers the interpreter's `bin`/`DLLs` with `os.add_dll_directory` (Windows; handles kept alive) and prepends them to `PATH`, logs the interpreter identity and the full `ssl` traceback, then runs `runpy.run_module("pip", …)` with the same arguments; `requirementErrorKey(profileId, addonId)` scopes requirement errors to one profile+addon and the profile Addons row + install snackbar now show them (catalog detail already did). Linux AppImage macro (D-112) untouched; reproduced the Windows failure on Linux (Python 3.13.11 + archive `ssl.py` on `PYTHONPATH`) and verified the extracted bootstrap patches it and installs `pyjwt`/`tzlocal` via pip 26.2.1; plain 3.13/pip 26 and `real_pip_install_test` (system pip 24) also pass. `flutter analyze` clean, 716 tests green (10 skipped); TASKS R-34, DECISIONS D-118, VERIFICATION §R-34, spec 06 §4.2 updated; Windows weekly live retest pending | R-34, D-118 | `lib/platform/pip_runner.dart`, `lib/domain/addons/addon_dependencies.dart`, `lib/state/addons_controller.dart`, `lib/ui/addons/{addon_install_flow,addons_view}.dart`, `lib/ui/profiles/profile_detail_view.dart`, `test/platform/pip_runner_test.dart`, `test/state/addons_controller_test.dart`, `test/ui/profile_addons_picker_test.dart`, `docs/spec/06-integrations.md`, `docs/impl/**` |
| 2026-10-05 | R74 | **R-35: status bar jobs indicator animated** (owner request: running work must be visible at a glance): the active-jobs chip used a static `Icons.sync`, so only the label showed that something was running. New `_JobsActivityIcon` (`lib/ui/shell/app_shell.dart`, key `statusBarJobsIndicator`) rotates continuously with a 1400 ms linear `AnimationController`/`RotationTransition` while jobs are queued/running and falls back to the static icon when `MediaQuery.disableAnimationsOf` reports the OS/accessibility "disable animations" setting. 2 new `app_shell_test` cases (rotation value changes while a job is active and the indicator disappears on completion; disabled-animations case has no `RotationTransition`); the existing jobs test fakes `disableAnimations` so `pumpAndSettle` stays settle-friendly. `flutter analyze` clean, 718 tests green (10 skipped); TASKS R-35, VERIFICATION §R-35 and spec 03 §1 updated; live visual pass pending | R-35 | `lib/ui/shell/app_shell.dart`, `test/app_shell_test.dart`, `docs/spec/03-ux.md`, `docs/impl/{TASKS,VERIFICATION,STATUS}.md` |
| 2026-10-06 | R75 | **v0.4.10 pre-release published** (owner request): version bumped 0.4.9 → 0.4.10 in `pubspec.yaml`/`lib/core/constants.dart` (`chore(release): bump version to 0.4.10 [R-34]`, `75803b5`), `check_version.sh` OK, pushed to `origin/devel`. Manual `release.yml` run 37397595261 (`create_release=true`, tag `v0.4.10`, `prerelease=true`, ref `devel`) — appimage/windows/publish all green — published the GitHub pre-release `v0.4.10` with `FreeCADLauncher-0.4.10-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.4.10-x86_64.AppImage` + `.sha256` + `.zsync`. All five assets re-downloaded and verified: both sidecars `sha256sum -c` OK, AppImage `--version` = 0.4.10 (exit 0), zip carries `7zr.exe`, `freecad_launcher.exe`, `LICENSE`, `THIRD_PARTY_NOTICES.md` and the app-local MSVC runtime DLLs. The release carries R-33 (pipe lifecycle), R-34/D-118 (weekly ssl fix + dependency error surfacing) and R-35 (animated jobs indicator) plus the M8-07/M8-08 work from 0.4.8/0.4.9 | R-34, R-35, D-118 | `lib/core/constants.dart`, `pubspec.yaml`, `docs/impl/STATUS.md` |
| 2026-10-08 | R76 | **R-36/D-119: release candidates installable** (owner report: `26.3rc1` not installable): the GitHub prerelease is fetched but `ReleaseTag.parse` dropped it because the stable regex rejected the `rcN` suffix. `FreeCadVersion` now carries an `rc` component (`isPrerelease`, `26.3rc1 < 26.3rc2 < 26.3`), `BuildChannel.rc` added, `ReleaseTag.parse` maps supported prereleases to it (pre-1.0 RCs stay below the floor), `BuildsController.rcBuilds` fed by the catalog, Versions → Available gets the **RC** filter + badge + confirmation warning (weekly pattern), `UpdatesController` unchanged (RC never stable/weekly), portable path `rc_26.3rc1_linux_x86_64` asserted (D-095). Real `26.3rc1` fixture; 6 new/updated tests; analyze clean, 726 tests green (10 skipped); spec 06/03/05, user guide, B-14, TASKS and VERIFICATION updated. Uncommitted; live catalog install/launch pending | R-36, D-119 | `lib/domain/builds/{freecad_version,build_types}.dart`, `lib/state/builds_controller.dart`, `lib/ui/builds/builds_view.dart`, `lib/l10n/app_en.arb`, `lib/l10n/gen/**`, `test/domain/{freecad_version,asset_classifier}_test.dart`, `test/fixtures/github_releases_26.3rc1.json`, `test/state/{builds_controller,updates_controller}_test.dart`, `test/ui/builds_view_test.dart`, `test/core/path_segments_test.dart`, `test/platform/paths_test.dart`, `docs/spec/{03-ux,05-data-model,06-integrations}.md`, `docs/user-guide.md`, `docs/impl/{DECISIONS,TASKS,VERIFICATION,STATUS}.md` |
| 2026-10-08 | R77 | **v0.4.11 pre-release published** (owner request): R-36/D-119 committed (`28faf1b feat(builds): install release candidates via the rc channel [R-36]`) and the version bumped 0.4.10 → 0.4.11 (`bc91ea9 chore(release): bump version to 0.4.11 [R-36]`); `packaging/check_version.sh` OK, `flutter analyze` clean. Pushed to `origin/devel` (`76b2a30..bc91ea9`). Manual `release.yml` run 37830243774 (`create_release=true`, tag `v0.4.11`, `prerelease=true`, ref `devel`) green on appimage/windows/publish and published the GitHub pre-release with `FreeCADLauncher-0.4.11-windows-x86_64.zip` + `.sha256` and `FreeCADLauncher-0.4.11-x86_64.AppImage` + `.sha256` + `.zsync`; all assets re-downloaded and verified: both sidecars `sha256sum -c` OK, AppImage `--version` = 0.4.11 (exit 0), zip carries `7zr.exe`, `freecad_launcher.exe`, `LICENSE`, `THIRD_PARTY_NOTICES.md` and the app-local MSVC runtime DLLs. The release carries R-36/D-119 (rc channel); live catalog install/launch of `26.3rc1` pending | R-36, D-119 | `lib/core/constants.dart`, `pubspec.yaml`, `docs/impl/STATUS.md` |
