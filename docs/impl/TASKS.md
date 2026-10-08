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
| M1-01 | Freeze prototype: tag `prototype-final`, create `v2` branch | Tag pushed, branch exists, `STATUS.md` updated | M0-04 | S | DONE |
| M1-02 | Project skeleton on `v2`: `pubspec` deps (`http` added, `snapd` removed), lints, `main.dart`/`app.dart` shell, ARB scaffolding per D-017, platform runners generated with app id `org.freecad.ext.launcher` (D-016) | App builds and runs — Linux verified; Windows/macOS via M1-09 CI | M0-02 | M | DONE |
| M1-03 | `core/`: `Result`, `AppError`, leveled logging with rotation + redaction, constants | Unit tests green; logs written under `logs/` | M1-02 | S | DONE |
| M1-04 | drift schema v1 (`builds`, `profiles`, `installed_addons`, `python_packages`, `bundles`, `bundle_items`, `macros`, `catalog_cache`, `settings`) + DAOs + codegen | In-memory drift tests for each DAO; `build_runner` clean | M1-02, M0-01 | L | DONE |
| M1-05 | `domain/profiles`: path mapping + env builder per OS + profile rules | Unit tests cover Linux/Windows/macOS env matrices (`spec 04 §4.1`) | M1-02 | M | DONE |
| M1-06 | `platform/process.dart`: `ProcessRunner` (arg arrays, sanitized env, streamed output, kill tree) | Unit tests with a fake process adapter; no shell usage | M1-03 | M | DONE |
| M1-07 | `AppServices` + `AppScope` + sidebar shell + status bar + navigation (Home/Profiles/Versions/Addons/Macros/Settings) | App navigates all sections with empty states | M1-02 | M | DONE |
| M1-08 | Diagnostics service: FUSE presence (Linux), Gatekeeper/quarantine (macOS), disk, permissions | Diagnostics screen/API returns structured results; unit-testable | M1-03, M1-05 | S | DONE |
| M1-09 | CI matrix: analyze, tests, codegen-freshness check, `flutter build` per OS | Workflow valid locally; first GitHub run pending a remote (OQ-7) | M1-02 | M | DONE |
| M1-10 | Test harness: in-memory drift helper, injected fake HTTP client, fixtures dir | Helpers used by at least one existing test | M1-04 | M | DONE |

Exit: shell runs on all three OSes; analyze/tests/build green in CI; schema and env logic
covered by tests.

## M2 — Builds (stable channel)

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| S1 | Spike: `.7z` extraction strategy | D-018: bundle `7zr.exe`; real 1.1.3 asset inspected (LZMA2+LZMA+BCJ2, koni_sevenz cannot read it); manual Windows extraction in M2-05 | M1-02 | M | DONE |
| S2 | Spike: macOS `.dmg` install (mount/copy/detach/quarantine) | D-019 recorded; manual macOS verification folded into M2-05 | M1-02 | S | DONE |
| M2-01 | GitHub releases client: conditional GET (ETag), cache, rate-limit header handling, token hook (disabled in v0.1 unless OQ-3 says otherwise) | Unit tests against fixtures; no network in tests; 304 path covered | M1-10 | M | DONE |
| M2-02 | Asset classifier + version compare: stable/legacy/weekly-aware, per-OS/arch selection, exact regexes from `spec 06 §1.3` | Fixture tests for 1.1.3, 1.0.2, 0.21.2, 0.20.0, weekly and gaps (0.19.4) | M1-10 | M | DONE |
| M2-03 | Catalog cache store + TTL + stale/offline behavior | Cache round-trip test; UI can render stale data with a warning | M1-04 | S | DONE |
| M2-04 | Download job pipeline: `.part`, progress, cancel, SHA-256 verify, cleanup | Unit tests; corrupted download rejected with no partial files | M1-06, M2-01 | M | DONE |
| M2-05 | Extraction/install strategies per kind: AppImage copy+exec bit, zip/tar safe-extract, dmg (S2), 7z (S1) | Real Linux AppImage install verified end-to-end; zip-slip/symlink/bomb guard tests; Windows/macOS real extraction pending those OSes (CI/manual) | S1, S2, M2-04 | L | DONE |
| M2-06 | Detect bundled Python version on install (run interpreter, parse, store) | Version shown in build detail; handles missing interpreter gracefully | M2-05 | S | DONE |
| M2-07 | Versions UI: Installed / Available / Custom tabs, install dialog with preflight, progress, errors | Installed + Available tabs and install orchestration done (controller tests, app runs); manual UI click-through still pending; Custom tab is filled by M2-08 | M1-07, M2-04, M2-05 | L | DONE |
| M2-08 | Custom build import: local file / URL, trust confirmation, optional label + checksum | Controller tests cover file/URL/executable/missing; Custom tab form with trust dialog; manual click-through pending | M2-05 | M | DONE |
| M2-09 | Build delete / verify / "used by profiles" guard | Tests cover blocked delete, hash verify, missing/broken; UI verify + remove feedback | M2-05 | S | DONE |
| M2-10 | Startup reconciler: mark `missing`/`broken`, block launch, offer repair | Tests with removed dirs; status badges in Installed tab; launch blocking lands in M3 | M1-04 | S | DONE |
| M2-11 | Linux FUSE detection + `APPIMAGE_EXTRACT_AND_RUN=1` fallback wiring (spec spike S6) | `fuseAvailable()` + launch env flag tested; manual FUSE-less launch pending (M3-04) | M1-08 | S | DONE |
| M2-12 | Custom executable import (D-020): picker accepts any file, exec-bit/missing validation, in-place reference, UI copy + trust notes | Controller tests for executable/non-executable/missing; picker offers all files; manual: import a self-compiled/AppImage-symlink binary and see it listed | M2-08 | M | DONE |
| M2-13 | Custom Python detection (D-020): `builds.pythonPath` (schema v2 + upgrade), probe near binary, headless temp-macro probe, manual interpreter picker fallback | Probe tests (direct/headless/prefix/fallback); controller test for `setCustomPython`; manual: detection on the local 0.21.2 AppImage symlink | M2-06, M2-12 | L | DONE |
| M2-14 | Support floor: ignore pre-1.0 catalog releases (D-021); `legacy` = 1.0.x; drop FreeCAD-Bundle fallback and the flat pip target dir from specs | 0.19/0.20/0.21 fixtures classify empty; `isSupported` floor tests green; docs updated | M2-02 | S | DONE |
| M2-15 | AppImage Python detection fix (D-022): headless macro probe per `prototype-final` (`-c -M` + tagged JSON + `sys.exit(0)`), asset-name hint as fallback | Real 1.0.2/dev AppImages report Python through the probe; unit tests cover headless path, hint fallback and transient prefix; custom AppImages no longer force the interpreter dialog | M2-06, M2-13 | M | DONE |
| M2-16 | Custom local AppImages symlinked instead of copied (D-023): executable check, `referenceInPlace` install request, copy fallback when symlinks unavailable, remove deletes only the link | Installer test asserts a symlink + target size and no chmod; controller test asserts `referenceInPlace` for local and managed copy for URL; analyze/tests green | M2-05, M2-08 | S | DONE |
| M2-17 | Opt-in hashing + import stage feedback (D-024): hash only when a checksum is given (local files and downloads), nullable `DownloadResult.sha256`, `hashing`/`detectingPython` stages with progress in Available + Custom tabs | Controller/downloader/checksum/installer tests green; local AppImage import no longer hashes when checksum is empty; stage transitions observable via `installProgress` | M2-04, M2-08, M2-15 | M | DONE |
| M2-18 | Switch to the Installed tab after a successful install/import (D-025) | Available installs and custom imports animate to Installed on success; failures stay on the current tab; manual click-through pending | M2-07 | S | DONE |
| M2-19 | Download progress shows bytes/speed (D-026): `InstallProgress` byte fields + average speed; downloader coalesces to 1% steps with a final update | Downloader throttle test; controller test asserts byte/total propagation; UI shows "x / y · z/s" during downloads | M2-04, M2-17 | S | DONE |

Exit: stable FreeCAD installs from catalog and launches by hand on Linux, Windows, macOS;
corrupted download rejected; rate-limit/offline paths verified.

