# TASKS

Statuses: `TODO` · `WIP` · `BLOCKED` · `DONE` · `DROPPED`. Effort: `S`/`M`/`L`.
Implementation follows the spec in `../spec/`. Only the active milestone's table is normally
loaded into context; dependencies are listed per task.

## M0 — Decisions (required before M1)

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| M0-01 | Answer OQ-2: application id / reverse-DNS | Decision recorded in `DECISIONS.md`, OQ table updated | — | S | DONE |
| M0-02 | Answer OQ-6: i18n scaffolding in v0.1? | Decision recorded; `M1-02` unblocked | — | S | DONE |
| M0-03 | Spec sign-off | User confirms spec; `STATUS.md` moves to M1 | M0-01, M0-02 | S | DONE |
| M0-04 | Confirm repository workflow (prototype tag + v2 branch) | `M1-01` unblocked | — | S | DONE |

Exit: no open question blocks M1; all spec open questions have an owner/status.

## M1 — Foundation

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| M1-01 | Freeze prototype: tag `prototype-final`, create `v2` branch | Tag pushed, branch exists, `STATUS.md` updated | M0-04 | S | WIP |
| M1-02 | Project skeleton on `v2`: `pubspec` deps (`http` added, `snapd` removed), lints, `main.dart`/`app.dart` shell, ARB scaffolding if OQ-6 says yes | App builds and runs on Linux/Windows/macOS | M0-02 | M | TODO |
| M1-03 | `core/`: `Result`, `AppError`, leveled logging with rotation + redaction, constants | Unit tests green; logs written under `logs/` | M1-02 | S | TODO |
| M1-04 | drift schema v1 (`builds`, `profiles`, `installed_addons`, `python_packages`, `bundles`, `bundle_items`, `macros`, `catalog_cache`, `settings`) + DAOs + codegen | In-memory drift tests for each DAO; `build_runner` clean | M1-02, M0-01 | L | TODO |
| M1-05 | `domain/profiles`: path mapping + env builder per OS + profile rules | Unit tests cover Linux/Windows/macOS env matrices (`spec 04 §4.1`) | M1-02 | M | TODO |
| M1-06 | `platform/process.dart`: `ProcessRunner` (arg arrays, sanitized env, streamed output, kill tree) | Unit tests with a fake process adapter; no shell usage | M1-03 | M | TODO |
| M1-07 | `AppServices` + `AppScope` + sidebar shell + status bar + navigation (Home/Profiles/Versions/Addons/Macros/Settings) | App navigates all sections with empty states | M1-02 | M | TODO |
| M1-08 | Diagnostics service: FUSE presence (Linux), Gatekeeper/quarantine (macOS), disk, permissions | Diagnostics screen/API returns structured results; unit-testable | M1-03, M1-05 | S | TODO |
| M1-09 | CI matrix: analyze, tests, codegen-freshness check, `flutter build` per OS | Workflow green on a test PR | M1-02 | M | TODO |
| M1-10 | Test harness: in-memory drift helper, injected fake HTTP client, fixtures dir | Helpers used by at least one existing test | M1-04 | M | TODO |

Exit: shell runs on all three OSes; analyze/tests/build green in CI; schema and env logic
covered by tests.

