# STATUS

> Live file. Every session updates this at start and end. Keep it short — details belong in
> `TASKS.md` and `DECISIONS.md`.

- **Updated**: 2026-09-18
- **Current milestone**: M1 — Foundation
- **Active branch**: `v2`
- **Last session**: 2026-09-18
- **Next action**: `M1-06` `platform/process.dart` `ProcessRunner` (arg arrays, sanitized
  env, streamed output, kill tree) with a fake process adapter.
- **Blockers**: none
- **In progress**: none
- **Recently completed**:
  - M0 — OQ-2 → `org.freecad.ext.launcher` (D-016); OQ-6 → ARB from day one (D-017); spec
    approved; repo workflow confirmed
  - M1-01 — prototype tagged `prototype-final`, `v2` branch created
  - M1-02 — v2 skeleton: prototype `lib/` replaced, ARB l10n scaffold, platform runners for
    Linux/Windows/macOS with app id `org.freecad.ext.launcher`, `http` added, `snapd`/`recase`
    removed. Verified locally: `flutter analyze` clean, `flutter test` green (1 widget test),
    `flutter build linux --release` succeeds. Windows/macOS builds pending M1-09 CI.
  - M1-03 — core primitives: `Result`/`AppError`, `Logger` with rotating file sink + secret
    redaction, constants. 10 unit tests; runtime verified: `app.log` created under
    `~/.local/share/org.freecad.ext.launcher/logs/`.
  - M1-04 — drift schema v1: 9 tables + 8 DAOs with natural-key upserts, FK cascades, enum
    columns; 30 in-memory DAO tests; generated files committed. `build_runner`, analyze and
    all 41 tests green. DB not wired into the app yet (M1-07 `AppServices`).
  - M1-05 — `ProfilePaths` + `LaunchEnvironment` (per-OS env matrix, python-var sanitation)
    and `AppPaths` (real app data layout + directory creation); 11 new tests, 52 total green.
- **Notes**:
  - Generated l10n files live in `lib/l10n/gen/` and are committed.
  - Windows/macOS runner scaffolding was generated on Linux; only CI can compile them.

## Session log

| Date | Session | Summary | Tasks | Touched |
|---|---|---|---|---|
| 2026-09-18 | planning | Requirements Q&A, cross-platform FreeCAD research, spec, implementation plan | — | `docs/spec/**`, `docs/impl/**`, `AGENTS.md` |
| 2026-09-18 | M0 | Resolved OQ-2/OQ-6, spec approved, workflow confirmed | M0-01..M0-04 | `docs/impl/DECISIONS.md`, `docs/spec/**` |
| 2026-09-18 | M1 | Prototype freeze, v2 branch, app skeleton with l10n and platform runners | M1-01, M1-02 | `lib/**`, `test/**`, `linux/**`, `windows/**`, `macos/**`, `pubspec.yaml`, `l10n.yaml` |
| 2026-09-18 | M1 | Core primitives: Result/AppError, rotating logger with redaction, constants; runtime log path verified | M1-03 | `lib/core/**`, `lib/main.dart`, `lib/ui/shell/**`, `test/core/**` |
| 2026-09-18 | M1 | Drift schema v1 + 8 DAOs + generated code + in-memory DAO tests | M1-04 | `lib/data/**`, `lib/domain/**`, `test/data/**`, `pubspec.yaml` |
| 2026-09-18 | M1 | Profile paths + launch environment builder per OS + AppPaths directory setup | M1-05 | `lib/domain/profiles/**`, `lib/platform/paths.dart`, `test/domain/**`, `test/platform/**` |

## Standing notes for the next agent

- The prototype is frozen at tag `prototype-final`; do not resurrect its code or schema.
- Read `docs/impl/DECISIONS.md` before proposing alternatives to anything already decided.
- The highest technical risk is `.7z` extraction (`S1`) — do not start `M2-05` before S1 exits.
- `AGENTS.md` is locally git-excluded (`.git/info/exclude`); it is not part of commits.