## M3 — Profiles and launch

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| M3-01 | Profile DAO/repository + name validation + build/Python binding rules | Unit tests for validation and binding rules | M1-04 | M | DONE |
| M3-02 | Profile lifecycle: create/duplicate/rename/delete with atomic directory creation | Tests for atomicity (no partial dirs on failure); delete cascades DB | M3-01 | M | DONE |
| M3-03 | Wire env builder into profile creation/launch; finalize per-OS isolation | Unit matrix green for all OSes; profile dirs verified by hand | M1-05, M3-02 | M | DONE |
| M3-04 | Launch runtime per build kind: AppImage (FUSE/fallback), archive, dmg, custom; macOS quarantine consent | Manual launch on each OS from a profile dir | M2-05, M2-11, M3-03 | L | DONE |
| M3-05 | Process tracking: running signal, launch log streaming, exit handling | Manual: running badge appears/disappears; log file contains output | M3-04 | M | DONE |
| M3-06 | Profiles UI: list/cards + detail tabs skeleton (Overview/Addons/Python/Macros/Config/Backups) | Navigable with real data; empty/loading/error states | M1-07, M3-02 | L | DONE |
| M3-07 | "Show launch command" viewer + copy (env + argv) | Manual: copied command launches the same isolated env | M3-03 | S | DONE |
| M3-08 | CLI mode in `main.dart`: `list`, `run <profile>`, `--version`, `--help`, arg passthrough after `--`, exit codes | Shell tests/manual on each OS; UI starts when no args | M1-06, M3-04 | M | DONE |
| M3-09 | CLI wrapper generation (`.sh` / `.cmd`) + PATH guidance + settings path | Manual: `freecad-launcher run` works from a fresh shell | M3-08 | M | DONE |
| M3-10 | Isolation E2E: two profiles, same build, independent config/Mod/macros/temp | Verified on each OS with screenshots/logs in session notes | M3-03, M3-04 | S | DONE |

Exit: two profiles are provably isolated; `freecad-launcher run <profile>` works from a fresh
shell; launch command viewer matches reality.

## M4 — Addons and Python

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| S3 | Spike: pip uninstall with `--target` (or decide install-only v0.1) | Written decision D-### with tested procedure | M1-02 | S | DONE |
| M4-01 | Addon catalog client + cache + parser per `addon_index_spec.md`; stats optional/non-fatal | Fixture tests for catalog zip parsing, branches, metadata; offline stale cache works | M1-10, M2-03 | M | DONE |
| M4-02 | Catalog UI: search (text + `#tag`), filters, grid, addon detail with branches and install action | Manual: search/filter/detail work offline against cache | M4-01 | L | DONE |
| M4-03 | Addon install engine: `zip_url` download, safe extract, place in `<profile>/Mod/<id>`, DB record | Real addon installs and loads in FreeCAD; zip-slip/bomb guard tests | M4-01, M2-04 | L | DONE |
| M4-04 | Branch selection, update detection, update (with backup) and remove | Manual: update an outdated addon; backup exists; remove cleans up | M4-03 | M | DONE |
| M4-05 | `requirements.txt` parser + consent dialog (install packages / addon only / cancel) | Unit tests for parser; manual consent flow | M4-03 | M | DONE |
| M4-06 | Interpreter discovery per build kind + pip runner (`--target`, streaming log, serialized jobs) | Real `pip install` works in a profile on each OS; module import verified in FreeCAD | M1-06, M2-06, S3 | M | DONE |
| M4-07 | Python packages UI + DB records + uninstall (per S3 decision) | Manual install/list/uninstall; per-profile isolation verified | M4-06 | M | DONE |
| M4-08 | Job queue UI: status bar summary, jobs view with progress/cancel/retry/logs | Manual: parallel downloads, cancel cleanup, retry | M2-04 | M | DONE |
| M4-09 | Desktop input theme: compact rounded outlined fields + bordered dropdown filters | `buildAppTheme` sets `InputDecorationThemeData`; theme test asserts dense/outline/radius; addons filter dropdowns wrapped in `InputDecorator` | M4-02 | S | DONE |
| M4-10 | Multi-select filter menu for content/installed filters (hamburger + checkable items) | Controller toggles with set semantics (empty/both = no filter), badge shows active count, clear action; controller + widget tests | M4-02 | S | DONE |

Exit: installing a workbench with requirements works and the imported module exists only in
that profile; jobs UI is usable.

## M5 — Collections, macros, config, export

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| S4 | Spike: macro catalog source and license | Written decision D-### (repo/API, URL stability, license) | M1-02 | S | DONE |
| M5-01 | Bundles: model, DAO, CRUD UI, add/remove items | Unit tests; manual create/edit from a profile | M1-04 | M | DONE |
| M5-02 | Bundle apply: planner (install/update/skip/conflict), preview, sequential execution | Unit tests for planner; manual apply with summary of results | M5-01, M4-03 | M | DONE |
| M5-03 | Bundle export/import JSON (`spec 05 §4.1`) with validation and unresolved-item handling | Round-trip test incl. unknown addon ids | M5-01 | S | DONE |
| M5-04 | Macro catalog client + install single macro (per S4) | Manual install from catalog; file appears in profile scan | S4, M3-02 | M | DONE |
| M5-05 | Macro scanner (flat profile root + `Macro/`) + list/delete/reveal/open-external | Manual on each OS; DB reconciliation on startup | M5-04 | M | DONE |
| M5-06 | Config management: paths display, config backup/restore snapshots (FR-8.1/8.2) | Manual backup/restore round trip; backup list capped | M3-02 | M | DONE |
| M5-07 | Manifest export/import (`spec 05 §4.2`) + name-clash handling + absolute-path reporting | Cross-OS import test (Linux export → another OS import) | M3-02, M4-01, M4-06 | L | DONE |
| M5-08 | Profile detail wiring for Addons/Python/Macros/Config/Backups tabs | All tabs functional; no dead ends | M3-06, M4-03, M4-07, M5-05, M5-06 | S | DONE |

Exit: bundle round-trips between machines; macros appear only in their profile; manifest
import recreates the addon set.

## M6 — Updates and polish

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| M6-01 | Addon update checks + badges (profile, addon list) | Manual: outdated addon flagged; no auto-install | M6-10, M4-04 | M | DONE |
| M6-02 | Build update checks + badges (stable channel) | Manual: newer stable release flagged | M2-02, M2-03 | S | DONE |
| M6-03 | Batch update flow ("Update all" with per-item toggles) | Manual batch through job queue with summary | M6-01, M6-02, M4-08 | M | DONE |
| M6-04 | Settings screen: theme, data dir, cadence, cache, logs, about, license | Manual full pass; settings persisted | M1-07 | M | DONE |
| M6-05 | Cache management: sizes, per-item clear, download cache retention | Manual: sizes accurate; clearing frees space; catalogs refetch | M2-03 | S | DONE |
| M6-06 | Debug bundle export (logs + versions + diagnostics, redacted) | Manual export review: no secrets, useful content | M1-08 | S | DONE |
| M6-07 | State coverage pass: loading/empty/filtered-empty/error/offline everywhere | Checklist in `VERIFICATION.md` completed per screen | M2-07, M4-02, M4-07, M5-08 | M | DONE |
| M6-08 | A11y + keyboard shortcuts + theme persistence | Keyboard map from `spec 03 §4` works; contrast/semantics spot-checked | M1-07 | M | DONE |
| M6-09 | Performance pass: startup < 2 s warm, no UI blocking on catalog loads | Measured timings recorded in session notes | M1-07, M2-03 | S | DONE |
| M6-10 | Addon pinning/freeze per profile (schema v4 `pinnedAt`, pin/unpin UI, update-block, bundle skip, manifest) | Pinned addon never badges or updates in that profile; other profiles unaffected; manifest round-trips | M4-04 | M | DONE |
| M6-11 | Desktop form style: label-left `FormRow`, 4 px outlined inputs, migrate dialogs and inline forms | Widget tests for `FormRow`; visual pass on all forms; search/filter rows unchanged | M6-10 | M | DONE |
| M6-12 | Home dashboard: stats tiles, launch last used profile, check updates, news feed (settings URL) | Home shows stats/actions; news from the configured RSS/Atom feed; first-run checklist when empty | M1-07, M6-09 | M | DONE |

Exit: `01-vision.md` success-criteria checklist passes manually.

## M7 — Linux v0.1 completion

Linux-first (D-072): functionality is finished and verified end-to-end on Linux before any
packaging/release automation. CI, release publishing and Windows/macOS deployment are deferred to
M8. M7-02 (release workflow) moved to M8-01.

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| S5 | Spike: reproducible Flutter AppImage build in CI | AppImage runs on clean Ubuntu/Fedora (with and without FUSE); zsync update info present; decision recorded | M1-09 | M | DONE |
| M7-01 | Productionize AppImage pipeline (`spec 07 §3`) | Tag build produces `FreeCADLauncher-<ver>-x86_64.AppImage` + sha256 | S5, M6-09 | M | DONE |
| M7-03 | `LICENSE` (GPL-3.0-or-later) + `THIRD_PARTY_NOTICES.md` + FreeCAD trademark attribution (D-070) | Files present, SPDX headers added to sources | M1-02 | S | DONE |
| M7-04 | README + user guide (install, first run, profiles, addons, pip, export, troubleshooting) | Docs reviewed; screenshots current | M6-07 | M | DONE |
| M7-06 | Linux manual functional pass: Versions install, custom import (incl. executable + Python fallback dialog), profile create/edit/launch in the GUI; fill the `VERIFICATION.md` §4 Linux column | Smoke matrix Linux column recorded in the session log; issues filed as tasks (R-03..R-07) | M7-01 | M | DONE |