## M2 — Builds (stable channel)

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| S1 | Spike: `.7z` extraction strategy | Written decision D-### with chosen extractor (pure Dart / FFI / bundled helper), license check, tested on a real FreeCAD `.7z` | M1-02 | M | TODO |
| S2 | Spike: macOS `.dmg` install (mount/copy/detach/quarantine) | Written decision; manual test on macOS extracts a launchable `.app` into `builds/<id>` | M1-02 | S | TODO |
| M2-01 | GitHub releases client: conditional GET (ETag), cache, rate-limit header handling, token hook (disabled in v0.1 unless OQ-3 says otherwise) | Unit tests against fixtures; no network in tests; 304 path covered | M1-10 | M | TODO |
| M2-02 | Asset classifier + version compare: stable/legacy/weekly-aware, per-OS/arch selection, exact regexes from `spec 06 §1.3` | Fixture tests for 1.1.3, 1.0.2, 0.21.2, 0.20.0, weekly and gaps (0.19.4) | M1-10 | M | TODO |
| M2-03 | Catalog cache store + TTL + stale/offline behavior | Cache round-trip test; UI can render stale data with a warning | M1-04 | S | TODO |
| M2-04 | Download job pipeline: `.part`, progress, cancel, SHA-256 verify, cleanup | Unit tests; corrupted download rejected with no partial files | M1-06, M2-01 | M | TODO |
| M2-05 | Extraction/install strategies per kind: AppImage copy+exec bit, zip/tar safe-extract, dmg (S2), 7z (S1) | Real stable build installs on each OS; zip-slip/fixture guard tests | S1, S2, M2-04 | L | TODO |
| M2-06 | Detect bundled Python version on install (run interpreter, parse, store) | Version shown in build detail; handles missing interpreter gracefully | M2-05 | S | TODO |
| M2-07 | Versions UI: Installed / Available / Custom tabs, install dialog with preflight, progress, errors | Manual: install from UI on each OS; all states implemented | M1-07, M2-04, M2-05 | L | TODO |
| M2-08 | Custom build import: local file / URL, trust confirmation, optional label + checksum | Manual: import user file, launch pending M3; DB + files correct | M2-05 | M | TODO |
| M2-09 | Build delete / verify / "used by profiles" guard | Tests for guard; manual delete of unused build removes files | M2-05 | S | TODO |
| M2-10 | Startup reconciler: mark `missing`/`broken`, block launch, offer repair | Tests with removed dirs; UI badges | M1-04 | S | TODO |
| M2-11 | Linux FUSE detection + `APPIMAGE_EXTRACT_AND_RUN=1` fallback wiring (spec spike S6) | Manual on FUSE-less system; no crash | M1-08 | S | TODO |

Exit: stable FreeCAD installs from catalog and launches by hand on Linux, Windows, macOS;
corrupted download rejected; rate-limit/offline paths verified.

## M3 — Profiles and launch

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| M3-01 | Profile DAO/repository + name validation + build/Python binding rules | Unit tests for validation and binding rules | M1-04 | M | TODO |
| M3-02 | Profile lifecycle: create/duplicate/rename/delete with atomic directory creation | Tests for atomicity (no partial dirs on failure); delete cascades DB | M3-01 | M | TODO |
| M3-03 | Wire env builder into profile creation/launch; finalize per-OS isolation | Unit matrix green for all OSes; profile dirs verified by hand | M1-05, M3-02 | M | TODO |
| M3-04 | Launch runtime per build kind: AppImage (FUSE/fallback), archive, dmg, custom; macOS quarantine consent | Manual launch on each OS from a profile dir | M2-05, M2-11, M3-03 | L | TODO |
| M3-05 | Process tracking: running signal, launch log streaming, exit handling | Manual: running badge appears/disappears; log file contains output | M3-04 | M | TODO |
| M3-06 | Profiles UI: list/cards + detail tabs skeleton (Overview/Addons/Python/Macros/Config/Backups) | Navigable with real data; empty/loading/error states | M1-07, M3-02 | L | TODO |
| M3-07 | "Show launch command" viewer + copy (env + argv) | Manual: copied command launches the same isolated env | M3-03 | S | TODO |
| M3-08 | CLI mode in `main.dart`: `list`, `run <profile>`, `--version`, `--help`, arg passthrough after `--`, exit codes | Shell tests/manual on each OS; UI starts when no args | M1-06, M3-04 | M | TODO |
| M3-09 | CLI wrapper generation (`.sh` / `.cmd`) + PATH guidance + settings path | Manual: `freecad-launcher run` works from a fresh shell | M3-08 | M | TODO |
| M3-10 | Isolation E2E: two profiles, same build, independent config/Mod/macros/temp | Verified on each OS with screenshots/logs in session notes | M3-03, M3-04 | S | TODO |

