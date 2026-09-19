# STATUS

> Live file. Every session updates this at start and end. Keep it short — details belong in
> `TASKS.md` and `DECISIONS.md`.

- **Updated**: 2026-09-19
- **Current milestone**: M4 — Addons and Python (S3, M4-01 done; M4-02 next)
- **Active branch**: `v2`
- **Last session**: 2026-09-19
- **Next action**: start `M4-02` (catalog UI: search text + `#tag`, filters, grid, addon detail
  with branches and install action), then M4-03 install engine. M3 exit review and Windows/macOS
  manual checks remain open; `m3-complete` tag exists.
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
  - 269 tests green (6 manual probes skipped), analyze clean, app builds and launches.

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