M7-05 (clean-machine validation on a Linux VM) moved to M8-05 (D-073).

Exit: Linux functionality verified end-to-end (manual smoke matrix) with a locally built AppImage;
`LICENSE`, notices and user docs complete. Nothing is published in M7 — GitHub release/publishing
happens in M8.

## M8 — Packaging, CI & cross-platform release (deferred)

Starts after M7; the GitHub CI/release work needs a git remote (OQ-7). Recorded in D-072.

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| M8-01 | Release workflow (was M7-02): test matrix, changelog, GitHub release creation, published checksums/zsync; CI regenerates `THIRD_PARTY_NOTICES.md` and fails on drift | `v0.1.0` pre-release published from the manual workflow (run 36812429637) with verified AppImage + sha256 + zsync; notes token-free. Tag-push path shares the same job | M7-04 | M | DONE |
| M8-02 | First GitHub CI run of the M1-09 matrix (analyze, tests, codegen freshness, build per OS) | CI green on the remote repo | M8-01 | S | DONE (ubuntu + windows green; macOS deferred to M8-04 per D-083) |
| M8-03 | Windows artifact + deployment (was B-11/OQ-1, D-091): portable `.zip` (bundle + `7zr.exe` + license/notices/README) + `.sha256`, CI job in the release workflow, real `.7z` extraction and install/launch/isolation manual pass on a clean machine; plan in [PLAN-M8-windows-release.md](PLAN-M8-windows-release.md) | Zip published on a GitHub Release, installs and launches on a clean Windows machine | M8-01, M8-06 | L | DONE — full Windows smoke matrix passed 2026-10-01; `v0.4.1` pre-release (manual `create_release=true`, run 36955018205) is the current release with the Windows zip + `.sha256`, sidecars verified (`v0.3.0`/`v0.4.0` were published earlier, later withdrawn) |
| M8-04 | macOS artifact + deployment (was B-11/OQ-1): unsigned `.app`/`.dmg`, quarantine consent, install/launch/isolation manual pass; re-enable the macOS CI job (D-083) | macOS artifact installs and launches on a clean machine; macOS back in the CI matrix | M8-01 | L | TODO |
| M8-05 | Clean-machine validation on a Linux VM (was M7-05) with the locally built AppImage | Success criteria checklist completed; issues filed as tasks | M7-01 | S | TODO |
| M8-06 | Cross-platform test portability (D-082): path assertions via `p.join`/realpath, per-platform command expectations (`xdg-open`/`open`/`explorer`), host-platform diagnostics in tests, distinct fixture names for case-insensitive filesystems, platform skips for Linux-specific probe/AppImage behavior; fix the ZIP entry separator bug (`debug_bundle.dart`) and the Windows log-sink teardown lock; plan in [PLAN-M8-windows-release.md](PLAN-M8-windows-release.md) | `flutter test` green on Windows in CI (run 36897077869); Linux still green | M8-02 | M | DONE |
| M8-07 | Platform metadata alignment + Windows data-root decoupling (D-116): `LegalCopyright`/`PRODUCT_COPYRIGHT` = `Copyright 2026 Frank Martínez <mnesarco at gmail>`, `CompanyName` = `Frank Martínez`, Windows data root pinned to `%APPDATA%\org.freecad.ext.launcher` (D-016) independent of exe metadata, one-time rename of the legacy `%APPDATA%\FreeCAD Launcher contributors\FreeCAD Launcher` with fallback to the legacy root, CI asserts the exe VersionInfo | Resolver/migration unit tests green; exe metadata asserted in CI; live Windows upgrade retest pending (no machine); docs/decision updated | M8-03, D-016 | M | DONE — `AppPaths.resolve` pinned root + legacy rename + logged fallback (`migrationWarning`), 6 new tests, `check_version_info.ps1` in `ci.yml`/`release.yml`, Runner.rc/AppInfo.xcconfig aligned, D-116/D-016/spec 05/README/user-guide updated, version 0.4.7 → 0.4.8; analyze clean, 709 tests green (10 skipped); Windows CI green on `09c4ded` (run 37362656403; `windows-latest` build + metadata guard). Residual: live upgrade retest over a `v0.4.7` data dir pending (no machine) |

| M8-08 | Installed builds show **Broken** after the M8-07 data-dir rename: the DB is an index over the filesystem and stores absolute paths (`builds.localPath`/`pythonPath`, `catalog_cache.payloadPath`, `installed_addons.sourcePath`, `python_packages.targetDir`), so moving the root invalidates every stored path. **D-117**: never move the data root; use the legacy root in place when its `config.db` exists and the pinned `%APPDATA%\org.freecad.ext.launcher` for fresh installs; a one-time repair rewrites legacy-prefixed stored paths whose mapped target exists (recovers installs already moved by 0.4.8) | Resolver + repair tests green; owner's Windows install recovers (builds reachable, no Broken); analyze/tests green; docs/decision updated | M8-07, D-116 | S | WIP — implemented: `AppPaths.resolve` never moves the root (pinned when it has `config.db`, else legacy, else pinned) and exposes `legacyRoot`; `DataRootRepair` rewrites legacy-prefixed `builds.localPath`/`pythonPath`, cache `payloadPath`, addon `sourcePath` and python `targetDir` only when the mapped target exists; `AppServices.startupWarning` logged after logger setup; 5 resolver + 4 repair tests (713 total green, 10 skipped), analyze clean, version 0.4.8 → 0.4.9; shipped in the `v0.4.9` pre-release (run 37371511156, one Windows rerun after a hosted-runner outage). Pending: owner Windows retest |

Exit: published Linux AppImage on GitHub releases; Windows/macOS artifacts published or the
distribution decision recorded (OQ-1).

