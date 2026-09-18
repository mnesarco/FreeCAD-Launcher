# STATUS

> Live file. Every session updates this at start and end. Keep it short — details belong in
> `TASKS.md` and `DECISIONS.md`.

- **Updated**: 2026-09-18
- **Current milestone**: M2 — Builds (code complete; cross-OS manual verification pending)
- **Active branch**: `v2`
- **Last session**: 2026-09-18
- **Next action**: start **M3** with `M3-01` (profile DAO/repository + name validation +
  build/Python binding rules), then `M3-02` lifecycle, `M3-03` env integration.
- **Blockers**:
  - No git remote configured, so the M1 CI workflow has not executed on GitHub (tracked under
    OQ-7). Everything else is verified locally.
  - Real Windows `.7z` extraction and macOS `.dmg` install still need those OSes (Windows CI
    once a remote exists; macOS needs a machine). Linux is verified end-to-end.
  - Manual UI click-throughs (install from Versions, custom import) and a FUSE-less Linux
    launch are pending; logic is covered by tests.
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
  - 171 tests green (1 manual network test skipped), analyze clean, app builds and launches.

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

## Standing notes for the next agent

- The prototype is frozen at tag `prototype-final`; do not resurrect its code or schema.
- Read `docs/impl/DECISIONS.md` before proposing alternatives to anything already decided.
- M2 exit criteria are locally green; only cross-OS manual checks and the first CI run remain.
- Start M3 with `M3-01`; profiles are the core of the product, so keep `docs/spec/05-data-model.md`
  and D-005 (isolation env matrix) in view.
- `AGENTS.md` is locally git-excluded (`.git/info/exclude`); it is not part of commits.
