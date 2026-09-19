# STATUS

> Live file. Every session updates this at start and end. Keep it short — details belong in
> `TASKS.md` and `DECISIONS.md`.

- **Updated**: 2026-09-19
- **Current milestone**: M4 — Addons and Python complete (S3, M4-01..M4-11 done); next: M5 —
  Collections, macros, config, export (S4 spike, then M5-01)
- **Active branch**: `v2`
- **Last session**: 2026-09-19
- **Next action**: start `M5-05` (macro scanner + installed list/delete/reveal/open). Manual
  M4/M5 UI click-throughs and the Windows/macOS manual checks remain open.
- **Blockers**:
  - No git remote configured, so the M1 CI workflow has not executed on GitHub (tracked under
    OQ-7). Everything else is verified locally.
  - Real Windows `.7z` extraction and macOS `.dmg` install still need those OSes (Windows CI
    once a remote exists; macOS needs a machine). Linux is verified end-to-end.
  - Manual UI click-throughs (install from Versions, custom import incl. executable + Python
    fallback dialog, profiles create/launch) are pending; headless profile launch, CLI wrapper
    and profile isolation are verified on Linux; GUI launch and Windows/macOS launches are
    pending a manual pass on those OSes.
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
    left the other intact (paths in the session log).
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
  - 384 tests green (8 manual probes skipped), analyze clean, app builds and launches.

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
| 2026-09-19 | M5 | D-048 macro catalog client, installer and Macros screen | M5-04 | `docs/impl/DECISIONS.md`, `lib/domain/macros/**`, `lib/data/catalog/macro_catalog.dart`, `lib/data/daos/macros_dao.dart`, `lib/platform/macro_installer.dart`, `lib/platform/paths.dart`, `lib/state/macros_controller.dart`, `lib/state/app_services.dart`, `lib/ui/macros/**`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M5 | D-047 bundle JSON export/import with validation and unresolved handling | M5-03 | `docs/impl/DECISIONS.md`, `lib/domain/bundles/bundle_json.dart`, `lib/state/bundles_controller.dart`, `lib/ui/addons/collections_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M5 | D-046 bundle apply planner, sequential runner and preview dialog | M5-02 | `docs/impl/DECISIONS.md`, `lib/domain/addons/addon_update_rules.dart`, `lib/domain/bundles/bundle_planner.dart`, `lib/state/bundle_apply_controller.dart`, `lib/state/addons_controller.dart`, `lib/state/app_services.dart`, `lib/ui/addons/collections_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | M5 | D-045 bundles controller + Collections tab (create/edit/items, profile seed) | M5-01 | `docs/impl/DECISIONS.md`, `lib/domain/bundles/bundle_rules.dart`, `lib/state/bundles_controller.dart`, `lib/state/app_services.dart`, `lib/data/daos/bundles_dao.dart`, `lib/ui/addons/collections_view.dart`, `lib/ui/addons/addons_view.dart`, `lib/l10n/**`, `test/**` |
| 2026-09-19 | S4 | D-044 macro catalog source: addons.freecad.org cache, format, placement and license handling | S4 | `docs/impl/DECISIONS.md`, `docs/spec/06-integrations.md` |
| 2026-09-19 | M4 | D-043 job queue (controller, cancel/retry, status bar + jobs dialog) and wiring for builds/addons/pip | M4-08 | `docs/impl/DECISIONS.md`, `docs/impl/TASKS.md`, `lib/domain/jobs/job_types.dart`, `lib/state/jobs_controller.dart`, `lib/state/*_controller.dart`, `lib/state/app_services.dart`, `lib/core/cancellation.dart`, `lib/platform/addon_installer.dart`, `lib/ui/jobs/jobs_dialog.dart`, `lib/ui/shell/app_shell.dart`, `lib/l10n/**`, `test/**` |

## Standing notes for the next agent

- The prototype is frozen at tag `prototype-final`; do not resurrect its code or schema.
- Read `docs/impl/DECISIONS.md` before proposing alternatives to anything already decided.
- Support floor is FreeCAD 1.0+ (D-021); pre-1.0 catalog tags are ignored, `legacy` = 1.0.x,
  custom user binaries are unaffected.
- M2 exit criteria are locally green; only cross-OS manual checks and the first CI run remain.
- Start M3 with `M3-01`; profiles are the core of the product, so keep `docs/spec/05-data-model.md`
  and D-005 (isolation env matrix) in view.
- `AGENTS.md` is tracked again (no longer git-excluded); keep it in sync with `docs/impl/`
  when conventions or the project state change.