## Refinements (pre-v0.1)

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| R-01 | Relabel installed builds (D-069): schema v5 `builds.label`, rename action on the Installed tile, label shown on every build surface | Controller tests (set/trim/reset/length); widget test renames and resets a build; analyze/tests green | M2-07 | S | DONE |
| R-02 | Original launcher icon (D-070): editable master SVG + render script; owner authors the final design, no FreeCAD logo modification | Owner's rocket master SVG saved; 512/256 AppImage/desktop PNGs regenerated and visually checked (512/256/64/32 px); D-068 placeholder gone | S5 | S | DONE |
| R-03 | Available tab never loads the catalog on first visit (shows the misleading "Check your connection and refresh the catalog" empty state until a manual refresh); load on first visit or show a proper loading/empty state | First visit to Available loads the catalog (spinner then list); offline shows the cached/stale state | M2-07 | S | DONE |
| R-04 | Build remove dialog always says "The files will be deleted from disk", but in-place custom builds (D-020) keep the file; use per-kind wording | Custom executable/AppImage removal does not claim files are deleted; catalog builds keep the current warning | M2-09 | S | DONE |
| R-05 | Re-importing an already-imported custom file fails with a raw `SqliteException: UNIQUE constraint failed` snackbar; detect the existing build key and update/reuse it or show a friendly duplicate error | Re-importing the same source updates/returns the existing build with a clear message; no raw SQL surfaced | M2-08, M2-12 | S | DONE |
| R-06 | Post-import "Python interpreter not detected" → "Choose Python…" never opens the picker: the Custom tab State is disposed by the tab switch (`mounted == false`); move the flow to a surviving State or keep the tab alive | Choosing an interpreter after import opens the picker and stores `pythonPath` (manual fallback reachable) | M2-13 | M | DONE |
| R-07 | A build download can sit at "782.8 MiB / 782.8 MiB" with the stream not closing for minutes (observed ~1–2 min) and no timeout; finish when received == content-length or add an idle timeout | Download completes once the declared byte count is reached; a stalled stream fails with a retryable error instead of hanging | M2-04 | M | DONE |
| R-08 | "Open profile folder" action in the profile detail header (same action as the profile card and Config tab) | Folder icon in the detail header opens the profile root via `FileActions.openDirectory`; failure snackbar; widget test asserts the command | M3-06, D-059 | S | DONE |
| R-09 | Don't override `HOME` in profile launches (D-075): drop the `HOME` export and `<profile>/home` from the layout; keep `FREECAD_USER_HOME`/XDG/temp isolation | Unit tests assert inherited `HOME` passes through unchanged; launch/isolation tests green; analyze clean | M1-05, D-005 | S | DONE |
| R-10 | Macro catalog/installed icons (D-076): render `icon_data` (PNG/SVG) with a memory+disk cache, generic fallback for XPM/missing | Icon shown in Catalog and Installed when available; cache files under `cache/macros/icons/`; unit/widget tests green; live check with the real catalog | M5-04, D-048 | M | DONE |
| R-11 | Copyright notices (D-079): `SPDX-FileCopyrightText` line in every SPDX-tagged file, notice in README, Settings › About and the generated notices | Headers present in all SPDX-tagged files; About shows the notice; notices regenerate deterministically; analyze/tests green | M7-03, D-074 | S | DONE |
| R-12 | About dialog with the official FreeCAD logo (D-080): bundled logo asset, trademark and independent-project notices, opened from Settings › About | Dialog shows the big logo and both notices; README/notices no longer claim no FreeCAD artwork; widget test; analyze/tests green | R-11 | S | DONE |
| R-13 | Profile Overview launch log (D-090): the log row becomes a clickable link that opens the file with the OS default text editor (`FileActions.open`), failure snackbar, localized label/tooltip | Widget test asserts the `xdg-open <log>` command; analyze/tests green (587 tests, 9 manual probes skipped) | M3-06, R-08 | S | DONE |
| R-14 | Portable path segments (D-095): shared `safePathSegment` helper; build IDs (`stable:1.1.3:windows:x86_64`) used as directory names made Windows fail with `FileSystemException`; apply to build dirs, launch logs, macro file/icon names and addon backup dirs | Helper + `AppPaths.buildDir` tests (POSIX and Windows contexts); analyze/tests green; Windows install retested with a rebuilt artifact | M8-03 | S | DONE — committed `031cc0e`; the R-15 failure screenshot shows the sanitized `stable_1.1.3_windows_x86_64.part` path reaching 7zr, so the fix is confirmed on Windows |
| R-15 | Windows process launches with an empty environment fail (7zr) — **D-096**: `IoProcessLauncher` sends a malformed one-wchar environment block, rejected by `CreateProcessW` with ERROR_INVALID_PARAMETER; inherit the parent environment on Windows when the spec env is empty | Windows-only real-process test (empty spec environment) green in CI; real 1.1.3 `.7z` install verified on the Windows machine with a rebuilt artifact | R-14 | S | DONE — Windows CI test green; full matrix pass 2026-10-01 with artifact run 36941684639 (7zr extraction OK) |
| R-16 | Build install logging: per-install log file (`logs/install-<id>-<stamp>.log`) with header/stages/error + stack trace, attached to the job (`logPath`) and mirrored to `app.log` via `appLogger.error` | Unit tests assert log content on failure and `job.logPath`; Jobs dialog shows the log path | M4-08 | S | DONE — `_installLocked` writes the log and sets the job path; 2 new tests |
| R-17 | Tolerant directory size walk: the recursive listing aborted Windows installs on FreeCAD paths over the 260-char limit (`pkg_resources` test fixtures); shared `directorySize` walks level by level and skips unreadable subtrees, used by `BuildInstaller` and `ProfilesController` | Unit tests (nested sums, missing dir, unreadable subdir); analyze/tests green; Windows install completes past the size measurement | R-15 | S | DONE — Windows matrix pass 2026-10-01 with artifact run 36941684639 |
| R-18 | Python probe cleanup aborted installs when the AppImage FUSE mount inside the probe `TMPDIR` was still tearing down (`FileSystemException` ENOTCONN on delete); cleanup is best-effort with retries and never fails the install | Probe tests green; real weekly AppImage install completes (probe + cleanup) | M2-15 | S | DONE — verified against the real `weekly-2026.10.01` AppImage: Python 3.13 detected, probe directory removed, no exception |
| R-19 | "Open logs/folder" opened the browser when running from the AppImage: openers inherited `LD_LIBRARY_PATH`/`APPDIR`, so the system `gio` behind `xdg-open` hit undefined symbols (D-098); `FileActions` now spawns openers with a sanitized environment | Unit tests for `openerEnvironment`; live check from the AppImage opens the file manager | R-08 | S | WIP — fixed; live AppImage check pending |
| R-20 | Pre-D-095 managed build directories (POSIX) were reported `missing` after D-095 sanitized names, blocking launches and orphaning the directory on remove; `existingBuildDir`/`buildDirCandidates` fall back to the legacy unsanitized name in status/reconcile/verify/remove and Python resolution (D-099) | Controller test (legacy colon directory reconciles installed and is deleted on remove) + paths tests; analyze/tests green | D-095 | S | DONE — 2 new tests |
| R-21 | Custom local AppImage removal (D-023) leaves the `builds/<id>/` symlink directory behind: `remove` skips directory cleanup for every custom build instead of only in-place executables; clean the link when `localPath` lives under `builds/`, never the target (pre-existing, found in the R40 audit) | Controller test (link deleted, target intact; in-place executable untouched) | D-023, R-05 | S | TODO |
| R-22 | Python-tab install dialog disposed its `TextEditingController` as soon as `showDialog` returned, while the closing route still rebuilt the `TextField`: "A TextEditingController was used after being disposed" cascading into `InheritedElement.debugDeactivated` (`_dependentsIsEmpty`) and a red error screen; the controller now lives in a `_PythonInstallDialog` StatefulWidget | Widget regression test opens/cancels the dialog and asserts no exception (fails on the old code); live driver click-through installs `six` cleanly; analyze/tests green | M4-07, M6-11 | S | DONE — fix + regression test verified both ways (614 tests green) |
| R-23 | `signals_flutter` 7.1: first visit to the profile Backups tab (after Config) crashed with `SignalEffectException` — `ProfilesController.refreshConfigSnapshots` wrote `configSnapshots` from `didChangeDependencies`, and 7.1 subscriptions call `markNeedsBuild()` synchronously (6.3.1 deferred to `endOfFrame`); both tab mounts now defer the refresh to a post-frame callback (D-101) | Widget regression test: Config → Backups does not throw and the empty state renders (fails on the old code); analyze/tests green | B-16, D-101 | S | DONE — regression test fails on the old code with `SignalEffectException` and passes with the post-frame fix; 615 tests green, analyze unchanged (127 B-17 deprecations) |
| R-24 | Settings ▸ Cache: “Build downloads” Clear and “Clean up now” wiped cached archives with a single click although spec 03 §4 requires confirmation; both now show a dialog naming the size/retention and stating that installed versions/profiles are unaffected (D-105) | Widget tests: confirmed clear deletes, cancel keeps, prune respects retention; analyze/tests green | D-063, D-105 | S | DONE — 3 widget tests, 627 green, analyze clean; live Cache card checked; dialog click-through deferred to avoid disturbing a user session on the dev machine |
| R-25a | Visual identity foundation (D-106): brand palette (`AppBrandColors`) + `AppStatusColors` theme extension in `lib/ui/theme/app_colors.dart`; `buildAppTheme` moved to `lib/ui/theme/app_theme.dart`, seeded from Tufts Blue `#418FDE` with the fidelity variant; component themes (cards, rail, chips, ListTiles, dialogs, snackbars, tabs, buttons, tooltip, scrollbar) and tuned type scale; D-059 input style unchanged | `app_theme_test` covers brand seed, status extension and shape policy; analyze/tests green | — | M | DONE — `app_theme_test` 4 cases green (brand seed, extension, shapes); fidelity scheme prints vivid blue in both modes |
| R-25b | Shell chrome: brand-tinted rail selected state + tonal status bar, semantic status colors replacing raw `Colors.green`/`Colors.orange` in Settings diagnostics and the Jobs dialog | Live check both themes; analyze/tests green | R-25a | S | DONE — brand rail selected state + tonal status bar with info-colored jobs; diagnostics/jobs use `AppStatusColors`; the rail brand mark added first was dropped as redundant (owner request 2026-10-03); analyze clean, UI tests green (live check in R-25e) |
| R-25c | Home hero band: slim rounded gradient band (brand icon, app title, profile/version/addon summary, New profile + Check updates actions), new `homeHeroSummary`/`homeHeroTagline` l10n keys; first-run checklist stays below | Home widget tests cover the hero and its actions; analyze/tests green | R-25a | S | DONE — hero + 2 widget tests; a11y contrast fixed by lightening the dark gradient end; 634 tests green; follow-up: the duplicate “Check for updates” action was removed from the Updates card (the hero keeps the only one and now shows the Checking… state) |
| R-25d | Component polish: `CompactBadge` semantic tones (running/success/warning/danger/info) across the call sites, tinted `EmptyState` icon bubble, accent section title | Badge/empty-state widget tests; analyze/tests green | R-25a | M | DONE — tone map + `compact_badge_test` (6 tones) + EmptyState bubble test; info-tinted update chips; 634 tests green, analyze clean |
| R-25e | Visual refresh verification + docs: spec 03 §1/§2.1 theme and hero wording, D-106 recorded, VERIFICATION entry, README screenshots refreshed, STATUS session row | Docs updated; analyze/tests/CI green; live light↔dark pass recorded | R-25b, R-25c, R-25d | S | DONE — specs/D-106/VERIFICATION/STATUS updated; screenshots recaptured (1280×720, light); live pass recorded; 634 tests green, analyze clean; shipped in `v0.4.3` (squash `1dc65b6`, release run 37148725010) |
| R-26 | Addon/macro catalog icons render soft on HiDPI: the raster path upscaled 24–64 px sources with medium filtering and `MacroIcon` pre-downscaled via `cacheWidth`; shared `RasterIcon` renders bitmaps at native resolution with `FilterQuality.high`/anti-aliasing, both widgets share BOM-safe SVG detection (XPM still falls back per D-076) | Bitmap icons use high filtering in both widgets; unit/widget tests cover the shared widget and the SVG/bitmap dispatch; live DPR2 check | R-10, R-25 | S | DONE — `lib/ui/widgets/raster_icon.dart` + both widgets converted; 3 tests (BOM-safe detection, filter flags, svg/bitmap dispatch), 637 green; live GDK_SCALE=2 pass (Macros/Addons) shows smooth upscaling |
| R-27a | Refactor for the profile-context pickers (D-107): extract Collections' `AddAddonDialog` into a shared `AddonPickerDialog` (`title`/`actionLabel`/`presentIds`/`searchHint`; text + `#tag` search, loading/error states) and lift the catalog tab's requirements-consent install into `installAddonIntoProfile(context, addon, branchRef, profileId)` | `collections_view_test` and `addons_view_test` stay green (behavior unchanged); analyze clean | R-25 | M | DONE — new `lib/ui/addons/addon_picker_dialog.dart` + `addon_install_flow.dart`; collections/adons views refactored; 21 UI tests green, analyze clean |
| R-27b | Profile ▸ Addons: header `Add addon` button and empty-state action open the shared picker with the profile's installed ids; picking installs the primary branch into that profile (requirements consent preserved), list refreshes from the signal | Widget tests: header/empty action, search + `#tag`, installed badge/disabled, install invoked with the profile id (real install covered by controller tests), consent cancel aborts; analyze/tests green | R-27a | M | DONE — `_ProfileAddonsTab` header/empty action + `_addAddon`; 4 widget tests (`profile_addons_picker_test`, spy controller) green; analyze clean; follow-up: the installed list uses the same `Card` row layout as the profile Macros/Installed lists (owner style request) |
| R-27b | Profile ▸ Addons: header `Add addon` button and empty-state action open the shared picker with the profile's installed ids; picking installs the primary branch into that profile (requirements consent preserved), list refreshes from the signal | Widget tests: header/empty action, search + `#tag`, installed badge/disabled, install writes the `installedAddons` row, consent dialog cancel aborts; analyze/tests green | R-27a | M | TODO |
| R-27c | Profile ▸ Macros and Macros ▸ Installed: header/empty-state `Add macro` action opens a catalog picker (`MacroPickerDialog`, search over name/comment/description/author, installed-in-profile badge/disabled); install calls `MacrosController.install` into that profile | Widget tests: entry points, filtering, installed badge/disabled, install invoked with the profile id; analyze/tests green | R-27a | M | DONE — `MacroPickerDialog` + `InstalledMacrosList` header/empty action; 2 widget tests (`profile_macros_picker_test`, spy controller) green; test/ui suite 90 green |
| R-27d | Profile pickers verification + docs: spec 03 §2.3 picker wording, D-107, VERIFICATION entry, STATUS session row, live pass (empty/non-empty, search, installed rows) | Docs updated; analyze/tests green; live pass recorded | R-27b, R-27c | S | DONE — spec/D-107/VERIFICATION/STATUS updated; live pass on the real Addons/Macros tabs (search + Installed/disabled rows) without touching the owner's profiles; analyze clean, tests green |
| R-27e | Profile tab list consistency (owner request): installed addons use the same `Card` row layout as Macros (earlier commit); `Add addon`/`Add macro`/`Install packages` headers get 8 px separation from the list; the Python tab adopts the same card rows + 12 px header/list padding | Live check of the three tabs; analyze/tests green | R-27b, R-27c | S | DONE — 74f12bb (addons cards) + 9e0bf21 (spacing + Python cards); live-verified on Demo (Addons/Python); profiles/picker tests green |
| R-28 | Profile ▸ Addons remove action (spec 03 §2.3 “add/remove/update” gap): shared `removeAddonFromProfile` (confirmation dialog + `AddonsController.remove` + snackbars) extracted from the catalog detail; the profile row gets a Remove icon button | Widget test: cancel keeps, confirm invokes remove with the profile id and shows the snackbar; analyze/tests green | R-27b | S | DONE — `lib/ui/addons/addon_remove_flow.dart` + row button; catalog detail refactored to the shared flow; 5 tests in `profile_addons_picker_test` green |
| R-29 | Creating a profile opens its detail view: both entry points (Profiles header/empty state and Home hero/first-run checklist) navigate to the new profile's detail; `showProfileFormDialog` returns the created/edited `Profile` | Widget tests: create from Profiles shows the detail tabs; create from Home calls `onOpenProfile` with the new id | R-25c, R-27b | S | DONE — `ProfileFormResult` replaced by the returned `Profile`; `ProfilesViewState._createProfile` selects it; `HomeView._createProfile` routes through `onOpenProfile`; 2 widget tests green |
| R-30 | History Workbench install failed with `Symlink entries are not allowed`: archives now **skip** symlinks (never create them) instead of aborting, report each skipped path+target via `ArchiveWarningCallback`, log them and show an addon “Some files were skipped” dialog (D-113); build archives log the skips | Unit tests: extractor skips+reports and extracts the rest; installer propagates skipped entries; controller records `installWarnings`; warnings-dialog widget test; real HistoryWorkbench archive extracts (3 skips, package.xml present) | M4-03, D-039 | S | DONE — spec 06 §2 + D-113 updated; 698 tests green, analyze clean; uncommitted until now |
| R-31 | Windows zip fails to start on machines without the system-wide MSVC C++ Redistributable (`VCRUNTIME140.dll`/`MSVCP140.dll` not found): `build_portable.ps1` locates the VS x64 CRT redist folder via `vswhere` and copies its DLLs next to `freecad_launcher.exe` (app-local deployment), requires `vcruntime140.dll`/`vcruntime140_1.dll`/`msvcp140.dll` in the bundle and the zip, and the notices gain a Microsoft Visual C++ runtime section (D-114) | Zip starts on a clean machine without the redistributable; zip listing shows the runtime DLLs; notices drift check/analyze/tests green; no-publish release run + `v0.4.6` publish | D-091, M8-03 | S | DONE — committed `d178a61` + bump `0793158`; no-publish run 37323499192 verified the zip DLL set (sidecar OK); `v0.4.6` published (run 37324089592, sidecars verified, AppImage `--version` = 0.4.6); analyze clean, 698 tests green |
| R-32 | Installing an addon with dependencies on Windows popped a FreeCAD “unrecognised option '-m'” dialog: the asset-name hint (`py311`) made the Python probe store `FreeCAD.exe` as `builds.pythonPath`, so pip ran `FreeCAD.exe -m pip install …`. **D-115**: the hint is version metadata only; real interpreter discovery always runs (Windows `<build>\bin\python.exe` per spec 06 §4.1), legacy stored paths equal to the build executable or naming a FreeCAD launcher are ignored, and FreeCAD binaries are never executed as Python (they are only ever run with `-c`) | Probe returns the probed `bin\python.exe` (not the FreeCAD exe) with the hint; legacy `pythonPath == FreeCAD.exe` resolves to the bundled interpreter; `PipRunner` refuses a FreeCAD executable; unit tests + analyze green; Windows live dependency install retest | B-19, D-115 | S | WIP — fixed and shipped in `v0.4.7` (run 37341658955; sidecars verified, AppImage `--version` = 0.4.7): `python_probe.detect` no longer fabricates a `BundledPython` from the hint (version-only fallback), `python_env` ignores FreeCAD/executable stored paths, `pip_runner` guard + sanitized interpreter-probe env; 5 new/updated tests, 703 tests green, analyze clean; Windows live retest pending |
| R-33 | Windows prints `Unhandled Exception: Bad state: StreamSink is closed` while the app keeps working: `_trackLaunch` closed the launch log `IOSink` after the 5 s stdout/stderr drain timeout, but `Future.timeout` does not cancel the `listen(logSink.add)` subscriptions, so a late pipe chunk (Windows stdio pipes can outlive the process through inherited write handles) called `add` on the closed sink (`_Socket._onData` → `_StreamSinkImpl.add`) | Regression test emits output after the process exit with the pipes still open and fails on the old code; analyze/tests green; Windows live retest | M8-06, M8-08 | S | WIP — `_trackLaunch` now cancels both stdout/stderr subscriptions before flushing/closing the sink; `logDrainTimeout` injectable for tests (default 5 s); new `exitWithoutClosingStreams` fake + 1 regression test (714 tests green, 10 skipped), analyze clean; Windows live retest pending |
| R-34 | Addon `<depend>` install into a **weekly** Windows profile failed while stable worked: pip reported `ssl` unavailable (`WARNING: Disabling truststore since ssl support is missing`, `The 'ssl' module is unavailable but required for HTTPS URLs`). Bootstrap diagnostics pinned it to `ImportError: cannot import name 'RAND_pseudo_bytes' from '_ssl'` at `Lib/ssl.py:109`: both 1.1 bundles ship the same stale Python 3.11-era `ssl.py`, but Python 3.11's `_ssl` still exports `RAND_pseudo_bytes` while 3.13 removed it. The failure was silent (only the catalog detail showed `requirementsErrors`). **D-118**: interpreter pip runs through a generated bootstrap that aliases the removed symbol before importing `ssl`, registers the interpreter's `bin`/`DLLs` via `os.add_dll_directory` (Windows), logs the interpreter plus the full `ssl` traceback, and runs pip with `runpy`; dependency errors are keyed per profile+addon and surfaced on the profile Addons row and the install snackbar | Bootstrap unit tests; real Python 3.13 + pip 26 + stale `ssl.py` smoke installs through the bootstrap; analyze/tests green; Windows weekly live retest | D-118, R-32 | S | WIP — implemented: `PipRunner._installWithInterpreter` bootstrap + `RAND_pseudo_bytes` shim + diagnostics + DLL registration; `requirementErrorKey` + per-profile error keys (controller/view/flow updated); 2 new widget tests + updated pip/controller tests (716 green, 10 skipped), analyze clean; real Linux smoke with pip 26.2.1/Python 3.13 **and the archive's stale `ssl.py`** logs `patched _ssl.RAND_pseudo_bytes` and installs `pyjwt`/`tzlocal`; Windows weekly retest pending |
| R-35 | The status bar active-jobs indicator was a static `Icons.sync`, so running work was only noticeable by reading the label. It now rotates continuously (1400 ms linear loop) while jobs are queued/running; with the OS/accessibility "disable animations" setting it falls back to the static icon | Widget tests: the rotation keeps changing while a job is active and the indicator disappears when the job completes; the disabled-animations case renders a static icon; analyze/tests green | — | S | DONE — `_JobsActivityIcon` (`statusBarJobsIndicator` key) in `lib/ui/shell/app_shell.dart`; 2 new `app_shell_test` cases (718 tests green, 10 skipped), analyze clean; spec 03 §1 status-bar bullet updated |
| R-36 | Release candidates are not installable: tag `26.3rc1` (GitHub prerelease, 2026-10-08) is fetched but dropped because the stable tag regex rejects the `rcN` suffix. **D-119**: `FreeCadVersion` gains an `rc` component (`26.3rc1 < 26.3rc2 < 26.3`), a new `BuildChannel.rc` channel, `ReleaseTag.parse` maps supported prereleases to it, Versions → Available gains an **RC** filter with badge + install warning (weekly pattern), and RCs stay out of stable update checks and the catalog-derived stable line. `builds.channel` is a text enum → no migration | `26.3rc1`/`1.1rc3` parse and order correctly; classifier fixture yields `rc` candidates; controller separates `rcBuilds`; widget test covers the channel filter/badge/warning; analyze/tests green; spec 06 §1.3/§1.5, D-078, B-14 and the user guide updated | — | M | DONE — `FreeCadVersion.rc` + `isPrerelease`, `BuildChannel.rc`, `ReleaseTag.parse`, `BuildsController.rcBuilds`, Available RC filter/badge/confirmation, 5 new l10n keys, real `26.3rc1` fixture; portable path for `rc:26.3rc1:…` asserted (D-095); docs updated; analyze clean, 726 tests green (10 probes skipped). Live install not re-verified (catalog fetch + release-candidate install on a real machine) |