Exit: two profiles are provably isolated; `freecad-launcher run <profile>` works from a fresh
shell; launch command viewer matches reality.

## M4 — Addons and Python

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| S3 | Spike: pip uninstall with `--target` (or decide install-only v0.1) | Written decision D-### with tested procedure | M1-02 | S | TODO |
| M4-01 | Addon catalog client + cache + parser per `addon_index_spec.md`; stats optional/non-fatal | Fixture tests for catalog zip parsing, branches, metadata; offline stale cache works | M1-10, M2-03 | M | TODO |
| M4-02 | Catalog UI: search (text + `#tag`), filters, grid, addon detail with branches and install action | Manual: search/filter/detail work offline against cache | M4-01 | L | TODO |
| M4-03 | Addon install engine: `zip_url` download, safe extract, place in `<profile>/Mod/<id>`, DB record | Real addon installs and loads in FreeCAD; zip-slip/bomb guard tests | M4-01, M2-04 | L | TODO |
| M4-04 | Branch selection, update detection, update (with backup) and remove | Manual: update an outdated addon; backup exists; remove cleans up | M4-03 | M | TODO |
| M4-05 | `requirements.txt` parser + consent dialog (install packages / addon only / cancel) | Unit tests for parser; manual consent flow | M4-03 | M | TODO |
| M4-06 | Interpreter discovery per build kind + pip runner (`--target`, streaming log, serialized jobs) | Real `pip install` works in a profile on each OS; module import verified in FreeCAD | M1-06, M2-06, S3 | M | TODO |
| M4-07 | Python packages UI + DB records + uninstall (per S3 decision) | Manual install/list/uninstall; per-profile isolation verified | M4-06 | M | TODO |
| M4-08 | Job queue UI: status bar summary, jobs view with progress/cancel/retry/logs | Manual: parallel downloads, cancel cleanup, retry | M2-04 | M | TODO |

Exit: installing a workbench with requirements works and the imported module exists only in
that profile; jobs UI is usable.

## M5 — Collections, macros, config, export

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| S4 | Spike: macro catalog source and license | Written decision D-### (repo/API, URL stability, license) | M1-02 | S | TODO |
| M5-01 | Bundles: model, DAO, CRUD UI, add/remove items | Unit tests; manual create/edit from a profile | M1-04 | M | TODO |
| M5-02 | Bundle apply: planner (install/update/skip/conflict), preview, sequential execution | Unit tests for planner; manual apply with summary of results | M5-01, M4-03 | M | TODO |
| M5-03 | Bundle export/import JSON (`spec 05 §4.1`) with validation and unresolved-item handling | Round-trip test incl. unknown addon ids | M5-01 | S | TODO |
| M5-04 | Macro catalog client + install single macro (per S4) | Manual install from catalog; file appears in profile scan | S4, M3-02 | M | TODO |
| M5-05 | Macro scanner (flat profile root + `Macro/`) + list/delete/reveal/open-external | Manual on each OS; DB reconciliation on startup | M5-04 | M | TODO |
| M5-06 | Config management: paths display, config backup/restore snapshots (FR-8.1/8.2) | Manual backup/restore round trip; backup list capped | M3-02 | M | TODO |
| M5-07 | Manifest export/import (`spec 05 §4.2`) + name-clash handling + absolute-path reporting | Cross-OS import test (Linux export → another OS import) | M3-02, M4-01, M4-06 | L | TODO |
| M5-08 | Profile detail wiring for Addons/Python/Macros/Config/Backups tabs | All tabs functional; no dead ends | M3-06, M4-03, M4-07, M5-05, M5-06 | S | TODO |

Exit: bundle round-trips between machines; macros appear only in their profile; manifest
import recreates the addon set.

