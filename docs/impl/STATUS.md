# STATUS

> Live file. Every session updates this at start and end. Keep it short — details belong in
> `TASKS.md` and `DECISIONS.md`.

- **Updated**: 2026-09-30
- **Current milestone**: **M7 — Linux v0.1 completion: complete** (M7-01/M7-03/M7-04/M7-06 done;
  M7-05 deferred to M8-05 per D-073)
- **Active branch**: `devel` (public) — `main` is reserved for a future release line
- **Last session**: 2026-09-30
- **Next action**: publish to GitHub (`mnesarco/FreeCAD-Launcher`, D-081): add the remote, push
  `devel`, watch the first CI matrix run (M8-02), then run the manual **Release AppImage**
  workflow; after that `M8-03`/`M8-04` (Windows/macOS artifacts) and `M8-05` (clean-VM pass).
  Backlog: `B-01` legacy channel, `B-14` CalVer readiness, `B-02` in-place build updates.
- **Blockers**:
  - None for publishing. M8-03/M8-04 still need Windows/macOS machines (OQ-1).
- **In progress**: none
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

## Standing notes for the next agent

- The prototype is frozen at tag `prototype-final`; do not resurrect its code or schema.
- Read `docs/impl/DECISIONS.md` before proposing alternatives to anything already decided.
- Support floor is FreeCAD 1.0+ (D-021); pre-1.0 catalog tags are ignored, `legacy` = 1.0.x,
  custom user binaries are unaffected.
- M7 is Linux-first (D-072): finish the Linux functional pass (M7-06), LICENSE/notices, README
  and the clean-VM check; CI, release publishing and Windows/macOS deployment are deferred to M8.
- `AGENTS.md` is tracked again (no longer git-excluded); keep it in sync with `docs/impl/`
  when conventions or the project state change.