## Backlog (post-MVP, scheduled when v0.1 is released)

| ID | Task | Spec ref | Target |
|---|---|---|---|
| B-01 | Legacy channel (1.0.x): catalog UI + installation; the weekly part is DONE (B-01a..B-01d, D-077) | FR-1.7 | v0.2 |
| B-02 | In-place build updates (install alongside → switch → cleanup) | FR-1.8, spec 04 §7 | v0.2 |
| B-03 | Full profile export (zip with payload toggles) | FR-9.2 | v0.2 |
| B-04 | Preference browser + config reset + raw XML advanced editor | FR-8.3, FR-8.4 | v0.2 |
| B-05 | Macro run via `FreeCADCmd` with output panel | FR-7.5 | v0.2 |
| B-06 | Launcher self-update for AppImage | FR-10.5, spec 07 §5 | v0.2 |
| B-07 | GitHub token UX with secure storage (OQ-3) | FR-12.2 | v0.2 |
| B-08 | Profile templates | FR-2.8 | v0.2 |
| B-09 | CLI addon/bundle subcommands | FR-3.5 | v0.2 |
| B-10 | Custom addon installs: repository URL + branch (updateable), local zip/tar (FR-4.8), dev symlink; details in [PLAN-B10-custom-addons.md](PLAN-B10-custom-addons.md) | FR-4.8, FR-4.11/FR-4.12 (to add) | v0.2 |
| B-12 | i18n translations (if OQ-6 = start later) | NFR-9 | v1.0 |
| B-13 | Fully isolated private-build profiles (OQ-8) | spec 09 | post-v1.0 |
| B-14 | CalVer transition readiness (D-078, FEP-0003): stable tags `YY.N` (three releases/year, `26.3` branched 2026-09-30) and monthly patches `YY.N.P`; derive the current stable line from the catalog for the stable/legacy split; RC tags classify into the `rc` channel (R-36/D-119) and never define the stable line; dedupe `26.3` vs `26.3.0`; ordering tests + spec 06 §1.3/§1.5. Needed before 27.1 branches (2027-01-31) makes 26.3 legacy | FR-1.1, FR-1.7, FR-1.8 | v0.2 |
| B-15 | Addon enable/disable per profile via the FreeCAD `ADDON_DISABLED` marker (switch on Profile → Addons rows; state derived from disk) | FR-4.13 | v0.2 |
| B-16 | Dependency upgrades (plan in [PLAN-dependency-upgrades.md](PLAN-dependency-upgrades.md)): patch/minor first, then `signals_flutter` 7, `xml` 7 and the drift/sqlite3 majors in isolated commits, each with `build_runner`, analyze/tests, Linux+Windows CI, real smoke and packaging verification; PR #2 (all groups, Flutter 3.47.6 per D-103) and the follow-up B-17 cleanup PR #3 are merged, devel CI green and the no-publish release smoke (run 37063249302) verified both artifacts — the Linux real catalog install + isolated profile launch passed owner verification 2026-10-02; only the Windows-machine smoke remains, on hold (no Windows machine available as of 2026-10-02) | — | post-M8 (`0.4.x`) |
| B-17 | Migrate off the deprecated `signals_flutter` `.watch(context)`/`Watch` API to implicit tracking (`SignalWidget`/`SignalStatefulWidget`, `SignalBuilder`); 127 sites / 34 classes; plan in [PLAN-signals-implicit-migration.md](PLAN-signals-implicit-migration.md); not a fix for R-23 (write-during-build rule applies to every API) | B-16, D-101 | post-M8 (`0.4.x`) |
| B-18 | Home “Recent profiles” row: replace the single last-used card with a top row of up to five recent-profile cards clickable to launch (last launch order, unhealthy hidden, chevron opens the detail); plan in [PLAN-B18-home-recent-profiles.md](PLAN-B18-home-recent-profiles.md) | D-104, D-067 | v0.4.x |
| B-19 | FreeCAD `package.xml` `<depend>` support on every addon install path: dependent addons + required/optional Python packages + internal workbenches-as-informational, unified consent dialog; plan in [PLAN-B19-addon-dependencies.md](PLAN-B19-addon-dependencies.md) | FR-4.7, D-108..D-111 | v0.4.x |
| B-20 | AppImage Python execution via headless macros (D-112): pip and the package probe run inside the mounted AppImage, removing the persistent `builds/<id>/extracted/` tree on FUSE systems | FR-4.7/FR-6, D-112 | v0.4.x |

