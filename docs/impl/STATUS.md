# STATUS

> Live file. Every session updates this at start and end. Keep it short — details belong in
> `TASKS.md` and `DECISIONS.md`.

- **Updated**: 2026-09-18
- **Current milestone**: M1 — Foundation (code complete; first CI run pending a remote)
- **Active branch**: `v2`
- **Last session**: 2026-09-18
- **Next action**: `M2-01` GitHub releases client (conditional GET/ETag, cache, rate-limit
  headers) using the M1-10 fixtures; then `M2-02` asset classifier.
- **Blockers**:
  - No git remote configured, so the M1 CI workflow has not executed on GitHub (tracked under
    OQ-7). Everything else in M1 is verified locally.
- **In progress**: none
- **Recently completed**:
  - M1-01..M1-10 — foundation complete (schema, core, paths/env, process runner, shell,
    diagnostics, CI workflow, test harness). 78 tests green, analyze clean, codegen current.
  - S1 — Real FreeCAD 1.1.3 Windows asset inspected: `LZMA2:28 LZMA:20 BCJ2`, solid, 2 blocks;
    pure-Dart `koni_sevenz` cannot read BCJ2 → **D-018**: bundle official 7-Zip standalone
    `third_party/7zip/7zr.exe` (sha256 pinned, LGPL) and invoke via `ProcessRunner` arg arrays.
    Manual Windows extraction remains in M2-05.
  - S2 — **D-019**: `.dmg` install via `hdiutil attach -readonly` → copy `FreeCAD.app` →
    detach, quarantine removal with consent, direct binary spawn; manual macOS verification in
    M2-05.
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
| 2026-09-18 | M1 | ProcessRunner with streamed output, timeouts, kill and fake-adapter tests | M1-06 | `lib/platform/process.dart`, `test/platform/process_test.dart` |
| 2026-09-18 | M1 | AppServices/AppScope, six-section shell with l10n empty states, settings data dir | M1-07 | `lib/state/**`, `lib/ui/**`, `lib/app.dart`, `lib/main.dart`, `lib/l10n/**`, `test/app_shell_test.dart` |
| 2026-09-18 | M1 | Diagnostics service + settings panel; shared fake process helper | M1-08 | `lib/platform/diagnostics.dart`, `lib/ui/settings/**`, `test/platform/**`, `test/helpers/**` |
| 2026-09-18 | M1 | CI workflow + test harness (DB helper, FakeHttp, fixtures) | M1-09, M1-10 | `.github/workflows/ci.yml`, `test/helpers/**`, `test/fixtures/**` |
| 2026-09-18 | M2 | Spikes S1/S2: real FreeCAD `.7z` inspected, bundled 7zr.exe + license, `.dmg` design | S1, S2 | `third_party/7zip/**`, `docs/impl/DECISIONS.md` |

## Standing notes for the next agent

- The prototype is frozen at tag `prototype-final`; do not resurrect its code or schema.
- Read `docs/impl/DECISIONS.md` before proposing alternatives to anything already decided.
- The highest technical risk is `.7z` extraction (`S1`) — do not start `M2-05` before S1 exits.
- `AGENTS.md` is locally git-excluded (`.git/info/exclude`); it is not part of commits.
