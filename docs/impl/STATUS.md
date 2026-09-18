# STATUS

> Live file. Every session updates this at start and end. Keep it short — details belong in
> `TASKS.md` and `DECISIONS.md`.

- **Updated**: 2026-09-18
- **Current milestone**: M1 — Foundation
- **Active branch**: `main` → `v2` (M1-01 in flight)
- **Last session**: 2026-09-18
- **Next action**: Finish `M1-01` (commit docs, commit prototype freeze, tag `prototype-final`,
  create `v2`), then `M1-02` (skeleton, deps, l10n, platform runners).
- **Blockers**: none
- **In progress**: `M1-01` — freeze prototype + branch
- **Recently completed**:
  - 2026-09-18 — v2 spec written (`docs/spec/`, 10 files)
  - 2026-09-18 — implementation plan created (`docs/impl/`, decision log seeded D-001..D-017)
  - 2026-09-18 — M0 complete: OQ-2 → `org.freecad.ext.launcher` (D-016), OQ-6 → ARB from
    day one (D-017), spec approved, workflow confirmed

## Session log

| Date | Session | Summary | Tasks | Touched |
|---|---|---|---|---|
| 2026-09-18 | planning | Requirements Q&A, cross-platform FreeCAD research, spec, implementation plan | — | `docs/spec/**`, `docs/impl/**`, `AGENTS.md` |
| 2026-09-18 | M0 | Resolved OQ-2/OQ-6, spec approved, workflow confirmed | M0-01..M0-04 | `docs/impl/DECISIONS.md`, `docs/spec/**` |

## Standing notes for the next agent

- The prototype in `lib/` is **frozen**. Do not extend it; v2 replaces it on the `v2` branch.
- Read `docs/impl/DECISIONS.md` before proposing alternatives to anything already decided.
- The highest technical risk is `.7z` extraction (`S1`) — do not start `M2-05` before S1 exits.
- Don't trust the old `AGENTS.md` architecture notes for v2; they describe the legacy prototype.