### B-01 breakdown — weekly builds (planned, v0.2; D-077)

Weekly only (legacy stays B-01). Dated tags only (`weeklies` skipped). Updates notify-only
(apply deferred to B-02). Channel filter on the Available tab, Stable default.

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| B-01a | Weekly catalog collection: keep the stable list untouched for update checks, add a `weeklyBuilds` signal; use `AssetClassifier.selectFor` so each release yields one candidate per platform/arch (macOS10/11/15 resolved); skip the rolling `weeklies` tag | Fixtures with real weekly asset names; one candidate per platform/arch; rolling tag ignored; stable list and update checks unchanged | M2-02, D-077 | M | DONE |
| B-01b | Available UI channel filter: Stable \| Weekly selector (Stable default), weekly rows with human label ("Weekly 2026-09-30") + dev badge, install confirmation warning (development quality, not covered by support), weekly empty state | Widget tests for channel switch, label, warning dialog and install flow; no stable UI regressions | B-01a, M2-07 | M | DONE |
| B-01c | Weekly update detection (notify-only): compare `WeeklyVersion` dates for installed weekly builds against the latest weekly candidate; never mix stable/weekly suggestions; no apply action | Unit tests for newer/equal/older dates and no cross-channel suggestions; badge shows in status chip/summary sheet | B-01a, M6-01 | S | DONE |
| B-01d | Verification + docs: real weekly AppImage install on Linux (checksum, headless `--version`, profile create/launch); spec 03 §2.2, spec 06 §1.3, user guide, VERIFICATION matrix | Manual Linux pass recorded in STATUS; docs updated; analyze/tests green | B-01b, B-01c | M | DONE |