## M6 — Updates and polish

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| M6-01 | Addon update checks + badges (profile, addon list) | Manual: outdated addon flagged; no auto-install | M4-04 | M | TODO |
| M6-02 | Build update checks + badges (stable channel) | Manual: newer stable release flagged | M2-02, M2-03 | S | TODO |
| M6-03 | Batch update flow ("Update all" with per-item toggles) | Manual batch through job queue with summary | M6-01, M6-02, M4-08 | M | TODO |
| M6-04 | Settings screen: theme, data dir, cadence, cache, logs, about, license | Manual full pass; settings persisted | M1-07 | M | TODO |
| M6-05 | Cache management: sizes, per-item clear, download cache retention | Manual: sizes accurate; clearing frees space; catalogs refetch | M2-03 | S | TODO |
| M6-06 | Debug bundle export (logs + versions + diagnostics, redacted) | Manual export review: no secrets, useful content | M1-08 | S | TODO |
| M6-07 | State coverage pass: loading/empty/filtered-empty/error/offline everywhere | Checklist in `VERIFICATION.md` completed per screen | M2-07, M4-02, M4-07, M5-08 | M | TODO |
| M6-08 | A11y + keyboard shortcuts + theme persistence | Keyboard map from `spec 03 §4` works; contrast/semantics spot-checked | M1-07 | M | TODO |
| M6-09 | Performance pass: startup < 2 s warm, no UI blocking on catalog loads | Measured timings recorded in session notes | M1-07, M2-03 | S | TODO |

Exit: `01-vision.md` success-criteria checklist passes manually.

## M7 — v0.1 release

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| S5 | Spike: reproducible Flutter AppImage build in CI | AppImage runs on clean Ubuntu/Fedora (with and without FUSE); zsync update info present; decision recorded | M1-09 | M | TODO |
| M7-01 | Productionize AppImage pipeline (`spec 07 §3`) | Tag build produces `FreeCADLauncher-<ver>-x86_64.AppImage` + sha256 | S5, M6-09 | M | TODO |
| M7-02 | Release workflow: matrix tests, changelog, release creation, checksums | Dry-run release from a RC tag succeeds | M7-01 | M | TODO |
| M7-03 | `LICENSE` (GPL-3.0-or-later) + `THIRD_PARTY_NOTICES.md` | Files present, SPDX headers added to sources | M1-02 | S | TODO |
| M7-04 | README + user guide (install, first run, profiles, addons, pip, export, troubleshooting) | Docs reviewed; screenshots current | M6-07 | M | TODO |
| M7-05 | Clean-machine validation on Linux VM | Success criteria checklist completed; issues filed as tasks | M7-02 | S | TODO |

Exit: published AppImage on GitHub releases; clean machine completes first-run flow.

## Backlog (post-MVP, scheduled when v0.1 is released)

| ID | Task | Spec ref | Target |
|---|---|---|---|
| B-01 | Weekly + legacy channels (catalog UI, installation) | FR-1.7 | v0.2 |
| B-02 | In-place build updates (install alongside → switch → cleanup) | FR-1.8, spec 04 §7 | v0.2 |
| B-03 | Full profile export (zip with payload toggles) | FR-9.2 | v0.2 |
| B-04 | Preference browser + config reset + raw XML advanced editor | FR-8.3, FR-8.4 | v0.2 |
| B-05 | Macro run via `FreeCADCmd` with output panel | FR-7.5 | v0.2 |
| B-06 | Launcher self-update for AppImage | FR-10.5, spec 07 §5 | v0.2 |
| B-07 | GitHub token UX with secure storage (OQ-3) | FR-12.2 | v0.2 |
| B-08 | Profile templates | FR-2.8 | v0.2 |
| B-09 | CLI addon/bundle subcommands | FR-3.5 | v0.2 |
| B-10 | Local addon zip install (developer mode) | FR-4.8 | v0.2 |
| B-11 | Windows/macOS launcher artifacts (OQ-1) | spec 07 §2 | v0.2 |
| B-12 | i18n translations (if OQ-6 = start later) | NFR-9 | v1.0 |
| B-13 | Fully isolated private-build profiles (OQ-8) | spec 09 | post-v1.0 |