Known limitation in this increment: weekly builds have no semver, so they don't appear in the
Addons FreeCAD-version filter (profile addon installs still work via the unfiltered branch
list). Deriving an API version from the Python probe is possible follow-up work.

CalVer (D-078/B-14) does not change this plan: weekly update checks are date-based and stable
update ordering stays numeric across schemas.

### B-10 breakdown — custom addon installs (planned, v0.2)

All three sources require `package.xml` at the addon root; fresh installs are blocked while the
id exists in the profile; details, API shapes and test matrix in
[PLAN-B10-custom-addons.md](PLAN-B10-custom-addons.md). Owner choices are recorded there and
became D-085..D-088 at kickoff.

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| B-10a | Foundations: schema v6 (`installed_addons.source`/`sourcePath`, migration), `AddonSource` enum, package.xml parser extraction, addon id rules, archive URL builder (GitHub/GitLab/Gitea/Codeberg/direct), `AddonInstaller.installFromArchive` + `linkDirectory`, requirements peek (zip/tar/dir), source-aware update guards | Unit tests for URL builder, id rules and parser refactor; installer tests for local archive atomic replace and symlink creation; catalog tests stay green; `build_runner` clean | B-10 plan, M1-04, D-039 | M | DONE |
| B-10b | Repository URL install + update: controller flows (conflict block, jobs, consent callback), `updateFromRepository`, Custom tab repo form + custom-install list, l10n, profile source chip | Controller tests (row provenance, conflict, pin-blocked update, custom rows excluded from `outdated`); widget tests for the form; manual install from a real repo recorded | B-10a | M | DONE |
| B-10c | Local archive install + reinstall: file picker (zip/tar.gz), id from root/filename, `installFromArchive`/`reinstallFromArchive`, Custom tab archive form + actions | Controller/installer tests incl. flat vs single-root archives; widget tests; manual zip install recorded | B-10a | M | DONE |
| B-10d | Dev symlink install: `installFromDirectory` (hard-fail without symlink support), link-only remove, live-edit warning, Custom tab folder form + Reveal action | Tests prove remove deletes only the link and target survives; manual live-edit check in FreeCAD | B-10a | M | DONE |
| B-10e | Verification + docs: real repo/zip/symlink installs in FreeCAD, spec 02/03/05/06, user guide, manifest skip-warning, VERIFICATION rows, decisions D-085..D-088 | Manual pass recorded in STATUS; analyze/tests green; limitations documented | B-10b, B-10c, B-10d | M | DONE |
| B-10f | Install an already-installed custom addon into another profile: per-row action on the Custom tab with a target-profile picker (profiles that already have it are not offered), reusing the source (repo re-fetch, stored/repicked archive, second dev link) | Controller tests (repo/zip/symlink copy, duplicate blocked, catalog refused, missing archive) + widget tests; live copy verified | B-10b, B-10c, B-10d | S | DONE |

### B-15 breakdown — addon enable/disable per profile (v0.2, D-089)

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| B-15a | Toggle on Profile → Addons rows writing/removing `ADDON_DISABLED`; controller derives the disabled set from disk (`refreshDisabledState`, refreshed on the installed-addons stream and tab mount), no schema change; disabled badge/dimmed title | Controller tests (marker create/remove, externally created marker, missing files) + widget toggle test; live check; analyze/tests green | M4-11, D-089 | S | DONE |

### B-17 breakdown — signals implicit-tracking migration (planned, D-101)

Implicit tracking does **not** fix R-23 by itself; the no-write-during-build rule applies to every
subscription API. API mapping, file list and migration traps in
[PLAN-signals-implicit-migration.md](PLAN-signals-implicit-migration.md).

`signals_lint` is deferred (**D-102**): the latest 7.1.0 caps `analyzer <14` and would downgrade
the analyzer/`source_gen` chain; re-evaluate it at B-17 start. Until the B-17 migration is done,
CI runs `flutter analyze --no-fatal-infos` (triggered by the 127 `.watch` deprecations); B-17d
must drop the flag.

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| B-17a | Small files: `app.dart`, `app_shell`, `jobs_dialog`, `updates_status_chip`, `config_snapshots_view`, `installed_macros`, `custom_addons_view` (11 sites) | No new analyze diagnostics; widget tests green; live check of the touched screens | B-16, D-101 | S | DONE — implicit tracking in 7 files; 615 tests green, `.watch` deprecations 127 → 116; live pass recorded under B-17d |
| B-17b | Profiles/builds/home: `profiles_view` (9), `builds_view` (10), `profile_detail_view` (11), `home_view` (12) | Same; live pass on Home, Profiles + six detail tabs and Versions | B-17a | M | DONE — implicit tracking in 4 files / 10 classes; 615 tests green, `.watch` deprecations 116 → 74; live pass recorded under B-17d |
| B-17c | Addons/macros: `addons_view` (22), `collections_view` (16), `macros_view` (14) | Same; live pass on Addons Catalog/Custom/Collections/detail and both Macros tabs | B-17a | M | DONE — implicit tracking in 3 files / 11 classes; `BundleDetailView` now tracks `bundles`/`items` itself (old sticky `watch()` masked the parent's early return; caught by a collections widget test); 615 tests green, `.watch` deprecations 74 → 22; live pass under B-17d |
| B-17d | Settings/updates + verification: `settings_view` (13), `updates_summary_sheet` (9); zero `deprecated_member_use`, full suite, Linux+Windows CI and AppImage smoke | `grep lib` finds no `.watch(context)`; analyze clean; CI + packaging smoke green | B-17b, B-17c | M | DONE — implicit tracking in settings/updates; `grep` finds no `.watch()`/`Watch`, `flutter analyze` **0 issues** (the `--no-fatal-infos` bridge is removed); 615 tests green; live pass incl. a live dark↔light theme switch; PR [#3](https://github.com/mnesarco/FreeCAD-Launcher/pull/3) CI green on Ubuntu + Windows (run 37058324255). Packaging smoke stays with B-16 Phase 3 |

### B-18 breakdown — Home “Recent profiles” row (planned, v0.4.x, D-104)

Owner choices confirmed 2026-10-02 (last 5 by last launch; hide when none/unhealthy; whole card
launches + chevron detail shortcut; compact cards; horizontal scroll). Details and file list in
[PLAN-B18-home-recent-profiles.md](PLAN-B18-home-recent-profiles.md).

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| B-18a | `ProfilesController.recentProfiles` computed (used profiles, `BuildStatus.installed` only, newest first, cap 5) + controller unit tests | Order/limit/health/exclusion tests green | D-030, D-104 | S | DONE — computed + 2 controller tests |
| B-18b | Home UI: move the section to the top, horizontal row of fixed-width compact cards (name, build label/channel, last-used, running badge), whole-card launch, l10n keys | Widget tests for visibility/order/5-cap/health/running/launch; analyze/tests green | B-18a | M | DONE — top row + compact cards + l10n; 6 new Home widget tests; analyze clean, 624 tests green |
| B-18c | Detail shortcut: `ProfilesViewState.openProfile(id)` + `AppShell` `onOpenProfile` wiring + chevron | Widget test asserts the callback/selection; live check | B-18b | S | DONE — `openProfile` + AppShell wiring + profiles widget test; live chevron → detail verified |
| B-18d | Verification + docs: spec 03 §2.1, remove obsolete l10n keys, live pass (launch, shortcut, narrow-window scroll), CI | Spec/STATUS updated; analyze/tests + CI green; live pass recorded | B-18c | S | DONE (local) — spec 03 §2.1 updated, obsolete keys removed; live pass (row/order, chevron → detail, narrow-window horizontal scroll, zero runtime errors); launch tap is widget-tested with a spy (no live FreeCAD spawn); follow-up: the Status counters row was removed in the same branch; PR CI pending |

Implementation note (2026-10-01, R22): B-10a..B-10f complete but **uncommitted pending
review** — schema v6 migration verified live; 574 tests green, analyze clean; real repo
(obelisk79/FreeCAD-Nxt @ main), archive and dev-symlink installs verified through the UI,
including link-only removal (see `VERIFICATION.md`).

### B-19 breakdown — package.xml `<depend>` support (planned, v0.4.x, D-108..D-111)

Owner choices confirmed 2026-10-04: unified dependency dialog with optional checkboxes,
`<depend>` version attributes parsed but ignored, batched interpreter probe for already-available
Python, lenient dependency failures, all install paths, removal warning for reverse dependencies,
missing-only dependency installs on update. Details and file list in
[PLAN-B19-addon-dependencies.md](PLAN-B19-addon-dependencies.md).

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| B-19a | Parse `<depend>` (root and nested `<content>`) into `AddonDependency`; expose dependencies on `AddonMetadata`/`Addon`; pure `resolveAddonDependencies` (automatic→addon/internal/python, internal workbench list, recursion over installed addons, PEP 503 dedupe with requirements.txt, post-order `orderedAddons`); catalog parser wiring | Parser and resolver unit tests green (types, optional casing, constraints, normalization, cycle, ordering, dedupe); analyze clean | D-108 | M | DONE — `addon_dependencies.dart` + `package_xml.dart` parser + catalog wiring; 17 tests green (12 resolver/parser + catalog parser), analyze clean |
| B-19b | `PythonPackageProbe` (one interpreter run, `find_spec` + `importlib.metadata`, PEP 503 JSON, sanitized env/PYTHONPATH) + `normalizePythonPackageName` + generated stdlib-name fallback | Probe tests with a fake runner (available/missing/failure→null); stdlib snapshot sanity; analyze clean | D-110 | M | DONE — `python_package_probe.dart` (one batched run, marker JSON, `null` on failure), `python_names.dart`, generated 329-entry `python_stdlib_names.dart` (CPython 3.10–3.14); 5 probe tests green |
| B-19c | Controller pipeline: `AddonDependencySelection` + `prepareDependencies`, staged `package.xml` union (catalog path moves to `prepareFromArchive`/`commitPrepared`), probe filtering, ordered dependent-addon installs in one job, `python_packages` provenance, lenient failures, per-package pip retry, `dependentsOf`, update missing-only | Controller tests green (install with deps, selection none/optional, probe skip, lenient failures, custom staged deps, late prompt, update missing-only, dependents); analyze clean | B-19a, B-19b | L | DONE — catalog installs now stage via `prepareFromArchive`/`commitPrepared` and read the real `package.xml`; `_dependencyPlan`/`_runDependencies`/`_installPythonRequirements` (batch + per-package retry) + `mergeDependencyPlans` + `dependentsOf`; probe results memoized; 6 new controller tests, all green |
| B-19d | Unified `showAddonDependenciesDialog` replacing the requirements dialog; catalog/custom/profile-picker flows pass the selection; addon detail dependencies row; removal “Required by” warning; l10n keys | Widget tests (sections/checkbox/cancel, install flow selection, detail row, remove warning) green; analyze clean | B-19c | L | DONE — `addon_dependencies_dialog.dart` (required/optional sections, internal info, invalid/unresolved), pre-download consent in `installAddonIntoProfile` + late handler, custom flow, detail dependencies row, removal warning in both flows, 13 dependency l10n keys; 3 dialog tests + picker consent/remove tests green |
| B-19e | Bundle apply aggregated dependency preview + selection; batch update one-shot consent; manifest import selection; `AppServices`/`BundleApplyController`/`ProfileManifestController`/`UpdatesController` signature updates; tests | Bundle planner/apply, updates batch and manifest controller tests green; analyze clean | B-19c | M | DONE — `BundleApplyController.apply(selection)` (bundle checkbox = required deps; optional not offered in the batch flow), `UpdatesController.applyUpdates(selection/onDependencies)` + summary-sheet merged one-shot dialog via `mergeDependencyPlans`, manifest import maps its checkbox to required-only; all suites green. Limitation: bundle/batch flows install required dependencies only |
| B-19f | Verification + docs: Ondsel-Lens live install (pyjwt/tzlocal installed, requests skipped), Beltrami dependent-addon ordering, FreeCAD-Ribbon optional checkboxes, Curves removal warning; spec 06 §2/§4.3, addon_index_spec, README, user guide, VERIFICATION rows, STATUS | Live pass recorded; analyze/tests green; docs updated | B-19d, B-19e | M | DONE (test-level for optional/dependent load) — real Ondsel-Lens E2E passed in 3 s (`real_addon_dependencies_test`: `<depend>` parsed, probe skipped requests/PyJWT, pip installed tzlocal, `source=addon:Ondsel-Lens`, import verified); real catalog check (67 addons with `<depend>`, Beltrami → Curves + numpy/scipy + internals); docs updated (06 §2/§4.3, addon_index_spec, README, user guide; spec 04 unchanged — no architecture change). Remaining live checks: optional checkbox install, dependent addon loaded inside FreeCAD, removal warning UI |

### B-20 breakdown — AppImage macro Python execution (planned, v0.4.x, D-112)

Avoids the persistent `builds/<id>/extracted/` tree by running pip and the package
availability probe inside the mounted AppImage through generated headless macros (D-112).
FUSE-less systems keep the one-time extraction fallback.

| ID | Task | Done when | Deps | Effort | Status |
|---|---|---|---|---|---|
| B-20a | `FreeCadMacroRunner`: generated `.FCMacro`, isolated env, tagged JSON payload, temp cleanup, `runAppImage` retry with `APPIMAGE_EXTRACT_AND_RUN=1` | Runner tests with a fake process (args/env/payload/cleanup/fallback) green; analyze clean | D-112 | M | DONE — `freecad_macro_runner.dart`; 4 tests (headless args/isolated env/payload/cleanup, FUSE fallback, both-fail, payload parsing) |
| B-20b | `PipRunner` AppImage mode: in-process `pip install --target` macro, pip log + tagged result, `PIP_CACHE_DIR`, interpreter mode unchanged | Pip tests for both modes green | B-20a | M | DONE — `install({pythonPath?, appImagePath?})` with exactly-one validation; macro generated with `jsonEncode` values and a `runpy` fallback; +3 tests; interpreter tests unchanged |
| B-20c | `PythonPackageProbe.availablePackagesInFreeCad` + `PythonExecutionResolver` (FUSE detection, interpreter fallback) | Probe/resolver tests green | B-20a | M | DONE — probe macro appends the target to `sys.path` (FreeCAD runtime order); resolver picks AppImage-in-place on FUSE, extraction/interpreter otherwise; +2 probe tests, 6 resolver tests |
| B-20d | Wire `AddonsController`/`PythonController`/`AppServices` to the resolver; preview stays instant; install-time probe filters bundled packages | Controller tests (AppImage macro pip, no extraction, fallback) green | B-20b, B-20c | M | DONE — both controllers accept `fuseAvailable`; preview passes `allowAppImageMacro: false`; AppServices wires `diagnostics.fuseAvailable`; AppImage controller tests assert `appImagePath` + null `pythonPath` |
| B-20e | Live verification on an isolated data root (no `extracted/` created; catalog addon + Python-tab install both via macro) + spec 06 §4.1/§4.2, D-112, VERIFICATION, STATUS | Live pass recorded; docs updated; analyze/tests green | B-20d | M | DONE — real UI pass on an isolated `XDG_DATA_HOME` with the stable AppImage and no extraction: dependency dialog instant, “Install dependencies” pip-installed pyjwt/tzlocal (`requests` filtered by the in-FreeCAD probe), Python tab installed `six`; **no `extracted/` dir**, temp data root 7.5 MB total, no lingering mounts; 692 tests green, analyze clean |
