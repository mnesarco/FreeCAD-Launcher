# DECISIONS

Append-only log. Never edit an accepted entry; supersede it with a new one and update the old
entry's status line only. Every entry must be traceable from a task or spec section.

Template:

```md
### D-### — <title>
- **Date**: YYYY-MM-DD
- **Status**: Accepted | Superseded by D-###
- **Context**: why this came up
- **Decision**: what was chosen
- **Consequences**: trade-offs, follow-ups
- **Refs**: spec/task/code links
```

---

### D-001 — Greenfield v2 rewrite, same stack
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: The current app is a prototype; scope changed to a cross-platform environment manager.
- **Decision**: Rebuild from scratch with Flutter + `signals_flutter` + `drift`. Keep the repo; tag the prototype `prototype-final` and develop v2 on a branch (executed in `M1-01`). No code or schema migration from the prototype.
- **Consequences**: `lib/` is replaced; old code stays in git history only; all v2 work follows `docs/spec` layering (ui/state/domain/data/platform/core).
- **Refs**: `../spec/04-architecture.md`, `TASKS.md` M1-01

### D-002 — Product scope is build/profile/addon management, not package managers
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Prototype supported Flatpak/Snap; the desired product installs portable official builds into user space.
- **Decision**: Manage GitHub-hosted FreeCAD builds (AppImage, portable archive, dmg) and user-supplied files. No Flatpak, Snap, distro packages, or source builds.
- **Consequences**: `snapd` dependency dropped; Flatpak/Snap UI/services deleted; reintroduction requires a new decision.
- **Refs**: `../spec/01-vision.md` NG1–NG3, `TASKS.md` M1-02

### D-003 — Platform and MVP format matrix
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Cross-platform goal with limited early capacity.
- **Decision**: Runtime support: Linux (x86_64/aarch64), Windows 10/11 (x86_64), macOS 11+ (x86_64/arm64). v0.1 managed formats: Linux AppImage, Windows portable `.7z`, macOS `.dmg`. The launcher itself ships only as a Linux AppImage in v0.1 (OQ-1 covers Windows/macOS artifacts, targeted v0.2).
- **Consequences**: All three OS builds must stay green in CI even before native launcher artifacts exist.
- **Refs**: `../spec/README.md`, `../spec/07-distribution.md`, OQ-1

### D-004 — Shared builds, isolated profiles
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Private build copies per profile cost 1–2 GB each; env-var isolation is sufficient and verified.
- **Decision**: A build is installed once per `(channel, version, platform, arch)`. Any number of profiles reuse it. Each profile gets its own user data directory; isolation is enforced at process launch via environment variables.
- **Consequences**: Profiles are not fully independent binaries; profile export is the portability mechanism. Hybrid private copies deferred (OQ-8).
- **Refs**: `../spec/04-architecture.md` §4, `../spec/05-data-model.md`

### D-005 — Profile isolation mechanism (verified)
- **Date**: 2026-09-18
- **Status**: Superseded by D-075 (HOME override clause only; rest stands)
- **Context**: FreeCAD only honors custom dirs if they exist; `--user-cfg` does not isolate data; 1.1 adds versioned default dirs but custom dirs bypass them.
- **Decision**: Set at launch: `FREECAD_USER_HOME=<profile>` plus `FREECAD_USER_TEMP`; `HOME` (Linux/macOS) or `APPDATA`/`LOCALAPPDATA` (Windows); `XDG_*` dirs (Linux); `TMPDIR`/`TEMP`; and remove inherited `PYTHONPATH`, `PYTHONHOME`, `VIRTUAL_ENV`, `PYTHONUSERBASE`. Create all dirs before spawning. Never pass `--single-instance` (global, not profile-scoped).
- **Consequences**: FreeCAD's macro dir collapses to the profile root under a custom home — macro scanner must check `<profile>/*.FCMacro` and `<profile>/Macro/`. Windows Qt registry state may stay shared (documented limitation).
- **Refs**: `../spec/04-architecture.md` §4.1, `../spec/06-integrations.md` §4

### D-006 — Python packages via bundled interpreter + `--target`
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: FreeCAD 1.0+ ignores `PYTHONPATH` (isolated `PyConfig`); system Python must never be touched. FreeCAD appends `<UserAppData>/AdditionalPythonPackages[/pyXY]` to `sys.path`.
- **Decision**: Install with `<bundled python> -m pip install --upgrade --target <profile>/AdditionalPythonPackages/py<XY>` (flat dir for ≤0.20), version detected from the interpreter, invoked with argument arrays (never a shell). Never use `Scripts\pip.exe` on Windows.
- **Consequences**: `AdditionalPythonPackages` is last on `sys.path` (bundled modules win); pip jobs are serialized per profile and globally; uninstall procedure requires spike S3.
- **Refs**: `../spec/06-integrations.md` §4, `TASKS.md` S3, M4-06

### D-007 — Build catalog source, channels, and rate-limit strategy
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Assets and channels have moved over time; unauthenticated GitHub API allows 60 req/h.
- **Decision**: Use `FreeCAD/FreeCAD` GitHub releases as the catalog (stable semver, `weekly-YYYY.MM.DD` + rolling `weeklies`, legacy 0.19–1.0 assets), plus archived `FreeCAD/FreeCAD-Bundle` for missing legacy full bundles. Conditional GET with ETag, 6-hour TTL, respect `X-RateLimit-Remaining`, stale-cache offline mode. Optional PAT deferred (OQ-3). SHA-256 sidecar verification whenever available.
- **Consequences**: Asset classification must be regex-based across naming eras; known gaps (e.g. 0.19.4 Linux/macOS) are hidden, not linked to 404s.
- **Refs**: `../spec/06-integrations.md` §1

### D-008 — Updates are notify-only
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Auto-updating FreeCAD builds or addons can break working environments.
- **Decision**: Update checks only produce suggestions; every download/install/update requires explicit confirmation. Weekly builds are never auto-suggested. App self-update (v0.2) stages a verified file and swaps on next start.
- **Consequences**: UI needs badges and batch-confirm flows (M6-01..03); no silent network mutation.
- **Refs**: `../spec/02-requirements.md` FR-10, `../spec/07-distribution.md` §5

### D-009 — Fresh drift schema v1, DB is an index
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Prototype schema no longer fits; disk is the source of truth for installs.
- **Decision**: `schemaVersion = 1` with tables in `../spec/05-data-model.md`; no migration from the prototype. A startup reconciler marks missing/broken builds/profiles instead of trusting the DB. Timestamps stored as ISO-8601 text (`build.yaml` + `driftRuntimeOptions` must agree).
- **Consequences**: Prototype users must manually copy data; reconciler tests are required (M2-10).
- **Refs**: `../spec/05-data-model.md`

### D-010 — UI shell: sidebar navigation
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Top tabs do not scale to six sections plus job status.
- **Decision**: `NavigationRail` with Home, Profiles, Versions, Addons, Macros, Settings; bottom status bar for jobs/updates/warnings; Material 3 dark default.
- **Consequences**: UX screens in `../spec/03-ux.md` are authoritative; prototypes' tabs/widgets are discarded.
- **Refs**: `../spec/03-ux.md`

### D-011 — Branding and license
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Public OSS release in the FreeCAD ecosystem.
- **Decision**: Keep the name "FreeCAD Launcher"; license GPL-3.0-or-later; SPDX headers in sources; third-party notices generated. Application id/reverse-DNS still open (OQ-2).
- **Consequences**: `LICENSE` + `THIRD_PARTY_NOTICES.md` are release blockers (M7-03).
- **Refs**: OQ-2, `../spec/07-distribution.md` §7

### D-012 — Launchers produce CLI + in-app launch only
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Desktop entry generation is platform-specific and high-maintenance; users asked for scriptable launching.
- **Decision**: v0.1 provides in-app launch and CLI (`list`, `run`) plus generated `.sh`/`.cmd` wrappers. No `.desktop`/shortcut/macOS bundle generation.
- **Consequences**: Desktop integration is deferred (revisit post-v1.0); wrapper PATH availability must be reported clearly.
- **Refs**: `../spec/02-requirements.md` FR-3, `../spec/03-ux.md`

### D-013 — Macros are manager-only in v0.1
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: FreeCAD has no verified CLI for running GUI macros in a profile.
- **Decision**: v0.1 lists/installs/deletes/reveals/opens macros externally. Running macros via `FreeCADCmd` is deferred to v0.2 (B-05) after a spike.
- **Consequences**: Macro catalog source must still be verified (S4); no editor.
- **Refs**: `../spec/02-requirements.md` FR-7, `TASKS.md` B-05

### D-014 — `.7z` extraction is blocked on spike S1
- **Date**: 2026-09-18
- **Status**: Accepted (provisional)
- **Context**: Dart's `archive` package does not support `.7z`, and the Windows portable build ships as `.7z`.
- **Decision**: Do not start `M2-05` Windows extraction before `S1` selects and verifies an extractor (pure-Dart package, FFI libarchive, or bundled helper) with a compatible license. Never shell out with interpolated strings; no partial installs on failure.
- **Consequences**: S1 is the highest-risk spike; Windows MVP depends on its outcome.
- **Refs**: `../spec/08-roadmap.md` S1, `TASKS.md` S1, M2-05

### D-015 — Repository workflow for the rewrite
- **Date**: 2026-09-18
- **Status**: Superseded by D-081 (branch strategy; issue/PR workflow unchanged)
- **Context**: Multi-session rewrite needs a clean baseline and reversible prototype.
- **Decision**: Tag `prototype-final` before v2 work; develop v2 on branch `v2`; merge to `main` after M2 exit review; `main` always releasable after that. Prototype data is not migrated.
- **Consequences**: v2 PRs target `v2` until merge; CI runs on both.
- **Refs**: `TASKS.md` M1-01, `../spec/07-distribution.md` §4.3

### D-016 — Application identity: `org.freecad.ext.launcher`
- **Date**: 2026-09-18
- **Status**: Accepted (the Windows data root was made explicit in D-116)
- **Context**: OQ-2 asked for the reverse-DNS identity; the prototype used `org.freecad.freecad_launcher` in `linux/CMakeLists.txt`.
- **Decision**: Use `org.freecad.ext.launcher` everywhere an application id is needed: Linux `APPLICATION_ID` and `.desktop` file, macOS `PRODUCT_BUNDLE_IDENTIFIER`, Windows AppUserModelID. The Dart package name stays `freecad_launcher`. The app-support data dir derives from it (via `path_provider`).
- **Consequences**: Data lives under `<appSupport>/org.freecad.ext.launcher` on Linux; all platform runners must be updated in `M1-02`. The `.ext.` segment deliberately marks this as an extension of the ecosystem, not an official FreeCAD binary.
- **Refs**: OQ-2, `../spec/07-distribution.md` §3, `TASKS.md` M1-02

### D-017 — i18n scaffolding from day one
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: OQ-6 asked whether to scaffold localization now or refactor later; the audience is public OSS.
- **Decision**: Add `flutter_localizations` + ARB (`lib/l10n/app_en.arb`, template English) in `M1-02`. All user-facing strings go through `AppLocalizations` from the first screen. Translations are not in scope for v0.1.
- **Consequences**: No hardcoded user strings in UI code; CI freshness check covers generated localization files; adding a language later is data-only.
- **Refs**: OQ-6, `../spec/02-requirements.md` NFR-9, `TASKS.md` M1-02

### D-018 — Windows `.7z` extraction via bundled 7-Zip standalone (`7zr.exe`)
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Spike S1. The real asset `FreeCAD_1.1.3-Windows-x86_64-py311.7z` (418,053,398 bytes) was inspected with 7-Zip 23.01: `Method = LZMA2:28 LZMA:20 BCJ2`, `Solid = +`, `Blocks = 2`. The pure-Dart `koni_sevenz` explicitly does not support BCJ2 and caps folder allocations at 1 GiB, so it cannot extract official FreeCAD archives. `.7z` is only needed on Windows (Linux uses AppImage, macOS uses `.dmg`). Windows' built-in `tar.exe` was considered but its 7z/BCJ2 support is not documented and cannot be relied on.
- **Decision**: Bundle the official 7-Zip standalone console executable `third_party/7zip/7zr.exe` (x86, SHA-256 `ad4c82fadcbdf93c03b4fc440f300509c7d60c5c2f4d183e35d9d70d6957037d`, LGPL-2.1-or-later, no RAR code) and invoke it through `ProcessRunner` with argument arrays (`x -y -o<dest> <archive>`). The Windows runner copies it next to the app executable. No pure-Dart 7z dependency is used.
- **Consequences**: +600 KB in repo and Windows bundle; `THIRD_PARTY_NOTICES.md` must list 7-Zip (M7-03); extraction progress is parsed from stdout; the pinned hash is checked in CI. Manual Windows extraction of the real archive is part of M2-05.
- **Refs**: S1, D-014, `../spec/06-integrations.md` §4, `TASKS.md` M2-05, `third_party/7zip/README.md`

### D-019 — macOS `.dmg` install via `hdiutil`
- **Date**: 2026-09-18
- **Status**: Accepted
- **Context**: Spike S2. macOS FreeCAD builds ship as `.dmg` containing `FreeCAD.app`; official notarization has been unreliable (FreeCAD/FreeCAD#30621).
- **Decision**: Install with `hdiutil attach -nobrowse -readonly -mountpoint <staging> <dmg>` → copy `FreeCAD.app` into `builds/<id>/` → `hdiutil detach <staging>` (retry with `-force` after a timeout). After copying, offer quarantine removal (`xattr -dr com.apple.quarantine <app>`) with an explanation. Launch by spawning `FreeCAD.app/Contents/MacOS/FreeCAD` directly so the profile environment is inherited. Gatekeeper state comes from the diagnostics service; if launch fails, surface right-click→Open guidance.
- **Consequences**: No notarization assumptions. Manual macOS verification cannot be done on Linux and is folded into M2-05 acceptance.
- **Refs**: S2, `../spec/06-integrations.md` §1.4, `TASKS.md` M2-05

### D-020 — Custom builds accept user-selected executables (Linux-first) + Python detection
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: On Linux a user may want the launcher to manage an arbitrary FreeCAD binary —
  self-compiled (e.g. `~/build/bin/FreeCAD`) or installed by another method (distro package,
  wrapper script, symlink). The custom import path (M2-08) only let users pick archive
  extensions, so extensionless binaries could not be selected. Python info for such binaries is
  also unknown. This refines D-002, which rules out package-manager *integration*, not
  referencing a local binary the user already has.
- **Decision**:
  - `BuildKind.custom` references any local executable file by absolute path (`localPath`);
    the launcher never copies it and `remove` deletes only the DB row. Known extensions keep
    the managed pipeline (`.AppImage` copied, archives extracted, `.dmg` mounted).
  - Validation: path exists, is a regular file (symlinks followed), and has the executable bit
    on Linux/macOS. URLs are rejected for `custom`.
  - Python detection for custom executables, best-effort and non-fatal:
    1. Scan near the (symlink-resolved) binary for a bundled interpreter and probe it with
       `-c`.
    2. Otherwise run the binary headless with a temp probe script (sibling `FreeCADCmd`
       preferred, else `<binary> --console <script>`) that prints `FCL_PY_VERSION`,
       `FCL_PY_PREFIX`, `FCL_PY_EXEC`; resolve the interpreter from a prefix that still
       exists after exit (AppImage mounts do not).
    3. If still unknown, the UI offers a Python executable picker; the chosen interpreter is
       probed with `-c` and stored.
  - Schema revision: nullable `builds.pythonPath`; `schemaVersion` 1 → 2 with an
    `onUpgrade` `addColumn` for pre-release dev DBs. No prototype migration (D-009 stands).
- **Consequences**: `localPath` may point outside the launcher data dir; reconciler/verify only
  check existence; pip jobs (M4) use the stored `pythonPath`. Import runs the selected binary
  headlessly (behind the existing trust confirmation) with a 60 s timeout; failures degrade to
  "Python unknown", never block the import.
- **Refs**: spec 02 FR-1.3/FR-1.6, spec 03 §2.2, spec 04 §4.2, spec 05 `builds`, `TASKS.md`
  M2-12/M2-13, D-002, D-009

### D-021 — Support floor: FreeCAD 1.0+ only
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: The catalog previously spanned 0.19–1.1 assets, with a `legacy` channel covering
  everything before 1.1 and a `FreeCAD/FreeCAD-Bundle` fallback. The product targets modern
  FreeCAD; pre-1.0 releases only add classifier surface, catalog noise, and dead Python layouts.
- **Decision**:
  - The official catalog supports FreeCAD 1.0 and newer only. Tags below 1.0 (0.19–0.21) are
    ignored at tag parse time via `FreeCadVersion.isSupported`.
  - `legacy` now means the older supported stable line (1.0.x while the current line is 1.1.x);
    the channel stays for FR-1.7's "older stable versions".
  - The archived `FreeCAD/FreeCAD-Bundle` fallback is dropped; the catalog is `FreeCAD/FreeCAD`.
  - The `<= 0.20` flat `AdditionalPythonPackages` target dir is dropped: always `py<XY>`.
  - Custom builds are unaffected: users may reference any executable (D-020); the floor applies
    to the managed catalog only.
- **Consequences**: Pre-1.0 fixtures stay as regression tests asserting empty classification;
  spec 06's legacy asset patterns shrink to 1.0.x; D-006's flat-dir clause and D-007's
  0.19–1.0/FreeCAD-Bundle clauses no longer apply.
- **Refs**: spec 02 FR-1.7, spec 06 §1.1/§1.3/§1.5/§4.2, spec 05, `TASKS.md` M2-14, D-006, D-007

### D-022 — AppImage Python detection via headless macro probe
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: `M2-06` probed AppImages by scanning a `squashfs-root/` tree that never exists in
  the current install layout (AppImages are stored as single files), so detection failed for
  custom AppImages and had to rely on asset-name hints for catalog builds. The frozen prototype
  (`prototype-final`) proved a working method: write an `.FCMacro`, run FreeCAD headless
  (`-c -M <macroDir> <macro>`) and parse tagged console output; the macro exits via
  `sys.exit(0)`.
- **Decision**:
  - `ProcessPythonProbe.detect(kind: appimage)` first probes an extracted interpreter when one
    exists; otherwise it runs the binary headless with the prototype's tagged-JSON macro and
    uses the reported `python` version. The asset-name `pythonVersionHint` becomes the fallback
    when the headless run fails.
  - The headless macro reports `python`, `sys.prefix` and `sys.executable` as JSON inside
    `[freecad-launcher:out]…[/freecad-launcher:out]`; interpreter paths are only stored when the
    prefix still exists after exit (AppImage mounts are transient).
  - Detection is best-effort and never blocks an install; pip still extracts the AppImage once
    on first pip need (spec 06 §4.1).
- **Consequences**: Importing/installing an AppImage runs it once, headless (covered by the
  existing trust confirmation for custom builds); the "AppImage must be extracted before its
  Python can be probed" failure mode disappears; custom AppImages no longer trigger the manual
  interpreter dialog when the version is known.
- **Refs**: `lib/platform/python_probe.dart`, `prototype-final:lib/service/applications.dart`
  (`callMacro`/`macroVersionCheck`), spec 04 §4.2, spec 06 §4.1, `TASKS.md` M2-15, M2-06, D-020

### D-023 — Custom local AppImages are symlinked, not copied
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: Importing a locally selected `.AppImage` ran it through the managed install
  pipeline, copying the whole file (hundreds of MB to >1 GB) into `builds/<id>/`. Users who
  already keep AppImages on disk (e.g. in a toolkit directory) pay that disk cost twice, unlike
  custom executables, which are referenced in place (D-020).
- **Decision**:
  - A local (non-URL) AppImage import is created as a symlink
    `builds/<id>/<assetName> -> <user file>`; the AppImage is not copied. `remove` deletes the
    symlink only, never the target. If the filesystem cannot create symlinks, fall back to a
    copy so the import still succeeds.
  - The selected file must exist and be executable (Linux/macOS) before importing; the symlink
    target is what the launcher later runs.
  - URL-downloaded AppImages and catalog installs still get a managed copy (their source is the
    download cache, not a user-owned file).
  - `sizeBytes` reports the target AppImage length (launcher-owned disk stays ~0).
- **Consequences**: `kind` remains `appimage` (FUSE/extract-and-run launch handling applies);
  a moved/deleted target flips status to `broken` via the existing reconciler; the symlink
  keeps the `builds/<id>/` layout, staged rename, verify and launch code unchanged.
- **Refs**: spec 02 FR-1.6, spec 03 §2.2, spec 05 `builds`, `TASKS.md` M2-16, D-020, D-022

### D-024 — Hashing is opt-in via checksum; imports report explicit stages
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: Importing a local AppImage hashed the whole file (~10.3 s for 778 MB) with pure
  Dart `package:crypto` even when the user provided no checksum, and the UI only showed an
  indeterminate "installing" spinner. The AppImage symlink/probe work is ~0.5 s, so hashing
  dominated the wait with no user-visible progress (measured in session).
- **Decision**:
  - Local imports hash only when the user provided a checksum; otherwise `sha256` stays null and
    `verified` is false (the column is already nullable for custom builds, D-009/spec 05).
  - The downloader verifies only when an expected checksum exists; `DownloadResult.sha256` is
    nullable, so catalog assets without a sidecar store no hash either.
  - `sha256File` reports progress; `BuildsController` throttles it to 1% steps.
  - Progress stages are explicit: `hashing`, `downloading`, `installing`, `detectingPython`.
    Both the Available list and the Custom tab show the current stage and a progress bar.
- **Consequences**: Custom imports without a checksum import in ~1 s plus detection; "verify
  files" for those builds is existence-only (no hash to compare) until a checksum is supplied at
  import; catalog assets lacking `-SHA256.txt` are likewise unverified (already possible).
- **Refs**: `lib/platform/checksum.dart`, `lib/platform/downloader.dart`,
  `lib/state/builds_controller.dart`, `lib/ui/builds/builds_view.dart`, spec 02 FR-1.6,
  spec 03 §2.2, `TASKS.md` M2-17

### D-025 — Successful installs switch to the Installed tab
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: Catalog installs from Available and custom imports from Custom ended with only a
  snackbar; the new build was not visible until the user switched tabs manually.
- **Decision**: After a successful catalog install or custom import, the Versions view animates
  to the Installed tab. Failed installs stay on the current tab so the error stays visible. The
  Python fallback dialog (D-020) opens after the switch.
- **Consequences**: `_AvailableBuildTile` and `_CustomTab` capture the `TabController` before
  awaiting, avoiding context use across async gaps.
- **Refs**: spec 03 §2.2, `lib/ui/builds/builds_view.dart`, `TASKS.md` M2-18, M2-07, M2-08

### D-026 — Download progress shows bytes and speed
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: User-reported "download hangs". Measured on the dev machine: GitHub release
  assets stream at ~55–75 KB/s (curl and Dart agree), so the 820 MB 1.1.3 AppImage needs
  ~3–4 h. The UI only showed a bar that moves ~0.1% per 30 s and no byte/speed information,
  so a slow-but-alive download looked frozen.
- **Decision**:
  - `InstallProgress` carries `receivedBytes`, `totalBytes` and `bytesPerSecond` (average since
    the download started); the Available list and Custom tab show "x / y · z/s" while
    downloading.
  - `Downloader` coalesces progress callbacks to 1% steps (256 KiB when the total is unknown)
    and always emits a final update, bounding UI work for large files without hiding activity.
- **Consequences**: Slow downloads are visibly alive; no change to transfer behavior. Resume
  support (Range) and mirror selection remain future work if slow links persist.
- **Refs**: `lib/platform/downloader.dart`, `lib/state/builds_controller.dart`,
  `lib/ui/builds/builds_view.dart`, spec 03 §2.2, `TASKS.md` M2-19, M2-04, M2-17

### D-027 — Profile naming and binding rules (M3-01)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: FR-2 requires case-insensitive unique names; profiles need a Python version for
  addons/packages but custom builds can have no detected Python (D-020); builds can be
  `missing`/`broken` (M2-10). `profiles.pythonVersion` is NOT NULL.
- **Decision**:
  - Names are trimmed, 1–64 characters, without control characters, unique
    case-insensitively. Spaces and unicode are allowed; the profile directory is the UUID, so
    the name is display-only. The repository enforces uniqueness because the SQLite unique index
    on `name` is case-sensitive.
  - A profile can be created or rebound only to a build with `status == installed` and a
    non-empty `pythonVersion`; `profile.pythonVersion` is copied from the build (schema
    unchanged). Builds without detected Python are rejected with a message pointing at the
    interpreter picker.
  - Rebuilding reports `pythonChanged` so the UI can show the FR-2.3 reinstall warning; a
    profile keeps its binding if its build later becomes unhealthy (the launch guard lands in
    M3-04).
- **Consequences**: The repository is the single writer (`ProfilesRepository`, exposed via
  `AppServices`); duplicate-name races are not a concern because one controller owns profiles.
  M3-02 adds atomic directory creation to `create` and directory cleanup to `delete`.
- **Refs**: spec 02 FR-2.1/FR-2.3, spec 03 §2.3, spec 05 `profiles`, `TASKS.md` M3-01, D-020

### D-028 — Profile lifecycle is atomic; duplicate asks config vs payload
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: M3-02 needed atomic directory creation and a concrete meaning for FR-2.4's
  "duplicate (fresh id, copied config)". Copying the full payload can mean gigabytes, so the
  user chose to be asked at duplicate time.
- **Decision**:
  - Profile directories are staged under `profiles/<id>.part`, fully populated, then renamed to
    `profiles/<id>`; the DB row is inserted after the rename and removed (along with the
    directory) if the insert fails. Failures leave no partial directories or rows.
  - `delete` removes the directory first, then the DB row (FK cascades addons/packages/macros);
    if the DB delete fails the row remains and the reconciler marks it missing.
  - `rename` only changes the DB name (directories are id-based).
  - `duplicate(copyPayload: false)` copies `user.cfg`/`system.cfg` into a fresh layout.
    `copyPayload: true` additionally copies `Mod/`, `AdditionalPythonPackages/`, root
    `*.FCMacro`/`Macro/`, and the addon/package/macro rows (fresh ids; `targetDir` rewritten to
    the new profile). The UI asks which mode (FR-2.4). Duplicating a profile whose build is
    unhealthy is allowed; the copy keeps the binding.
- **Consequences**: A hard crash can leave a stale `profiles/<id>.part` (cleanup is future
  work); full-payload duplicates verify with the copy size; `ProfilesRepository` now requires
  `AppPaths` + host platform.
- **Refs**: spec 02 FR-2.4, spec 03 §2.3, spec 05 `profiles`, `TASKS.md` M3-02, D-027

### D-029 — Pure launch plan composes executable, argv and env
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: Spec 04 defines a profile launch as a pure function of (build, profile, args, OS)
  → (executable, argv, env). The env builder and path mapping existed from M1-05, but nothing
  composed the pieces for M3-04 to execute.
- **Decision**: `LaunchPlanBuilder.build` (pure domain) returns `(executable, argv, env)`:
  - executable is the build's recorded `localPath` (installer already resolves AppImage/archive/
    dmg/custom layouts);
  - arguments are user args first, then `-u <profile>/user.cfg -s <profile>/system.cfg`
    (always appended for clarity; "optional" in spec 04 means FreeCAD does not require them);
    `--single-instance` is never added (D-005);
  - environment comes from `LaunchEnvironment.build` (sanitized inherited vars, per-OS dirs,
    `APPIMAGE_EXTRACT_AND_RUN=1` only on Linux when requested).
- **Consequences**: M3-04 only needs to ensure the profile directories exist and spawn the plan;
  a unit test asserts every directory the plan references is part of
  `ProfilePaths.directoriesFor(platform)`.
- **Refs**: spec 04 §4.1/§4.2, `lib/domain/profiles/launch_plan.dart`, `TASKS.md` M3-03, M3-04,
  D-005

### D-030 — Launch runtime and profiles controller
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: M3-04 needed the executable half of the launch model: per-kind/runtime behavior
  (AppImage FUSE fallback, macOS quarantine) and an orchestrator that guards and records
  launches. The UI arrives in M3-06.
- **Decision**:
  - `FreeCadRuntime` (platform) builds the plan via `LaunchPlanBuilder`: for Linux AppImages it
    sets `APPIMAGE_EXTRACT_AND_RUN=1` when `DiagnosticsService.fuseAvailable()` is false;
    archive/dmg/custom just use the recorded `localPath`.
  - `ProfilesController.launch` blocks when the build is not `installed`, re-creates the profile
    directories (D-005), starts the process, and updates `lastUsedAt`. It returns
    `LaunchResult` (started / quarantineRequired / failure) instead of throwing.
  - macOS quarantine: if the `.app` bundle has `com.apple.quarantine`, launch returns
    `quarantineRequired`; only an explicit consent triggers `xattr -dr` (D-019 refined) and then
    the launch. Other platforms never check.
  - M3-05 owns the running signal and log streaming; M3-04 returns the process handle.
- **Consequences**: M3-06 only needs to render `LaunchResult` (consent dialog + error) and the
  CLI (M3-08) can reuse the controller. Headless Linux launch of the real 1.0.2 AppImage
  verified (`--version`, exit 0); Windows/macOS manual launches remain open.
- **Refs**: spec 02 FR-2.5, spec 04 §4.2/§4.3, `lib/platform/launch.dart`,
  `lib/state/profiles_controller.dart`, `TASKS.md` M3-04, D-019, D-029

### D-031 — Process tracking: running signal, per-launch logs, exit codes
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: M3-05; spec 04 §4.3 defines a running state per profile and per-launch log files.
- **Decision**:
  - `ProfilesController` refcounts launches per profile: `runningProfiles` is a signal Set,
    `launchLogs` maps profile → latest log path, `lastExitCodes` records exit codes. Re-running
    a profile is allowed (FR-3.4); running clears only when the last launch exits.
  - `ProfileLaunch` (id, profileId, logPath, startedAt, `exitCode` future) is returned by
    `launch`; the CLI (M3-08) will await `exitCode`.
  - stdout/stderr stream to `logs/launch-<sanitized-name>-<iso>.log` with a header (timestamp,
    executable, argv). After exit, streams are drained with a 5 s timeout before the log closes,
    so a lingering child pipe cannot keep the profile "running" forever.
- **Consequences**: M3-06 renders the running badge from `runningProfiles` and can reveal
  `launchLogs`; exit codes are available to CLI wrappers; closing the launcher does not kill
  FreeCAD (per spec) and tracking state dies with the app.
- **Refs**: spec 04 §4.3, spec 02 FR-2.5, `lib/state/profiles_controller.dart`,
  `TASKS.md` M3-05, D-030

### D-032 — Profiles UI: cards, dialogs and detail skeleton
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: M3-06; the Profiles section was a placeholder even though the repository,
  controller and launch runtime were ready.
- **Decision**:
  - Profiles view: live cards (name, build version/channel, Python, addon/package counts, size,
    last used, running badge, health chip) driven by `ProfilesController` signals, with
    loading/empty/error states. Create dialog offers only installed builds with a detected
    Python (D-027); duplicate dialog asks config vs full payload (D-028); delete confirms.
  - Profile detail: six tabs — functional Overview (build/health, paths, config files, last log)
    plus Addons/Python/Macros/Config/Backups placeholders until M4/M5 (M5-08 wires them).
  - Launch is triggered from card and detail with the quarantine consent dialog (D-030); running
    state comes from `runningProfiles`.
  - Profile sizes are computed asynchronously into `profileSizes` (cards show them when ready)
    rather than blocking the list.
- **Consequences**: Widget tests must pre-seed data in `setUp` because drift stream queries
  opened under `testWidgets`' fake async block later writes; documented in the test file.
- **Refs**: spec 03 §2.3, spec 02 FR-2.1..2.5, `lib/ui/profiles/**`, `lib/state/profiles_controller.dart`,
  `TASKS.md` M3-06, D-027, D-028, D-030

### D-033 — Launch command viewer shows isolation overrides and a copyable shell line
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: FR-2.6 requires revealing the exact executable + env + args; pasting that
  command must reproduce the isolated environment. The plan's environment contains the whole
  inherited env, which is noise for display.
- **Decision**:
  - `LaunchCommand.fromPlan` keeps only variables whose value differs from the inherited
    environment, lists sanitized keys that were removed (`PYTHONPATH`, …), and renders a
    platform shell line: POSIX `KEY='value' 'exe' 'arg' …` with single-quote escaping, Windows
    `set "KEY=value" && "exe" "arg"`.
  - `ProfilesController.planFor` returns the launch plan without spawning; the detail header
    exposes "Show launch command" with a copy button (clipboard) plus the override/removed
    lists for transparency.
- **Consequences**: Copy output is shell-pasteable on POSIX and cmd on Windows; widget
  `planFor` needed `ensureProfileDirectories` to skip existing dirs so fake-async tests do not
  hit real I/O. Linux manual test executes the generated command via `/bin/sh -c` (exit 0).
- **Refs**: spec 02 FR-2.6, spec 03 §2.3, `lib/domain/profiles/launch_command.dart`,
  `lib/ui/profiles/launch_command_dialog.dart`, `TASKS.md` M3-07, D-029, D-030

### D-034 — CLI mode and exit codes
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: FR-3.1..FR-3.4 require a scriptable CLI; `main.dart` previously always started
  the GUI. M3-09's wrapper scripts will call the same binary.
- **Decision**:
  - `runCli` (`lib/cli/cli.dart`) supports `list`, `run <profile> [-- <args>...]`,
    `--version`/`-v` and `--help`/`-h`; no arguments starts the GUI. Everything after `--` is
    passed through verbatim; extra arguments without `--` are a usage error.
  - Exit codes: `0` success; `run` returns FreeCAD's own exit code; `2` usage errors and
    unknown profiles; `1` launch failures, including quarantine-required (the CLI cannot give
    consent — it prints instructions to launch once from the UI).
  - `list` prints tab-separated `name<TAB>buildVersion<TAB>channel<TAB>pyX.Y` for scripts.
  - CLI output is plain English and not localized (machine-readability over translation).
- **Consequences**: Linux shell checks pass for `--version`, `--help`, `list` and all exit
  codes; `run` was exercised with the real Pixi profile (the build ignores `--version` and
  opened the GUI, so it was stopped) — passthrough/exit-code propagation is unit-tested.
  Windows/macOS shell checks remain.
- **Refs**: spec 02 FR-3.1..3.4, `lib/cli/cli.dart`, `lib/main.dart`, `TASKS.md` M3-08, M3-09

### D-035 — CLI wrapper generation and PATH reporting
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: FR-3.2 asks for an on-request platform wrapper with PATH availability reported.
- **Decision**:
  - `CliWrapperInstaller` writes `~/.local/bin/freecad-launcher` on Linux/macOS
    (`#!/bin/sh` + `exec "<app>" "$@"`, chmod 755 via `ProcessRunner`) or
    `%LOCALAPPDATA%\FreeCADLauncher\bin\freecad-launcher.cmd` on Windows (`@echo off` + `%*`).
  - The wrapped target is `$APPIMAGE` when the launcher runs as an AppImage (transient mount
    paths would break), otherwise `Platform.resolvedExecutable`.
  - PATH checking is report-only; shell profiles are never edited. Settings shows the wrapper
    path, installed/PATH status, and install/remove via `SettingsController` signals.
- **Consequences**: Moving/updating the launcher requires reinstalling the wrapper; the Windows
  directory must be added to PATH manually. Linux manual test installed the wrapper into a temp
  home and ran it directly — it proxied to the built CLI and printed the version.
- **Refs**: spec 02 FR-3.2, spec 03 §2.6, `lib/platform/cli_wrapper.dart`,
  `lib/state/settings_controller.dart`, `TASKS.md` M3-09, M3-08

### D-036 — Python package removal is RECORD-based; updates uninstall first (S3)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: S3 needed a reliable removal procedure for `pip install --target`.
  Tested with Python 3.12 / pip 24.0:
  - `pip uninstall --target` does not exist (`no such option: --target`).
  - `pip install --target` without `--upgrade` prints a warning and leaves the package
    untouched (exit 0) when the directory already exists.
  - `pip install --target --upgrade` installs the new version but leaves the previous
    `*.dist-info` behind (e.g. `packaging-24.1.dist-info` next to `packaging-24.2.dist-info`).
- **Decision**:
  - Install/update invocation is `<python> -m pip install --upgrade --target <dir> <spec>`;
    `--upgrade` is mandatory.
  - Uninstall: find every `<normalized-name>-*.dist-info` under the target, parse `RECORD`
    (CSV), delete listed files that resolve inside the target (reject absolute paths and `..`
    escapes), prune emptied directories bottom-up, then delete the dist-info directory.
    `RECORD` includes `__pycache__/*.pyc` entries, so those are removed as well. Verified:
    `six` was fully removed (root `__pycache__` pruned) while `packaging` stayed intact.
  - Update: uninstall the installed package first, then install with `--upgrade` — avoids
    stale dist-info and files shared between versions.
  - `--target` installs do not create console scripts outside the target, so nothing else
    needs cleaning.
- **Consequences**: M4-04/M4-07 implement uninstall as file removal via `ProcessRunner`-free
  Dart I/O plus DB row deletion; safety guards mirror archive extraction; a partially failed
  uninstall surfaces as a job error and the reconciler keeps the DB row until files are gone.
- **Refs**: spec 06 §4.2, `TASKS.md` S3, M4-04, M4-06, M4-07, D-006

### D-037 — Addon catalog model, parsing and cache behavior
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: M4-01; the catalog is a ~1.5 MB zip containing a single ~4 MB JSON with 168
  addon IDs (176 branch entries). Real data shows quirks the parser must tolerate: 43 entries
  have no metadata, `freecad_min/max` are `null`, a string, or `{"version_as_list": [...]}`,
  and three entries lack `zip_url` (two carry `relative_cache_path`, one has neither).
- **Decision**:
  - Domain models keep one `Addon` per ID with one or more `AddonBranch` entries; `package.xml`
    is parsed with `package:xml` into name/description/version/license/pythonmin/tags/people/
    content; requirements and icon come from the JSON metadata.
  - Branch URLs: `zip_url` wins; otherwise `relative_cache_path` is resolved against
    `https://addons.freecad.org/` (parameterized for future settings). Branches with neither
    are skipped; the one uninstallable addon (`Supplemental-Materials`) is omitted.
  - Malformed branches (no `git_ref`) are skipped; `_`/`$` keys and non-array values ignored;
    addons sort case-insensitively by display name.
  - `AddonCatalog` mirrors `ReleasesCatalog`: 6 h TTL, payload stored as
    `<addonsCache>/addon_catalog_cache.zip`, DB row in `catalog_cache` under `addons:catalog`,
    stale fallback with `error` when offline, `AddonCatalogUnavailableException` when no cache
    exists. No ETag (the CDN zip has no stable validator); stats are deferred.
- **Consequences**: Real catalog parses to 167 addons / 175 branches (verified from the local
  zip); UI search helpers (`matchesQuery`, `#tag`) live on `Addon` for M4-02. Stats
  (`addon_stats.json`) remain optional and unimplemented.
- **Refs**: `addon_index_spec.md`, spec 06 §2, `lib/domain/addons/addon.dart`,
  `lib/data/catalog/addon_catalog*.dart`, `TASKS.md` M4-01, M4-02, D-007

### D-038 — Addon catalog controller and UI
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: M4-02; the catalog data layer existed (D-037) but the Addons section was still
  a placeholder.
- **Decision**:
  - `AddonsController` owns catalog loading plus filter state (`query`, content type, installed
    state, FreeCAD version) with a computed `filteredAddons`; it watches `installed_addons`
    (badge counts) and `builds` (version dropdown) and keeps per-addon branch selection.
  - Catalog tab: search supports `#tag` via `Addon.matchesQuery`, filters for content type,
    installed state and installed FreeCAD versions (primary-branch min/max compared with
    `FreeCadVersion`; unparsable bounds are unbounded), stale-cache banner, lazy
    `GridView.builder` of cards with base64 SVG/PNG icons (fallback icon).
  - Detail page: description, version/license/authors/range/last-update/content/tags/
    requirements, repository link (`url_launcher`), branch radio list, and an Install button
    that stays disabled with a note until M4-03 wires the install engine.
  - The Collections tab remains a placeholder (M5-01).
- **Consequences**: `AppServices.addons` is injectable for tests; M4-03 adds the profile picker
  and install action to the detail page; M4-04 reuses the controller for updates.
- **Refs**: spec 03 §2.4, spec 02 FR-4, `lib/state/addons_controller.dart`,
  `lib/ui/addons/**`, `TASKS.md` M4-02, M4-03, M5-01, D-037

### D-039 — Addon install pipeline (download → safe extract → atomic Mod placement)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: M4-03; addon branch zips are GitHub-style archives with a single top-level
  directory, and FreeCAD loads addons from `<profile>/Mod/<AddonId>`. Installs must be safe
  against hostile archives and must not destroy a working addon when a reinstall fails.
- **Decision**:
  - `AddonInstaller` downloads the branch `zip_url` through `Downloader` (download cache),
    extracts into `<dest>.part` with `SafeArchiveExtractor` (zip-slip/bomb/symlink guards,
    D-014), strips a single top-level folder (tolerating `__MACOSX`), and rejects archives that
    expand to zero files — the archive decoder tolerates garbage input, so an empty result must
    be an error.
  - Replacement is atomic: an existing `<dest>` is renamed to `<dest>.old`, staging is renamed
    into place, and the backup is restored if the rename fails; staging/backup are cleaned up.
  - `AddonsController.install` records an `installed_addons` row (gitRef, catalog version,
    `catalogLastUpdate`, `sourceUrl`, `hasRequirements`) and exposes `installing`/`installErrors`
    signals; the detail page installs into a picked profile.
  - Catalog zips have no checksums; trust comes from the curated catalog plus structural
    checks, and the user must confirm nothing extra (installs are explicit user actions).
- **Consequences**: M4-04 reuse: update = install (backup semantics already handle replace),
  remove = delete directory + DB row; requirements install (M4-05) keys off `hasRequirements`.
  Real A2plus install verified (6.1 MB, `package.xml` + `InitGui.py`); GUI load click-through
  remains manual.
- **Refs**: spec 06 §2, spec 02 FR-4, `lib/platform/addon_installer.dart`,
  `lib/state/addons_controller.dart`, `lib/ui/addons/addons_view.dart`, `TASKS.md` M4-03

### D-040 — Addon update detection, pre-update backups and removal
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: M4-04; catalog entries carry `last_update_time` and package versions, while the
  installed row stores the catalog timestamp at install time. Updates must never silently
  destroy a working addon.
- **Decision**:
  - Update available when the branch `lastUpdateTime` is newer than the installed
    `catalogLastUpdate`, or when the installed version differs from the branch package version.
    Detection only flags; nothing auto-installs (D-008).
  - Update = copy the current `<Mod>/<id>` into `<profile>/backups/addon-<id>-<timestamp>/`
    first (abort on failure), then reinstall the selected branch with the existing atomic
    installer (D-039). No backup pruning yet.
  - Remove = delete `<Mod>/<id>` and the `installed_addons` row (0-row delete → error);
    backups are kept. The UI shows Update (when flagged) + Remove for an installed addon, with
    a confirmation dialog for removal.
- **Consequences**: M6-01 adds badges/batch updates on top of `isUpdateAvailable`; M5-06 can
  add backup retention caps; profile Addons tab stays read-only until M5-08.
- **Refs**: spec 06 §2, spec 02 FR-4/FR-10, `lib/state/addons_controller.dart`,
  `lib/ui/addons/addons_view.dart`, `TASKS.md` M4-04, D-008, D-039

### D-041 — Requirements parsing, consent and pip installation (M4-05/M4-06)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: Addons may declare `requirements.txt`; installing them needs an interpreter per
  build kind, a pip invocation into the profile target, and explicit consent because it runs
  third-party install code.
- **Decision**:
  - `parseRequirements` handles names, extras, specifiers and environment markers, strips
    comments, and flags unsupported pip options (`-e`, `--index-url`, …) as invalid entries.
  - Before installing an addon with requirements, the UI shows a consent dialog
    (install packages / addon only / cancel); cancel aborts the whole addon install, addon-only
    skips pip.
  - Interpreter resolution (`PythonEnvResolver`): stored `builds.pythonPath` first; then a
    nearby scan for custom builds; the bundled scan for archive/dmg; for AppImages run
    `--appimage-extract` once into `builds/<id>/extracted/` and use
    `squashfs-root/usr/bin/python`. A missing interpreter surfaces a requirements error without
    failing the addon install.
  - `PipRunner` runs `<python> -m pip install --upgrade --target
    <profile>/AdditionalPythonPackages/pyXY <specs> --disable-pip-version-check
    --no-warn-script-location` with a sanitized environment (`PIP_NO_INPUT`,
    `PYTHONNOUSERSITE`, no `PYTHON*`), writes `logs/pip-<addon>-<ts>.log`, returns the output
    tail on failure, and serializes all pip jobs globally through a queue.
  - Each requirement is recorded in `python_packages` with `source = addon:<id>` and the actual
    target dir.
- **Consequences**: M4-07 renders these rows and implements RECORD-based uninstall (D-036);
  real `six` install verified via the extracted interpreter (`import six` ok).
- **Refs**: spec 06 §4.1/§4.2/§4.3, spec 02 FR-4.7/FR-6, `lib/domain/python/requirements_parser.dart`,
  `lib/platform/python_env.dart`, `lib/platform/pip_runner.dart`, `TASKS.md` M4-05, M4-06, D-006, D-036

### D-042 — Python packages tab and RECORD-based uninstall
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: M4-07; S3/D-036 chose RECORD-based removal, and the Python tab needed install,
  list and remove wired for a profile.
- **Decision**:
  - `PythonUninstaller` normalizes the package name, finds matching `*.dist-info` directories,
    deletes RECORD-listed files that resolve inside the target (rejecting escapes with an
    error), prunes emptied directories and removes the dist-info. Missing dist-info → error.
  - `PythonController` watches `python_packages`, installs pasted specs (reusing
    `parseRequirements`) through the shared pip queue, records rows with `source = manual`, and
    uninstalls files + row; per-profile `installing`/`uninstalling`/`errors` signals drive the
    UI.
  - Profile detail **Python** tab: install dialog (one package per line), list with source
    labels, remove confirmation, empty state.
- **Consequences**: Manual pip flows are now usable without addons; M5-08 can reuse the tab for
  requirements provenance. Real `six` install + RECORD uninstall verified (9 files removed).
- **Refs**: spec 03 §2.3, spec 02 FR-6, `lib/platform/python_uninstaller.dart`,
  `lib/state/python_controller.dart`, `lib/ui/profiles/profile_detail_view.dart`,
  `TASKS.md` M4-07, D-036

### D-043 — Job queue: controller, cancellation and status bar/jobs dialog (M4-08)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: FR-11.1–11.3 ask for a visible job queue with per-job progress, speed, cancel,
  retry, logs and limits (downloads 2, no parallel installs); spec 04 §3 places it under
  `state/`. Builds, addon installs/updates and manual pip installs previously reported progress
  through per-controller signals only.
- **Decision**:
  - `Job` (domain) has kind `download|install|pip`, state `queued|running|completed|failed|
    cancelled`, `fraction`, `detail`, `logPath`, `error`; `JobsController` (state) keeps an
    in-memory list, FIFO-queues per group with limits (downloads 2, install+pip 1), and
    `run<T>()` returns `T?` — `null` when cancelled.
  - `JobContext` exposes progress/detail reporting, `setLogPath` (pip logs), `fail(message)`
    (controllers mark the job failed while still returning their `Result`), and the job's
    `CancellationToken`.
  - Cancellation: `CancellationToken` gained `addListener`; build installs bridge the job token
    to the build's own token so the downloader deletes the `.part`; addon installs pass the job
    token to `AddonInstaller`, which re-checks after download before staging/extracting. Pip jobs
    run through the serialized `PipRunner` and cannot be interrupted mid-run, so cancel takes
    effect once the current pip invocation finishes.
  - A task error after cancellation reports `cancelled`, not `failed`.
  - UI: the shell status bar shows `n · <current label>` while jobs are active and opens a jobs
    dialog (state chip, progress bar, detail, error, log path, Cancel for active, Retry for
    failed/cancelled when a retry callback is registered, Clear finished).
  - `AppServices` creates one shared `JobsController`; builds install, addon install/update and
    manual pip install run as jobs; retries resubmit the original request.
- **Consequences**: M6-03 can run batch updates through the same queue; job history is
  in-memory only (not persisted); retry of an install whose failure was "profile missing" simply
  fails again (the task revalidates).
- **Refs**: spec 02 FR-11, spec 04 §3, `lib/domain/jobs/job_types.dart`,
  `lib/state/jobs_controller.dart`, `lib/ui/jobs/jobs_dialog.dart`,
  `lib/ui/shell/app_shell.dart`, `lib/core/cancellation.dart`, `TASKS.md` M4-08, D-039, D-041

### D-044 — Macro catalog source, cache format and license handling (S4)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: spec 06 §3 named `FreeCAD/FreeCAD-macros` as the candidate source and asked S4 to
  verify the repo/API, URL stability and license before M5-04/M5-05.
- **Findings** (all verified 2026-09-19):
  - `FreeCAD/FreeCAD-macros` is the official repo (org-owned, active, default branch `master`);
    `.FCMacro` files live in category directories and carry in-file metadata (`__Name__`,
    `__Comment__`, `__Author__`, `__Version__`, `__License__` as SPDX, `__Files__`, …). The repo
    has **no repository-level license** (GitHub license: null), so licensing is per macro.
  - FreeCAD's AddonManager (submodule `FreeCAD/AddonManager`) does not read the repo directly:
    `MacroCacheCreator` runs server-side, merges git macros (66) with wiki macros
    (`wiki.freecad.org/Macros_recipes`, 196; a git copy wins duplicates), validates icons and
    publishes **`https://addons.freecad.org/macro_cache.zip`** plus a **`.sha256`** sidecar — the
    same service and pattern as `addon_catalog_cache.zip` (D-037). The official client refreshes
    by comparing the `.sha256` sidecar before downloading the 5.2 MB zip
    (`addonmanager_workers_startup.py`).
  - The zip contains one `macro_cache.json` keyed by macro name: 262 entries today with the full
    macro `code`, `comment`/`desc`, `author`, `date`, `version`, `license`, `wiki`/`url`,
    `on_git`/`on_wiki`, `src_filename` (git path includes category), base64 `icon_data` +
    `icon_extension`/`xpm`, `other_files` (inconsistently a list or a Python-repr string) and
    base64 `other_files_data`. Every entry currently carries `code`.
  - Install semantics (from `Macro.install`): write `code` to `<macro_dir>/<filename>` (git:
    `src_filename` basename; wiki: `filename_from_url` or `<Name>.FCMacro` with spaces → `_`), then
    write `other_files_data` at their relative paths (skip empty keys and the `"ICON"` sentinel)
    and the icon as `basename(icon)` when `icon_data` exists (`<Name>_icon.xpm` for the 4 XPM
    macros).
  - Placement verified on real FreeCAD 1.0.2 (AppImage macro probe): with `FREECAD_USER_HOME` set,
    `FreeCAD.getUserMacroDir(True)` equals the profile root, so catalog macros install directly
    into `<profile>/` (the scanner also checks `<profile>/Macro/`, per spec 04 §"user home").
  - License reality: 172/262 macros declare no license, the rest are mostly LGPL variants, one is
    "All rights reserved".
- **Decision**:
  - v0.1 macro source = `addons.freecad.org/macro_cache.zip` (host/URL overridable for tests),
    consumed like `AddonCatalog`: cached zip in the app cache dir, TTL + stale fallback +
    `catalog_cache` row (`macros:catalog`). Fetch the `.sha256` sidecar first; if unchanged, keep
    the cached payload. Verify the downloaded zip against the sidecar through
    `Downloader(expectedSha256:)`; a mismatch is an error (stale cache if available).
  - Parse into a `MacroCatalogEntry` (domain): name, comment, author, date, version, license,
    wiki/url, onGit/onWiki, srcFilename (+ category from the second git path segment), code,
    icon/iconXpm, otherFiles map. Normalize `other_files` shapes; skip entries missing `code`.
  - License: show the per-macro `license` (SPDX or "Unknown" when empty) in the catalog detail and
    the install confirmation; never block installation (matching FreeCAD). Persist it for
    installed catalog macros via schema v3 (`macros.license`, nullable) in M5-05 so the profile
    macro list and manifests carry provenance; migration v2→v3 with build_runner codegen.
  - M5-04 install needs no git clone, GitHub API or token (no rate limits); it stages
    `<profile>/<filename>.part` and renames atomically like addon installs. `catalogCommit`
    stays null until v0.2; the cache `date` field can seed hash-based update checks later.
- **Consequences**: M5-04/M5-05 have an exact source, format and placement; schema v3 ships with
  M5-05; wiki-sourced macros depend on upstream cache quality (currently all parse); category is
  only available for git-sourced macros; the GitHub token remains unnecessary for macros.
- **Refs**: spec 06 §3, spec 02 FR-7, spec 04 §"user home", verified against
  `FreeCAD/AddonManager` `MacroCacheCreator.py`, `addonmanager_workers_startup.py`,
  `addonmanager_macro.py`, `addonmanager_preferences_defaults.json`; real FreeCAD 1.0.2 probe;
  `lib/data/catalog/addon_catalog.dart`; `TASKS.md` S4; D-005, D-037

### D-045 — Collections: controller, validation and Collections tab (M5-01)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: FR-5.1 asks to create/edit bundles from a profile's installed addons; the spec
  reserved the Addons **Collections** tab (03 §2.4) and the `bundles`/`bundle_items` tables
  already exist in schema v2. Apply/export/import belong to M5-02/M5-03.
- **Decision**:
  - `BundlesController` (state) owns the drift tables through `BundlesDao`: `bundles`/`items`
    signals fed by `watchAll()` plus a new `watchAllItems()` (one item stream; counts and
    per-bundle lists derive from it), `start()`/`dispose()`, and CRUD — `create` (optional
    `initialItems(bundleId)` builder), `createFromProfile` (copies `installed_addons` rows with
    their `gitRef`), `update` (name/description), `delete` (items cascade), `addItem`,
    `removeItem`, `setItemBranch` (upsert on the composite PK).
  - Name rules mirror profiles: trimmed, 1–64 chars, no control characters, case-insensitive
    unique. `checkName` is async and queries the DAO (not the live signal), so validation works
    before `start()`; the dialog localizes the four `BundleNameIssue` cases.
  - `BundlesDao.save` now inserts `bundle.toCompanion(false)` — drift's default `toCompanion(true)`
    would drop null fields and make it impossible to clear `description` on update.
  - Item semantics: `gitRef = null` means "default branch"; the add dialog seeds items with the
    addon's primary branch and the detail row can re-branch or remove. Catalog-unknown addon ids
    are kept and shown as "Not in catalog" (bundles can outlive catalog changes).
  - UI (Collections tab, replacing the placeholder): bundle list with item counts; create/edit
    dialog with an optional "start from profile" seed; detail with an addon picker (search incl.
    `#tag`, already-added state) and delete confirmation. Apply/Export/Import buttons are
    deferred to M5-02/M5-03 to avoid dead ends.
- **Consequences**: M5-02 can consume `itemsFor(bundleId)` directly; M5-03 must validate imported
  ids against the catalog; no schema change (v2 stays).
- **Refs**: spec 02 FR-5.1, spec 03 §2.4, spec 05 `bundles`/`bundle_items`,
  `lib/state/bundles_controller.dart`, `lib/domain/bundles/bundle_rules.dart`,
  `lib/ui/addons/collections_view.dart`, `TASKS.md` M5-01

### D-046 — Bundle apply: pure planner, sequential execution and preview dialog (M5-02)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: FR-5.2 requires a preview (install/update/skip/conflict per item) followed by
  execution with explicit confirmation; M5-01 stored bundles and items.
- **Decision**:
  - `planBundleApply` (pure, `domain/bundles/bundle_planner.dart`) takes domain inputs
    (`BundlePlanEntry`, `BundlePlanInstalledAddon`) plus the catalog and classifies every item as
    `install | update | skip | unavailable`. `unavailable` covers both a missing addon and a
    missing branch of a known addon; `gitRef == null` resolves to the primary branch.
  - Update detection reuses the single rule `addonContentChanged`
    (`domain/addons/addon_update_rules.dart`, extracted from `AddonsController.isUpdateAvailable`)
    on catalog timestamp/version vs installed timestamp/version, plus branch switches.
  - `BundleApplyController` (state) executes the actionable items sequentially through injected
    install/update closures wired to `AddonsController` (parallel installs stay excluded per
    D-043); it exposes `applying/completed/total/currentAddonId` signals and returns a
    `BundleApplySummary` with per-item installed/updated/skipped/failed results; failures are
    collected and the run continues. Each install/update still appears in the jobs dialog.
  - Requirements are handled once per run: the planner flags `hasRequirements` per item and the
    preview offers a single "Also install declared Python requirements" checkbox (default off)
    instead of the per-addon M4-05 consent dialog; unchecked means "addon only".
  - UI: the collection detail gains **Apply**, opening a dialog with three stages — preview
    (target profile picker, per-item action chips, requirement checkbox), running (progress bar)
    and summary (counts plus failed items with errors). Only actionable items execute;
    skip/unavailable are informational.
- **Consequences**: M6-03 batch updates can reuse the controller/summary; apply progress is
  dialog-scoped (not persisted); per-item toggles and conflict resolution are deferred (M6-03);
  a canceled/failed item does not roll back earlier items.
- **Refs**: spec 02 FR-5.2, spec 03 §2.4, `lib/domain/bundles/bundle_planner.dart`,
  `lib/state/bundle_apply_controller.dart`, `lib/ui/addons/collections_view.dart`,
  `TASKS.md` M5-02, D-040, D-043, D-045

### D-047 — Bundle JSON export/import: codec, unresolved entries and name clashes (M5-03)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: spec 05 §4.1 defines bundle JSON (`schema`, `name`, `description`, `addons` with
  `id`/`git_ref`) and asks for import validation plus "warn and keep unresolved entries".
- **Decision**:
  - Pure codec in `domain/bundles/bundle_json.dart`: `encodeBundleJson` writes schema 1 (2-space
    JSON) and `decodeBundleJson` returns a `Result`. Import rejects non-object payloads, invalid
    JSON, `schema != 1` and an empty/omitted name; it normalizes/trims values, drops malformed
    addon entries and treats non-string/blank `git_ref` as null.
  - `BundlesController.exportJson(bundleId)` serializes the stored bundle; `importJson({json,
    catalog, name})` validates the (override-able) name with the existing bundle rules, keeps
    the first occurrence of repeated addon ids, and creates the bundle with all items. Unknown
    catalog ids are kept and returned in `BundleImportResult.unresolvedAddonIds` — no schema
    change, because the detail item list already renders them as "Not in catalog".
  - UI: **Import** on the Collections header (file picker → dialog with editable name, addon
    count and unresolved warning) and **Export** on the bundle detail (`getSaveLocation`,
    sanitized filename). Import errors show inline; success snackbars mention unresolved counts.
  - Name clashes are resolved by the user: the import dialog pre-fills the JSON name and uses the
    same live validation as create, instead of silently suffixing (M5-07 will define manifest
    name-clash handling separately).
- **Consequences**: M5-07 can reuse the codec/validation patterns; import does not auto-install
  and unresolved items remain listed/removable; export/import relies on `file_selector`, already
  used by the custom-build importer.
- **Refs**: spec 05 §4.1, spec 02 FR-5.3, `lib/domain/bundles/bundle_json.dart`,
  `lib/state/bundles_controller.dart`, `lib/ui/addons/collections_view.dart`,
  `TASKS.md` M5-03, D-045

### D-048 — Macro catalog client, installer and Macros screen (M5-04)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: S4/D-044 selected `addons.freecad.org/macro_cache.zip` (+`.sha256`) as the official
  source; M5-04 needs the client and single-macro install before M5-05 adds the scanner.
- **Decision**:
  - `MacroCatalog` (data) mirrors `AddonCatalog`: 6 h TTL, `catalog_cache` key `macros:catalog`,
    stale-cache fallback, `MacroCatalogException` when nothing is cached. It additionally fetches
    the tiny `.sha256` sidecar first and skips the ~5 MB zip when the hash is unchanged, verifies
    the downloaded zip with `Downloader(expectedSha256:)` (mismatch → error; stale fallback when a
    cache exists) and stores the verified hash in the cache row `etag`.
  - `parseMacroCatalog` (domain) maps `macro_cache.json` values to `MacroCatalogEntry`
    (code, comment/description, author, date, version, license, wiki/url, onGit/onWiki,
    `src_filename` + derived category, icon name/base64/extension, XPM, `other_files`,
    `other_files_data`), normalizes the two upstream `other_files` shapes (`list` and
    Python-repr string), skips entries without code and sorts by name. `fileName` follows
    FreeCAD's rules (git basename → wiki `filename_from_url` → `<Name>.FCMacro` with spaces → `_`).
  - `MacroInstaller` (platform) writes `code` atomically (`.part` → rename) into the profile root
    (`FREECAD_USER_HOME` = macro dir, D-044), decodes `other_files_data` as base64 (skipping the
    `"ICON"` sentinel, empty keys and unsafe paths) and writes the icon (XPM as
    `<Name>_icon.xpm`, otherwise the icon basename); existing files are replaced.
  - `MacrosController` (state): catalog signals + search filter, `installedMacros` watched from
    `macrosDao.watchAll()`, `install` runs through the jobs queue (retryable, cancel-aware),
    upserts a `macros` row with `source = catalog` (reinstall keeps id/installedAt) and exposes
    per-macro `installing`/`installErrors`.
  - UI: the Macros screen now renders the catalog (search, refresh, stale banner, profile picker,
    license or "Unknown license", Installed badge, Install button); the installed-file list,
    delete/reveal/open actions and filesystem reconciliation remain M5-05.
- **Consequences**: M5-05 builds the installed list/scanner on `installedMacros`; license is only
  displayed here (persistence is part of M5-05 per D-044); `macros.catalogCommit` stays null until
  v0.2 hash-based updates.
- **Refs**: spec 06 §3, spec 02 FR-7.2, `lib/data/catalog/macro_catalog.dart`,
  `lib/domain/macros/macro_catalog_entry.dart`, `lib/platform/macro_installer.dart`,
  `lib/state/macros_controller.dart`, `lib/ui/macros/macros_view.dart`,
  `TASKS.md` M5-04, D-044

### D-049 — Macro scanner, schema v3 and installed-macro actions (M5-05)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: FR-7.1/7.3/7.4 need the installed list (name, size, date) with delete/reveal/open;
  spec 04 notes the macro dir is the profile root (`FREECAD_USER_HOME`) with a legacy `Macro/`
  subdir; D-044 deferred license persistence to this task.
- **Decision**:
  - Schema **v3**: `macros.license` (text?) and `macros.sizeBytes` (int?), added via
    `onUpgrade(from < 3)` with regenerated drift code; catalog installs now store the SPDX
    license (null when the cache has none) and the summed size of installed files.
  - `MacroScanner` (platform) lists `<profile>/*.FCMacro` first, then `<profile>/Macro/*.FCMacro`
    (`.fcmacro` matched case-insensitively); duplicate file names prefer the profile root; each
    entry carries name, fileName, path, size and modified time.
  - `MacrosController` reconciliation: `start()` triggers `reconcileAll()` (every profile);
    `reconcile(profileId)` deletes rows whose file disappeared and inserts local rows (source
    `local`, size/modified from disk) or refreshes size/modified when they changed; catalog rows
    are kept while their file exists.
  - `delete(profileId, fileName)` removes the file (if present) and the row; missing rows error.
  - `MacroFileActions` (platform) reveals/opens a path through `ProcessRunner` argument arrays:
    Linux `xdg-open [dirname]` / `xdg-open <file>`; macOS `open -R` / `open`; Windows
    `explorer.exe /select,<path>` / `cmd /c start "" <path>`. No shell interpolation.
  - UI: the Macros screen is tabbed — **Installed** (profile picker, size/date/license rows,
    Open/Reveal/Delete with confirmation) and **Catalog** (unchanged). External file changes are
    picked up on the next startup reconcile.
- **Consequences**: M5-08 can render the profile Macros tab from the same index; reconciliation is
  startup-only (no filesystem watcher) and macros placed externally are imported as `local`; the
  legacy `Macro/` directory keeps working.
- **Refs**: spec 02 FR-7.1/7.3/7.4, spec 04 §"user home", `lib/platform/macro_scanner.dart`,
  `lib/platform/macro_file_actions.dart`, `lib/state/macros_controller.dart`,
  `lib/ui/macros/macros_view.dart`, `TASKS.md` M5-05, D-044, D-048

### D-050 — Config paths, snapshots and backup cap (M5-06)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: FR-8.1 wants config/data paths plus `user.cfg`/`system.cfg` presence and an
  "open config dir" action; FR-8.2 wants timestamped backup/restore inside the profile. The
  Config and Backups profile tabs were placeholders.
- **Decision**:
  - `ConfigSnapshotService` (platform) snapshots `<profile>/user.cfg` and
    `<profile>/system.cfg` into `<profile>/backups/config-<UTC timestamp>Z/` using the same
    timestamp format as addon backups (D-040); it returns null when neither file exists, lists
    snapshots newest-first (creation time parsed from the directory name, filesystem mtime as
    fallback), restores by copying files back over the profile root, deletes snapshots and keeps
    at most `maxSnapshots` (default 10) by pruning the oldest after each create.
  - All snapshot IO is synchronous inside async methods (small files), so the flows stay usable
    in widget tests and avoid partial state; `ConfigSnapshotException` wraps failures.
  - `ProfilesController` owns the per-profile snapshot signal
    (`configSnapshots`), refreshes it on demand, and exposes `createConfigSnapshot`,
    `restoreConfigSnapshot`, `deleteConfigSnapshot` returning `Result`s (service injected via
    AppServices).
  - `FileActions` (renamed from the macro-only helper) gains `openDirectory`; the profile
    **Config** tab shows root/user.cfg/system.cfg/backups with sizes or "Created on first
    launch", an "Open profile folder" action, "Back up config" (snackbar on create or when
    there is nothing to back up) and the snapshot list; the **Backups** tab shows the snapshot
    list with restore (confirmation) and delete. Reset and the preference browser stay v0.2
    (FR-8.3/8.4); manifest export/import arrives with M5-07.
- **Consequences**: M5-08 can treat Config/Backups as wired; snapshots are not recorded in the
  DB (filesystem is the source of truth, consistent with profile backups); restoring does not
  auto-snapshot the current files first (the list makes that explicit).
- **Refs**: spec 02 FR-8.1/8.2, spec 03 §2.2, `lib/platform/config_snapshots.dart`,
  `lib/platform/file_actions.dart`, `lib/state/profiles_controller.dart`,
  `lib/ui/profiles/config_snapshots_view.dart`, `TASKS.md` M5-06, D-028, D-040

### D-051 — Profile detail tab wiring (M5-08, partial: Macros tab)
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: M5-08 asks that every profile-detail tab be functional. Addons (M4-11), Python
  (M4-07), Config and Backups (M5-06) were done; Macros was still a "coming soon" placeholder.
- **Decision**:
  - The installed-macro list is extracted into `InstalledMacrosList`/`InstalledMacroTile`
    (`ui/macros/installed_macros.dart`) and now backs both the Macros screen **Installed** tab
    and the profile detail **Macros** tab.
  - The shared widget ensures `MacrosController.start()` and runs a per-profile `reconcile`
    when first mounted, so opening the tab picks up files added outside the app without a
    restart; `_ComingSoonTab` is removed (no remaining placeholders in the detail view).
  - Manifest export/import buttons for the **Backups** tab remain M5-07; until then the tab
    offers config snapshots only.
- **Consequences**: All six profile-detail tabs are functional; M5-07 completes the Backups
  tab; the Macros screen and profile tab share one implementation.
- **Refs**: spec 03 §2.2, `lib/ui/macros/installed_macros.dart`,
  `lib/ui/profiles/profile_detail_view.dart`, `TASKS.md` M5-08, D-049, D-050

### D-052 — Macro directory is `<profile>/Macros` (correction)
- **Date**: 2026-09-19
- **Status**: Accepted (supersedes the placement part of D-044 and D-049)
- **Context**: D-044/D-049 placed catalog macros directly in the profile root based on a 1.0.2
  `getUserMacroDir(True)` probe; the product owner corrected the convention to
  `<profile>/Macros`.
- **Decision**:
  - `ProfilePaths.macros` = `<profile>/Macros`, created with the profile layout
    (`directoriesFor`).
  - `MacroInstaller` targets that directory; `MacroScanner` scans only it (no root or legacy
    `Macro/` scanning); `delete` and the installed-list path resolution use it as well.
  - Spec 04 ("user home") and spec 06 §3 were updated; startup reconciliation will drop index
    rows whose files are not in `Macros/`. FreeCAD's own macro path is left to the build/profile
    configuration (the launcher neither writes `MacroPath` nor depends on the collapsed root).
- **Consequences**: Profiles created before this fix keep their root-level macros until moved
  manually (no released builds); the launcher no longer relies on FreeCAD's collapsed user-home
  macro dir.
- **Refs**: spec 04 §"user home", spec 06 §3, `lib/domain/profiles/profile_paths.dart`,
  `lib/platform/macro_scanner.dart`, `lib/state/macros_controller.dart`,
  `lib/ui/macros/installed_macros.dart`, D-044, D-049

### D-053 — Force `MacroPath` to `<profile>/Macros` on every launch
- **Date**: 2026-09-19
- **Status**: Accepted (completes D-052)
- **Context**: D-052 corrected the launcher's macro directory, but FreeCAD resolves its macro
  path from `User parameter:BaseApp/Preferences/Macro` → `MacroPath` (used by
  `getUserMacroDir(True)`), which otherwise falls back to the collapsed user home.
- **Decision**:
  - `FreeCadPreferences.ensureMacroPath(userCfgPath, macroPath)` edits `<profile>/user.cfg`
    before every launch (called from `ProfilesController.launch`), inserting/replacing
    `Root/BaseApp/Preferences/Macro/FCText@MacroPath = <profile>/Macros/` and preserving the
    rest of the document. A missing/empty file is replaced by a minimal `FCParameters`
    document; an unparsable file is left untouched (returns false) so a corrupt config is never
    clobbered.
  - Editing uses the existing `xml` dependency; the stored value uses the native trailing
    separator (FreeCAD normalizes `/` to `PATHSEP` on read).
  - Verified against real FreeCAD 1.0.2: with that `user.cfg`, `getUserMacroDir(True)` returns
    `<profile>/Macros/`; without it, the collapsed profile root.
- **Consequences**: Macros written by FreeCAD/AddonManager and the launcher agree on
  `<profile>/Macros/`; config snapshot restores may revert the preference, but the next launch
  re-forces it; `getUserMacroDir()` (no argument) still reports FreeCAD's internal default.
- **Refs**: spec 04 §"user home", spec 06 §3, `lib/platform/freecad_preferences.dart`,
  `lib/state/profiles_controller.dart`, `TASKS.md` M5-05, D-052

### D-054 — Macro catalog installs pick the profile in a dialog
- **Date**: 2026-09-19
- **Status**: Accepted
- **Context**: The Macros **Catalog** tab followed the Addons screen pattern (a target-profile
  dropdown above the list); for browsing a read-mostly catalog with many rows that is noisy, and
  it implied a single target for the whole screen.
- **Decision**:
  - The Catalog tab no longer shows a profile dropdown. Every macro row keeps an **Install**
  button (disabled only while that macro is installing); installed macros additionally show an
  `Installed in N profile(s)` chip.
  - Clicking Install opens a `Select the target profile` dialog: radio list of profiles,
    preselecting the first profile that does not have the macro; profiles that already have it
    are disabled and labelled "Installed"; with no profiles the dialog only explains how to
    proceed. Confirming installs into the chosen profile and updates `selectedProfileId`, so the
    Installed tab follows.
  - The Installed tab keeps its profile dropdown (it lists one profile at a time).
- **Consequences**: Installing the same macro into several profiles is a two-click flow; the
  catalog report stays clean; l10n adds `macrosSelectProfile` (reusing `addonsInstalledIn` for
  the count chip).
- **Update (same day)**: the profile list in the dialog is scrollable (max height 320 px) so it
  stays usable with many profiles; a widget test seeds 30 profiles and scrolls to the last.
- **Refs**: spec 03 §2.5, `lib/ui/macros/macros_view.dart`, `test/ui/macros_view_test.dart`,
  TASKS.md M5-04, D-048

### D-055 — Profile manifest export/import (M5-07)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: M5-07 implements FR-9.1 (manifest JSON with metadata, addons, Python packages,
  bundles and config file list; no payloads), FR-9.3 (import never overwrites) and FR-9.4
  (cross-OS portability, absolute-path reporting). Spec 05 §4.2 documents a metadata-only shape,
  but its §3 and the FR-9 acceptance require "config intent (paths rewritten, absolute paths
  reported)", which needs the config text at import time. Four scope choices were confirmed with
  the product owner before implementing.
- **Decision**:
  - The manifest stays JSON-only (no addon/macro payloads; the full `.zip` with payload toggles
    remains v0.2/B-03). Shape: `schema 1`, `exported_at`, `source {os, arch}`,
    `profile {name, build, channel, python}`, `addons [{id, git_ref, version}]`,
    `python_packages [{name, version, source}]`, `bundles`, `config_files` and an additive
    `config` map carrying the `user.cfg`/`system.cfg` text (only those keys, ≤ 4 MiB total).
  - Pure codec and absolute-path scanner live in `domain/profiles/profile_manifest.dart`;
    `ProfileManifestController` (state) owns export, preview and import. `AppServices` wires the
    reinstall callbacks to `AddonsController` (catalog loaded lazily) and `PythonController`
    (`install` gained an optional `source`, so imported packages keep their recorded provenance:
    `manual`/`requirements`; `addon:<id>` rows are covered by the addon install).
  - `bundles` exports the names of collections whose items are all installed in the profile;
    import matches them by name and reports the missing ones without creating them.
  - `build` is a version; the preview selects the installed build with the same version and
    channel (then version-only) among builds that are `installed` with a detected Python. When
    nothing matches, the dialog lists every usable build and warns, mirroring the create-profile
    picker.
  - Name clash (FR-9.3): the preview pre-fills `<name> (imported)`, then `(imported 2)`…; the
    dialog validates structurally and `ProfilesRepository` enforces case-insensitive uniqueness,
    so an existing profile is never overwritten.
  - On confirm: atomic profile creation, config write, `FreeCadPreferences.ensureMacroPath`
    rewrites `MacroPath` to the new profile's `Macros/` (D-053-compatible; a minimal `user.cfg`
    is created when the manifest has none), then — optional, default on — addons are reinstalled
    sequentially and non-addon-sourced packages are pip-installed grouped by recorded source.
    Failures are collected in a summary (the profile stays), a config-write failure rolls the
    profile back, and missing bundle names are surfaced as warnings.
  - Absolute paths (POSIX `/…`, Windows `C:\`, UNC `\\…`) are scanned from the embedded config
    with the pure scanner and listed in the preview before importing.
  - UI: **Import manifest** in the Profiles header (opens file picker → preview dialog with
    editable name, build picker, contents, path/bundle warnings, reinstall and requirements
    checkboxes, inline progress/errors), **Export manifest** in the profile card menu and the
    profile **Backups** tab, which also offers Import; file dialogs follow the bundle flows
    (`getSaveLocation`/`openFile`, `file_selector`).
- **Consequences**: FR-9.1's "no addon payloads" is respected while config intent travels;
  config files bigger than 4 MiB or non-`user.cfg`/`system.cfg` keys are rejected/ignored;
  imports run through the existing job queue (one pip job per source group); the manifest does
  not carry macros/addon payloads (v0.2 full export, OQ-5); `ProfileManifestController` is
  injectable in `AppServices` for tests.
- **Refs**: spec 02 FR-9.1/9.3/9.4, spec 03 §2.3/§3.7, spec 05 §3/§4.2,
  `lib/domain/profiles/profile_manifest.dart`, `lib/state/profile_manifest_controller.dart`,
  `lib/ui/profiles/profile_manifest_dialogs.dart`, `TASKS.md` M5-07, D-028, D-041, D-046, D-047,
  D-053

### D-056 — Addon pinning/freeze per profile (M6-10)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: users need to freeze an addon version in a profile so a working setup is not
  changed by update checks or bundle apply (FR-4.10, requested mid-M6). Addons live per profile
  (`<profile>/Mod/<id>`, unique row per `(profileId, addonId)`), so a pin is naturally scoped to
  one profile; different profiles may install/pin different branches or versions of the same addon.
- **Decision**:
  - `installed_addons.pinnedAt` (nullable timestamp, schema v4 via `onUpgrade` addColumn) — pinned
    means non-null; pin records the moment, unpin clears it. `AddonsController.pin`/`unpin`
    return `Result`; `installedAddons` keeps the rows, so `isPinned(profileId, addonId)` is cheap.
  - Hard freeze: `UpdatesController.outdated` skips pinned rows (no badge anywhere for that
    profile; other profiles still badge); `AddonsController.update` refuses pinned addons with an
    explicit error (unpin first); `planBundleApply` maps a pinned installed entry to `skip` with
    `pinned: true` (never update); the catalog detail hides Update and shows a Pinned chip for the
    selected profile; the profile Addons tab shows a Pinned chip plus a pin/unpin action.
  - The manifest carries `addons[].pinned` (additive optional field, schema 1); import reinstalls
    and re-pins those ids. Pin is per profile, so two manifests may disagree without conflict.
- **Consequences**: schema v4 (drift migration), update flow (D-040) unchanged for unpinned
  addons, M6-01 badges respect pinning, bundle preview shows pinned items as skipped. Pinning is
  not a semver range — it freezes at the installed version until unpinned/reinstalled.
- **Refs**: spec 02 FR-4.10, spec 03 §2.3/§2.4/§3.6, spec 05 §3/§4.2,
  `lib/data/tables/installed_addons.dart`, `lib/state/addons_controller.dart`,
  `lib/domain/bundles/bundle_planner.dart`, `TASKS.md` M6-10, D-005, D-039, D-040, D-046, D-055

### D-057 — Addon update checks and badges via a dedicated UpdatesController (M6-01)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: FR-10.1/10.4 require checking addon updates against the cached catalog, badging
  affected profiles/addons, a "Check" action and cached timestamps. D-040 already defines the
  pure update rule and the per-item update flow; M6-02 (builds) and M6-03 (batch) will extend the
  same surface. Four scope questions were confirmed with the product owner.
- **Decision**:
  - New `UpdatesController` (`state/updates_controller.dart`) aggregates addon update state:
    `outdated`/`outdatedByProfile` computed from the catalog + `installed_addons` (so it reacts
    to installs, removals and catalog loads), plus `checking` and `lastCheckedAt` signals.
  - `check()` recomputes against the already-cached catalog (loads it only when absent), never
    forces a network refresh, persists `updates.addons.lastCheckedAt` in `settings` and returns
    the outdated count (null when the catalog is unavailable). Notify-only; no auto-install.
  - Badges everywhere: status-bar `N updates` chip opening a summary sheet (grouped by profile,
    version change + branch, last-checked line, Check button), profile cards, the profile Addons
    tab rows, and Addons catalog cards (a check action lives in the catalog header). Pinned
    addons (D-056) are excluded per profile.
  - M6-02 adds builds to `UpdatesController`; M6-03 consumes the same state for batch updates.
- **Consequences**: update state is derived, so no duplicate persistence beyond the timestamp;
  the status-bar chip appears as soon as a loaded catalog detects outdated rows, even before the
  first explicit check; the summary sheet is informational (per-item update stays in the addon
  detail until M6-03).
- **Refs**: spec 02 FR-10.1/10.3/10.4, spec 03 §1/§2.2/§2.3/§2.4/§3.6,
  `lib/state/updates_controller.dart`, `lib/ui/updates/updates_summary_sheet.dart`,
  `TASKS.md` M6-01, D-008, D-040, D-056

### D-058 — Build update checks and badges (M6-02)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: FR-10.2 requires checking for new stable FreeCAD releases on demand; FR-1.8's
  in-place build update is v0.2 (B-02). The releases catalog and stable candidates already exist
  (`BuildsController.availableBuilds`, M2-02/M2-03), and D-057 anticipated adding builds to
  `UpdatesController`. Two scope questions were confirmed with the product owner.
- **Decision**:
  - Checked builds: `channel == stable`, `kind != custom`, status `installed`, with a parseable
    `FreeCadVersion`; compared against the newest stable candidate of the **same asset kind**
    (appimage/archive/dmg) for the current platform/arch. Custom and weekly builds never badge;
    a build with no newer same-kind release is quiet.
  - Notify-only: badge/chip on the Versions → Installed tile plus a summary-sheet entry
    (installed → latest version); no install/update button (B-02 v0.2). The "Check updates" action
    loads the addon and releases catalogs cache-first (no forced network) and stamps
    `updates.addons.lastCheckedAt` and `updates.builds.lastCheckedAt`.
  - `UpdatesController` gains a `BuildsController` dependency, `outdatedBuilds` and
    `outdatedCount` (addons + builds); `lastCheckedAt` becomes a computed max of the two
    per-kind timestamps. The status-bar chip and summary sheet report the combined count and the
    sheet lists a FreeCAD-builds section before the per-profile addon groups.
- **Consequences**: schema unchanged; existing addon badges keep working; M6-03 can consume
  `outdatedCount`/`outdatedBuilds` for a batch flow once in-place updates land; no update action
  is offered on builds yet.
- **Refs**: spec 02 FR-1.8/FR-10.2/FR-10.3, spec 03 §2.2/§3.6, `lib/state/updates_controller.dart`,
  `lib/domain/builds/build_update.dart`, `lib/ui/builds/builds_view.dart`,
  `lib/ui/updates/updates_summary_sheet.dart`, `TASKS.md` M6-02, D-008, D-057, B-02

### D-059 — Desktop form style: label-left form rows (M6-11)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: M4-09 introduced a compact input theme with floating labels (`labelText` inside
  the border) and 8 px corners. The frozen prototype (`prototype-final`) used traditional
  desktop forms: a fixed label column left of each input (`"Label:"` with an optional icon,
  130 px, 12 px gap), default outlined borders (4 px) with `isDense`, and 12 px between rows.
  The product owner asked to return to that style; four scope questions were confirmed.
- **Decision**:
  - `InputDecorationThemeData` is revised: 4 px corner radius (supersedes the M4-09 8 px value),
    Flutter's dense default content padding, scheme-colored enabled/focused/error borders,
    `isDense: true`.
  - Shared widgets in `lib/ui/widgets/form_row.dart`: `FormRow` (fixed 195 px label column with
    optional icon and colon, 12 px gap, `Expanded` field, top alignment, 12 px bottom spacing)
    plus thin `FormTextField`/`FormDropdown` wrappers. Converted forms drop `labelText` and use
    hints inside the field. The 195 px width (prototype value 130 px, widened ~50% on 2026-09-20
    after visual review) keeps longer labels such as "Version label (optional):" on one line.
  - Applied to dialogs and inline labeled forms: profile create/edit + duplicate, custom build
    import (form constrained to 640 px), manifest import, bundle create/edit/apply/import, Python
    specs (multiline, label top-aligned), and the addon detail install-target picker. Labeled
    dialogs widen from 420 to 480 px.
  - Search fields and the Addons filter row keep the compact unlabeled style
    (`_CompactDropdown` remains for filters); pickers that only select a context (e.g. the
    installed-macros profile picker) stay compact.
- **Consequences**: all form labels move out of the input border; the M4-09 theme regression
  test is revised; the prototype look is restored without reviving prototype code.
- **Refs**: spec 03 §1, `lib/app.dart`, `lib/ui/widgets/form_row.dart`,
  `test/ui/app_theme_test.dart`, `TASKS.md` M6-11, prototype-final `lib/view/widgets.dart`

### D-060 — Batch addon updates ("Update all") (M6-03)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: FR-10.3/10.4 and spec 03 §3.6 ask for a batch flow with per-item toggles from the
  update badge; D-057 anticipated M6-03 consuming the same state, and D-046's bundle apply
  already established the sequential/summary pattern. In-place build updates are v0.2 (B-02), so
  the batch covers addons only. Two scope questions were confirmed with the product owner.
- **Decision**:
  - `UpdatesController.applyUpdates(List<AddonUpdate>)` runs the selected items sequentially via
    `AddonsController.update` (each one a job through the shared queue), tracks
    `applying`/`applyCompleted`/`applyTotal`/`applyCurrentAddonId`, is failure-tolerant and
    returns an `AddonUpdateApplySummary` (updated/failed + error per item).
  - The summary sheet pre-checks every outdated addon, offers per-item toggles and an
    "Update selected (N)" button; while running it shows aggregate progress and the current
    addon; afterwards it shows "N updated"/"M failed" with "Retry failed" (reruns only the
    failures). Toggle state is UI-local (`_unchecked`), so newly detected updates start checked
    and failures stay checked after a run.
  - Build entries remain informational (no update action until B-02); pinned addons never reach
    the list (D-056); nothing runs without an explicit confirmation.
- **Consequences**: no new persistence or schema; per-item jobs are visible in the status bar and
  jobs dialog as usual; after a successful run the outdated list shrinks reactively while the
  summary remains visible in the sheet.
- **Refs**: spec 03 §3.6, spec 02 FR-10.3/10.4, `lib/state/updates_controller.dart`,
  `lib/ui/updates/updates_summary_sheet.dart`, `TASKS.md` M6-03, D-008, D-043, D-046, D-056,
  D-057

### D-061 — Settings screen: persisted theme, update cadence and log level (M6-04)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: FR-12.1 and spec 03 §2.6 ask for a real settings screen; M1-08/M3-09 only had
  data directory, version/license, CLI wrapper and diagnostics. M6-05 (cache management) and
  M6-06 (debug bundle) are separate tasks, and the GitHub token is v0.2 (B-07, OQ-3). Three
  scope questions were confirmed with the product owner.
- **Decision**:
  - Pure types/helpers in `lib/domain/settings/app_settings.dart`: `AppThemeMode`
    (system/light/dark, default dark per D-010), `UpdateCadence` (manual/daily/weekly with
    intervals), `isUpdateCheckDue`, `LogLevel` parsing, and storage keys matching spec 05
    (`theme_mode`, `update_check_interval`, `log_level`). Values persist as plain strings via
    the existing `settings` table (`SettingsDao`).
  - `SettingsController` gains `themeMode`/`updateCadence`/`logLevel` signals plus persisting
    setters; `AppServices.bootstrap` loads them before `runApp`; `app.dart` watches
    `themeMode` for `MaterialApp.themeMode`; `main.dart` applies `logLevel` to `appLogger`
    through a signals effect, so level changes take effect immediately.
  - Update cadence: `UpdatesController.checkIfDue(cadence)` waits for the restored saved
    timestamps and runs the existing cache-first `check()` only when the interval elapsed;
    `AppShell` triggers it once on mount. Manual cadence never checks; the user-set cadence is
    the visible reason for the startup check (NFR-6).
  - Settings UI is section cards (General, Logs, Command-line launcher, About, Diagnostics)
    using `FormRow`/`FormDropdown` per D-059; the data directory and logs folder show the path
    with an "open folder" action; the version/license card is informational.
  - Cache management stays in M6-05, the debug bundle in M6-06, and the GitHub token in B-07;
    theme persistence lives here (M6-08 keeps a11y/keyboard shortcuts).
- **Consequences**: no schema change (settings rows only); the diagnostics panel is unchanged;
  opening Settings is enough to change theme/cadence/level; cache and token sections can be
  added without reworking the layout.
- **Refs**: spec 02 FR-12.1, spec 03 §2.6, spec 05 `settings`, `lib/domain/settings/app_settings.dart`,
  `lib/state/settings_controller.dart`, `lib/state/updates_controller.dart`, `lib/ui/settings/**`,
  `TASKS.md` M6-04, D-010, D-017, D-035, D-057, D-059

### D-062 — `--version` launches FreeCAD with `--console`
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: GUI FreeCAD builds ignore `--version` and open the full GUI (observed with the
  local Pixi build in M3-08), so scripted version queries (`freecad-launcher run <profile> --
  --version`) popped a window instead of printing. Console-mode builds (FreeCADCmd) are
  unaffected by `--console`.
- **Decision**: `LaunchPlanBuilder` prepends `--console` when the user arguments contain
  `--version` and `--console` is not already present. No other argument is rewritten;
  everything else stays verbatim passthrough (D-034). The manual AppImage install smoke test
  runs `--console --version` directly.
- **Consequences**: version queries always exit without a GUI; unit, platform, CLI and manual
  test expectations update; `--console` is harmless on console binaries.
- **Refs**: spec 02 FR-3, spec 04 §4.1, `lib/domain/profiles/launch_plan.dart`,
  `test/manual/real_install_linux_test.dart`, `TASKS.md` M3-08, D-029, D-034

### D-063 — Cache management: sizes, per-category clear and retention (M6-05)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: FR-11.4 and spec 03 §2.6 ask for cache sizes and clearing; M6-04 deferred the
  cache section to this task. Three scope questions were confirmed with the product owner.
- **Decision**:
  - `CacheCategory` (downloads/github/addons/macros) and `CacheRetention` (forever/7/30/90,
    default 30) join `lib/domain/`; the retention value persists under spec key
    `cache_retention_days` (stored as the number of days, `0` = forever).
  - `CacheService` (platform) walks each category directory for sizes, clears a category's
    contents, removes the matching `catalog_cache` row (`github:releases:freecad`,
    `addons:catalog`, `macros:catalog`) so the next load refetches, and prunes files in the
    download cache older than the retention window.
  - `CacheController` (state) exposes `sizes`/`busy` and refreshes after clearing/pruning; the
    Settings **Cache** card shows a size + Clear per category, a refresh action, the retention
    dropdown and **Clean up now**. Clear/clean-up are disabled while any job is active (a
    running download may still be writing into the cache). `AppShell` prunes on startup with
    the persisted retention.
  - Clearing a catalog never touches installed builds, profiles or addons (files are already
    copied out of the cache); the catalogs held in memory refetch on the next explicit refresh
    or restart, since the controllers keep their in-memory copy.
- **Consequences**: sizes are computed on demand (no background watcher) and refresh after any
  clear/prune; clearing the 800 MB download cache is a single click and only costs a
  re-download if that asset is needed again; retention defaults to 30 days so old artifacts do
  not accumulate.
- **Refs**: spec 02 FR-11.4, spec 03 §2.6, spec 05 `settings`, `lib/platform/cache_service.dart`,
  `lib/state/cache_controller.dart`, `lib/ui/settings/settings_view.dart`, `TASKS.md` M6-05,
  D-037, D-048, D-061

### D-064 — Debug bundle: full redacted logs, DB-free inventory (M6-06)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: FR-12.4 and spec 07 §6 ask for a support bundle (logs + versions + diagnostics,
  no secrets, DB-free) users can attach to issues. Three scope questions were confirmed with the
  product owner.
- **Decision**:
  - `DebugBundleService` (platform) writes a zip atomically (`.part` → rename) containing
    `system.txt`, `diagnostics.txt` and **every** file under `logs/` (basename entries), each
    log line passed through `redactSensitive`; log bytes are decoded with
    `allowMalformed: true` so a corrupt file cannot break the export. Suggested name:
    `freecad-launcher-debug-YYYYMMDD-HHMMSS.zip`.
  - `DebugBundleController` (state) runs diagnostics and builds the DB-free summary: launcher
    version, Dart version, OS/build, data directory, builds (version/channel/kind/status/Python)
    and profiles (name, bound build, Python, addon/package counts). No `config.db`, no tokens,
    no GitHub token (B-07 not shipped).
  - Settings → Logs gains a **Debug bundle** row: Export opens `getSaveLocation` (zip), then a
    snackbar with the file name and a **Reveal** action (`FileActions.reveal`). Exporting state
    disables the button.
  - Full logs were chosen over recent tails; the Flutter framework version is not included
    because it is not exposed at runtime without adding a dependency (Dart version and OS build
    are).
- **Consequences**: bundles are small (~12 KB in the dev app) and safe to attach; absolute
  paths and the user name still appear (not secrets, needed for support); macOS Gatekeeper
  diagnostics read `notApplicable` on other platforms.
- **Refs**: spec 02 FR-12.4, spec 03 §2.6, spec 07 §6, `lib/platform/debug_bundle.dart`,
  `lib/state/debug_bundle_controller.dart`, `lib/ui/settings/settings_view.dart`,
  `TASKS.md` M6-06, D-063

### D-065 — Keyboard shortcuts and a11y pass (M6-08)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: spec 03 §4 defines the desktop keyboard map (`Ctrl/Cmd+1..6` sections,
  `Ctrl/Cmd+N` new profile, `F5` refresh, `Ctrl/Cmd+F` search, `Esc` closes dialogs) but no
  bindings existed; theme persistence moved to M6-04 (D-061). Scope confirmed with the product
  owner: full map, context-aware F5/Ctrl+F, guideline tests plus fixes.
- **Decision**:
  - `AppShell` wraps the shell in `CallbackShortcuts` with an autofocus `Focus` node, so the
    shortcuts fire regardless of which widget has focus and no-op where a section has no target.
    Both `control` and `meta` variants are bound (Linux/Windows and macOS).
  - Sections expose a `SectionShortcuts` interface (`refresh`, `focusSearch`) and their state
    classes are public; AppShell drives the active section through `GlobalKey`s. `F5` refreshes
    the active section (profile sizes, Versions/Addons/Macros catalogs with a forced reload);
    `Ctrl/Cmd+F` focuses the Addons catalog search or switches the Macros view to its Catalog
    tab and focuses the search. Addons and Macros use explicit `TabController`s for this.
  - `Ctrl/Cmd+N` switches to Profiles and opens the create dialog; `Esc` dismisses dialogs and
    sheets through Flutter's default `DismissIntent` (verified by test).
  - A11y: `test/ui/a11y_test.dart` runs the labeled-tap-target, Android tap-target and
    text-contrast guidelines across all six sections. Settings path values are plain `Text`
    (the previous `SelectableText` exposed a 16–32 px text-field tap target that failed the
    guideline).
- **Consequences**: shortcuts are not user-configurable (future work); `F5` on Profiles only
  recomputes sizes (the list itself is DB-stream driven); guideline tests gate the visible
  sections but do not replace per-OS manual passes.
- **Refs**: spec 03 §4, `lib/ui/shell/app_shell.dart`, `lib/ui/shell/section_shortcuts.dart`,
  `lib/ui/addons/addons_view.dart`, `lib/ui/macros/macros_view.dart`,
  `lib/ui/builds/builds_view.dart`, `lib/ui/profiles/profiles_view.dart`,
  `lib/ui/settings/settings_view.dart`, `test/ui/a11y_test.dart`, `test/app_shell_test.dart`,
  `TASKS.md` M6-08, D-061, D-017

### D-066 — Performance pass: startup timing and off-thread catalog parsing (M6-09)
- **Date**: 2026-09-20
- **Status**: Accepted
- **Context**: M6-09 requires warm startup < 2 s and no UI blocking on catalog loads. The three
  catalogs are loaded at app start (all sections are built by the shell's `IndexedStack`), and
  parsing the 4 MB addon JSON / 5 MB macro zip ran synchronously on the UI isolate: measured at
  190 ms and 390 ms respectively right after the first frame.
- **Decision**:
  - Startup timing logs (tag `perf`): `startup: bootstrap at X ms` and
    `startup: first frame at X ms` from `main.dart`, plus one line per catalog load (entries +
    elapsed). `appLogger` defaults to a no-op `Logger` so tests and CLI never hit a late
    initialisation.
  - Heavy catalog parsing runs on a background isolate with `Isolate.run` in `AddonCatalog`,
    `MacroCatalog` and `ReleasesCatalog`; the UI isolate only performs async file IO and awaits
    the parsed list. Exception types propagate to the existing error paths.
- **Measurements** (release build, `flutter build linux`, warm data root with catalogs cached,
  3 runs on the dev machine): wall clock from process launch to the first-frame log
  553/559/561 ms; in-process bootstrap 14–23 ms; first frame 142–186 ms. Addon catalog
  (176 addons) and macro catalog (262 macros) parse off-thread after the first frame.
- **Consequences**: each parse pays a small isolate spawn overhead (~10–20 ms wall, off the UI
  thread); parsed objects are copied between isolates (plain data, negligible); the `perf` log
  lines make future regressions measurable in `logs/app.log`.
- **Refs**: spec 02 NFR-2, `lib/main.dart`, `lib/core/log.dart`,
  `lib/data/catalog/addon_catalog.dart`, `lib/data/catalog/macro_catalog.dart`,
  `lib/data/catalog/releases_catalog.dart`, `TASKS.md` M6-09, D-037, D-048

### D-067 — Home dashboard, news feed and shell navigation state (M6-12)
- **Date**: 2026-09-21
- **Status**: Accepted; superseded by D-104 (single last-used-card clause only)
- **Context**: Home was a static welcome screen; the product owner asked for a dashboard
  (general stats, launch the last used profile, check for updates) plus a user-configurable
  RSS/Atom news section (default `https://freecad.org/news.rss`, which currently 404s). Four
  scope questions were confirmed. Spec 03 §2.1 also describes a first-run checklist and a
  guided setup flow.
- **Decision**:
  - `ShellController` (`state/shell_controller.dart`) owns the selected `AppSection`; the shell
    and keyboard shortcuts drive it, so Home tiles and the first-run steps can navigate between
    sections. AppShell no longer keeps `_selectedIndex`.
  - Home (normal): five stat tiles (installed builds, profiles, installed addons, macros,
    Python packages) that navigate to their section, a "last used profile" card
    (`max(lastUsedAt)`, falling back to the first profile) with Launch (reusing
    `launchProfile`), an updates card (`outdatedCount`) whose button runs
    `UpdatesController.check()` and opens the existing summary sheet, and a news card.
  - Home (first run, no builds or profiles): the welcome text becomes a 3-step checklist
    (version → profile → addons) with actions, followed by the same dashboard (stats at zero).
    The "Guided setup" wizard from spec 03 §2.1 stays deferred (noted in VERIFICATION).
  - News: `NewsFeed` (data) downloads the configured URL through the shared `Downloader`,
    caches it under `cache/news/news_feed.xml` with a `catalog_cache` row (`news:feed`, journal
    `etag` = URL) and a 6 h TTL, serves stale items when offline, and parses RSS 2.0/RDF and
    Atom (`parseNewsFeed`, RSS dates in RFC 822/1123 with numeric offsets). The card shows up
    to 5 items (title + date, tap opens the browser), a stale hint, or an inline error with
    Retry; the default URL's 404 is therefore a normal error state.
  - Settings **General** gains a "News feed URL" field (key `news_feed_url`; empty resets to
    the default). The news cache is a fifth `CacheCategory` (size/clear support).
  - `AppServices` wires `NewsFeed`/`NewsController`/`ShellController`; `AppServices` accepts a
    `NewsController` override for tests.
- **Consequences**: Home performs one feed request per 6 h window (NFR-6: user-visible feature);
  the news URL is the only free-form network setting; section navigation is now shared state
  rather than shell-local; widget tests that pump the whole app must `runAsync` the initial
  frame because the feed touches the real filesystem.
- **Update (2026-09-21)**: the default feed URL is `https://blog.freecad.org/feed/atom/`
  (verified `application/atom+xml`), replacing the not-yet-published
  `https://freecad.org/news.rss`.
- **Refs**: spec 03 §2.1/§2.6, `lib/state/shell_controller.dart`,
  `lib/state/news_controller.dart`, `lib/data/catalog/news_feed.dart`,
  `lib/ui/home/home_view.dart`, `lib/ui/settings/settings_view.dart`, `TASKS.md` M6-12,
  D-010, D-061, D-063, D-065

### D-068 — Reproducible AppImage build (S5)
- **Date**: 2026-09-21
- **Status**: Accepted (runtime pin superseded by D-084)
- **Context**: spec 07 §3 proposed a pipeline (`flutter build linux` → AppDir → appimagetool
  type-2 + zsync update info + SHA-256 sidecar) and asked S5 to validate tooling, reproducibility
  and clean-distro behavior. There is no git remote yet (OQ-7), so CI could not be executed;
  the spike ran locally with containers standing in for clean machines. Four scope questions
  were confirmed with the product owner.
- **Decision**:
  - `packaging/appimage/build_appimage.sh` stages the AppDir (Flutter bundle under `usr/bin`,
    AppRun, `.desktop`, generated icon) and bundles the shared-library closure via `ldd`,
    excluding the vendored official AppImage **excludelist** plus a forced-bundle font/text set
    (`libharfbuzz`, `libfreetype`, `libfontconfig`, `libexpat`, `libz`, `libuuid`, `libfribidi`,
    `libgmp`, `libcom_err`, `libgpg-error`, `libICE`, `libSM`) because minimal systems do not
    ship them. Pinned tools: appimagetool 1.9.1 and the type-2 runtime, both SHA-256 verified.
  - Determinism: `SOURCE_DATE_EPOCH` (last commit time) drives appimagetool; the packaged
    AppImage is touched to that timestamp and the `.zsync` is regenerated with `zsyncmake`
    (appimagetool's own zsync embeds the file mtime and is not stable). Two consecutive full
    builds produced identical hashes: AppImage `a83b1ffb…` (29,866,488 bytes, 69 libs) and
    `.zsync` `9da830f1…`.
  - Update information is embedded as
    `gh-releases-zsync|<owner>|<repo>|<channel>|FreeCADLauncher-*-x86_64.AppImage.zsync`;
    owner/repo are environment parameters with placeholders until the remote exists (OQ-7).
    The workflow `.github/workflows/release-appimage.yml` runs the script on `v*` tags and
    uploads the AppImage, `.sha256` and `.zsync`.
  - Glib family fix: the bundle ships `libgio-2.0.so`/`libglib-2.0.so`/`libgobject-2.0.so`/
    `libgmodule-2.0.so` symlinks to their `.so.0` files. Without them `path_provider_linux`
    `dlopen`s a second glib copy, loses the GApplication id and writes to
    `<appSupport>/freecad_launcher` instead of `<appSupport>/org.freecad.ext.launcher`.
  - Icon: generated placeholder (FreeCAD glyph from the bundled icon font, white on a blueGrey
    rounded square, 256/512 px) pending real branding (OQ-2).
- **Verification**: host runs pass with FUSE and with `APPIMAGE_EXTRACT_AND_RUN=1`; clean
  `ubuntu:24.04` and `fedora:41` containers (Xvfb + Mesa EGL/GL/GLES libs, since headless
  containers lack the driver stack every desktop has) print `FreeCAD Launcher 0.1.0` and exit 0
  via `--version`; the GUI launches from the AppImage on the host.
- **Consequences**: CI execution is pending a remote; containers substitute clean VMs (no
  VMs available) and use extract-and-run (no `/dev/fuse`); gdk-pixbuf loaders/GTK immodules are
  not bundled yet, so M7-01 must verify icons/GUI assets on a truly clean target; the update
  information stays a placeholder until the repo identity is known.
- **Update (2026-09-21)**: the temporary icon is superseded by the original design workflow in
  D-070 (master SVG + render script); M7-01 still owns the clean-target icon/asset check.
- **Refs**: spec 07 §2/§3, `packaging/appimage/**`,
  `.github/workflows/release-appimage.yml`, `TASKS.md` S5, M7-01, D-011, D-016, OQ-2, OQ-7

### D-069 — Relabel installed builds
- **Date**: 2026-09-21
- **Status**: Accepted
- **Context**: the product owner asked for a pre-M7 refinement: installed builds should be
  renameable to a user-chosen display label. `builds.version` is load-bearing (unique key
  `(platform, arch, channel, version, assetName)`, build update detection, addons
  FreeCAD-version filter, manifest export/import matching), so it cannot be overwritten.
- **Decision**:
  - Schema v5 adds a nullable `builds.label` column (`onUpgrade` v4 → v5 `addColumn`); `version`
    is never modified by relabeling.
  - A display extension `Build.displayLabel` (in `data/database.dart`, next to the drift model)
    returns `label ?? version`; every user-facing surface uses it (Versions → Installed tile
    and remove dialog, profile cards/detail/dialogs, manifest import build picker, Home
    last-used card, CLI `list`, debug-bundle inventory). All version-based logic keeps using
    `version`.
  - Relabel is offered for every installed build (catalog and custom) through a pencil action
    on the Installed tile opening a small dialog pre-filled with the current label; clearing the
    field removes the label so the automatic version label returns. Labels are trimmed,
    limited to 64 characters (same as profile names) and need not be unique — they are
    display-only. Invalid labels are rejected by the dialog; `BuildsController.relabel` also
    validates and returns `Result`.
  - `BuildsController.relabel(buildId, label?)` trims, maps empty/whitespace to `null`, stamps
    `updatedAt` and returns the updated build.
- **Consequences**: every surface must remember to display `label ?? version` (one extension
  call); update badges show raw versions; no filesystem or manifest impact.
- **Refs**: spec 03 §2.2, spec 05 §2, `lib/data/tables/builds.dart`, `lib/data/database.dart`,
  `lib/data/daos/builds_dao.dart`, `lib/state/builds_controller.dart`,
  `lib/ui/builds/builds_view.dart`, `TASKS.md` R-01, D-021

### D-070 — Launcher icon: original design, font glyphs stay
- **Date**: 2026-09-21
- **Status**: Accepted
- **Context**: D-068 shipped a temporary icon (FreeCAD glyph recolored onto a blueGrey rounded
  square). The FPA brand guidelines (fpa.freecad.org/handbook/process/logo.html) state that the
  FreeCAD logo is an FPA trademark, must not be modified (no color/shape/style changes, no
  effects), and third parties may use it only to credit FreeCAD or link to freecad.org. The
  in-app icon font `assets/fonts/freecad-launcher-icons.ttf` was created by the project owner,
  so it is in-house artwork and can stay.
- **Decision**:
  - The application icon is an **original design** that does not modify, recolor or compose the
    FreeCAD logo. It is authored by the project owner.
  - The in-app font/glyph set (`lib/ui/icons.dart`, `assets/fonts/freecad-launcher-icons.ttf`)
    stays as-is: owner-created artwork, licensed with the project (GPL-3.0-or-later).
  - Asset pipeline: `packaging/appimage/freecad-launcher.svg` is the master; a committed render
    script converts it to the committed PNGs (`freecad-launcher.png` 512, `-256.png` 256) so the
    AppImage build keeps consuming fixed files and stays reproducible. The official FreeCAD logo
    is not bundled; attribution ("FreeCAD and the FreeCAD logo are trademarks of the FreeCAD
    Project Association AISBL", link to freecad.org) belongs in README/release docs.
  - The FreeCAD brand palette (Tufts Blue `#418FDE`, Light Red `#FF585D`, Off Black `#212529`,
    white) is available to the design but not required.
- **Consequences**: the D-068 placeholder PNGs are replaced by renders of the master SVG; the
  final design is blocked on the owner editing the SVG (R-02); Windows/macOS icon exports
  (`.ico`/`.icns`) remain part of B-11.
- **Refs**: spec 07 §3/§7, `packaging/appimage/freecad-launcher.svg`,
  `packaging/appimage/render_icons.sh`, `TASKS.md` R-02, D-011, D-016, D-068, OQ-2

### D-071 — AppImage productionization (M7-01)
- **Date**: 2026-09-21
- **Status**: Accepted; superseded by D-103 (toolchain pin clause only)
- **Context**: S5/D-068 proved the pipeline; M7-01 must make a tag build a shippable artifact.
  Three production choices were confirmed with the product owner (CI Flutter pin, placeholder
  policy, icon sizes).
- **Decision**:
  - **Version/tag consistency**: `packaging/check_version.sh` compares `appVersion` in
    `lib/core/constants.dart` with the `pubspec.yaml` version (build suffix ignored) and, when
    `GITHUB_REF_NAME`/`TAG_NAME` is a release tag, with the tag itself. It runs in CI and is
    called by `build_appimage.sh`, so a mismatched tag cannot produce an artifact.
  - **Toolchain pin**: the CI matrix is pinned to Flutter 3.41.4, the same version the release
    workflow already used and that local/verified builds use (no `stable` drift).
  - **Update-info placeholders**: `build_appimage.sh` aborts when `APPIMAGE_OWNER`/
    `APPIMAGE_REPO` are still `REPLACE_*`; local experiment builds can set
    `ALLOW_PLACEHOLDER_UPDATE_INFO=1`. The tag workflow always passes the real repository
    identity, so released artifacts never carry placeholders.
  - **Icons**: `render_icons.sh` renders 16/32/48/64/128/256/512 px and the AppDir installs the
    full `hicolor` tree plus the root 512 px icon; appimagetool keeps generating `.DirIcon`.
  - **Release workflow**: tag/dispatch builds run the pipeline, verify the `sha256` sidecar and
    smoke-test the artifact (`APPIMAGE_EXTRACT_AND_RUN=1 … --version`); release creation,
    changelog and the test matrix stay in M7-02.
- **Consequences**: local builds without real owner/repo now need the explicit override flag;
  six small PNGs are committed and must be regenerated with `render_icons.sh` whenever the
  master SVG changes; CI and release builds share one toolchain version.
- **Verification (2026-09-21)**: local artifact `721cdb2b…` (29,903,352 bytes); `sha256` sidecar
  verifies; three consecutive packaging runs produced identical AppImage/zsync hashes
  (`a5c38072…`); host FUSE and extract-and-run `--version` exit 0; `desktop-file-validate` OK;
  clean `ubuntu:24.04`/`fedora:41` containers (Xvfb + Mesa) print the version and open a GUI
  window without gdk-pixbuf/GTK asset errors. Finding: the GTK runner initializes before Dart
  `main`, so even `--version` needs a `DISPLAY` — the release smoke test runs under `xvfb-run`,
  and "clean" means a desktop-baseline X11 stack (`libX11` is excludelist baseline). The GitHub
  tag run is still pending a remote (OQ-7).
- **Refs**: spec 07 §1/§3/§4.2, `packaging/check_version.sh`,
  `packaging/appimage/{build_appimage.sh,render_icons.sh}`,
  `.github/workflows/{ci,release-appimage}.yml`, `TASKS.md` M7-01, D-068, D-070, OQ-7

### D-072 — Linux-first completion; CI, release workflow and cross-platform deployment deferred
- **Date**: 2026-09-24
- **Status**: Accepted
- **Context**: M6 is complete and M7-01 shipped the AppImage pipeline. The remaining v0.1 work
  mixed Linux functionality verification with GitHub CI/release automation and Windows/macOS
  deployment. A git remote is still missing (OQ-7), so the CI and release workflow cannot be
  executed or verified, and Windows/macOS need those machines. The product owner wants Linux
  functionality finished and verified first.
- **Decision**:
  - M7 is now **Linux v0.1 completion**: Linux manual functional pass (M7-06), `LICENSE`/notices
    (M7-03), README + user guide (M7-04), and clean-machine validation on a Linux VM from the
    locally built AppImage (M7-05). Nothing is published in M7.
  - A new deferred phase **M8 — Packaging, CI & cross-platform release** collects: the release
    workflow (was M7-02 → M8-01), the first GitHub CI matrix run (M8-02), and Windows/macOS
    launcher artifacts + deployment checks (was B-11 → M8-03/M8-04).
  - Windows/macOS manual checks and OQ-7 no longer block M7; they block M8.
- **Consequences**: the v0.1 exit no longer requires a published GitHub release; publishing and
  cross-platform deployment happen in M8 once a remote exists. `.github/workflows/` and spec 07
  §3/§4.2 stay as written but are executed later. `VERIFICATION.md` gained an M8 section.
- **Refs**: spec 08 §1 (M7/M8), spec 07 §4.2, spec 09 OQ-1/OQ-7, `TASKS.md` M7/M8,
  `VERIFICATION.md` §2, M1-09, M7-01, B-11

### D-073 — Clean-machine Linux validation deferred to M8
- **Date**: 2026-09-24
- **Status**: Accepted
- **Context**: M7-05 (clean-machine validation on a Linux VM) was the last verification gate in
  M7. The AppImage pipeline already runs the app in clean `ubuntu:24.04`/`fedora:41` containers
  (D-071), and the product owner wants docs/licensing finished before spending time on a VM pass.
- **Decision**: M7-05 moves to M8 as M8-05 (clean-machine validation on a Linux VM with the
  locally built AppImage). M7 exit no longer requires a clean-machine pass; it requires the
  manual smoke matrix (done, M7-06), `LICENSE`/notices (M7-03) and user docs (M7-04).
  M8-01 (release workflow) now depends on M7-04.
- **Consequences**: v0.1 completion is not blocked on a VM; the clean-machine check still happens
  once, in M8, with the other packaging/deployment work.
- **Refs**: `TASKS.md` M7/M8, D-071, D-072

### D-074 — Licensing artifacts, copyright holder and notices generation
- **Date**: 2026-09-24
- **Status**: Accepted
- **Context**: M7-03 needs `LICENSE`, `THIRD_PARTY_NOTICES.md` and trademark attribution; the
  copyright holder and a reproducible notices source were undecided.
- **Decision**:
  - Copyright holder (owner-provided): **Frank Martínez \<mnesarco at gmail\>**. `LICENSE` is the
    verbatim GPL-3.0 text; hand-written sources carry `SPDX-License-Identifier:
    GPL-3.0-or-later` (generated `*.g.dart`/l10n files excluded).
  - `THIRD_PARTY_NOTICES.md` is generated by `tool/generate_third_party_notices.dart` from
    `dart pub deps --json`, restricted to the shipped closure (direct + transitive; dev-only
    subtrees excluded), with full license texts grouped by identical text and a
    package/version/license table. Bundled system libraries and the FreeCAD trademark
    attribution (spec 07 §7, D-070) are static sections emitted by the generator.
  - The Linux AppImage ships `LICENSE` and `THIRD_PARTY_NOTICES.md` under
    `/usr/share/doc/freecad-launcher/`.
- **Consequences**: regenerating notices is one command and deterministic; the M8 release
  workflow should regenerate them and fail on drift.
- **Refs**: spec 07 §3/§7, D-070, `TASKS.md` M7-03, `THIRD_PARTY_NOTICES.md`, `LICENSE`,
  `tool/generate_third_party_notices.dart`, `packaging/appimage/build_appimage.sh`

### D-075 — Profile launches no longer override `HOME`
- **Date**: 2026-09-30
- **Status**: Accepted
- **Context**: D-005 isolated every user directory by pointing `HOME` at `<profile>/home`. In
  practice FreeCAD 1.0+ honors `FREECAD_USER_HOME`, so the extra `HOME` override mostly broke
  host-level integration (portals/file dialogs, bookmarks, dotfiles, per-user caches) while the
  `<profile>/home` tree stayed nearly empty. Owner request: don't touch `HOME`.
- **Decision**:
  - `LaunchEnvironment.build` no longer sets `HOME` on Linux/macOS; the inherited value passes
    through unchanged (Windows never set it). `FREECAD_USER_HOME`, `FREECAD_USER_TEMP`, the
    Linux `XDG_*` dirs and `TMPDIR`, and the Windows `APPDATA`/`LOCALAPPDATA`/`TEMP`/`TMP`
    overrides stay, so FreeCAD config/data/temp remain per-profile.
  - `<profile>/home` is dropped from `ProfilePaths` and `directoriesFor`; existing directories
    are left on disk untouched.
  - The headless Python/AppImage probe keeps its throwaway `HOME` (it is not a profile launch).
- **Consequences**: `HOME`-keyed state (dotfiles, bookmarks, user caches, sockets) is shared
  between profiles and with the host; isolation relies on FreeCAD's own env handling plus the
  XDG/temp overrides. D-005's isolation mechanism is otherwise unchanged.
- **Refs**: D-005, spec 04 §4.1, spec 05 §3, `lib/domain/profiles/launch_environment.dart`,
  `lib/domain/profiles/profile_paths.dart`, `TASKS.md` R-09

### D-076 — Macro icons from the catalog with a two-level cache
- **Date**: 2026-09-30
- **Status**: Accepted
- **Context**: The macro catalog payload carries base64 `icon_data` for 202/262 macros (147 PNG,
  52 SVG, 3 XPM), but the Macros lists always showed a generic icon. Rendering naively would
  base64-decode and allocate new byte arrays on every build, defeating Flutter's `ImageCache`
  and flutter_svg's picture cache; loading from network is not an option (icons ship inside the
  cached catalog zip).
- **Decision**:
  - `MacroIcon` renders the entry icon when renderable: SVG via `flutter_svg`, raster via
    `Image.memory` decoded at display size (`cacheWidth`). XPM and iconless entries keep the
    generic `Icons.auto_fix_high_outlined` icon. Both the Catalog list and the Installed list
    (catalog lookup by `fileName`) use it.
  - `MacroIconCache` (platform) is a two-level cache: a bounded in-memory LRU (16 MiB) over
    content-addressed files under `cache/macros/icons/<sha256>.<format>`. Stable byte arrays let
    the framework image/SVG caches hit; disk reads/writes are synchronous (small files) so the
    widget needs no `FutureBuilder`.
  - The icons directory lives inside the `macros` cache category, so Settings ▸ Cache sizes and
    clearing include it. A catalog refresh prunes icon files not present in the new catalog.
- **Consequences**: Icons are rendered from local cached data with no extra network requests;
  the 3 XPM-only macros and macros without icon data stay generic. `MacroIconCache.resolve`
  negatively caches undecodable payloads.
- **Refs**: spec 03 §2.5, D-044, D-048, `lib/platform/macro_icon_cache.dart`,
  `lib/ui/macros/macro_icon.dart`, `TASKS.md` R-10

### D-077 — Weekly builds (v0.2 plan): dated tags, channel filter, notify-only updates
- **Date**: 2026-09-30
- **Status**: Accepted
- **Context**: FR-1.7's weekly channel is the next build-management increment. Analysis (session
  R6) showed the foundation already exists (`WeeklyVersion`, `ReleaseTag.parse`, weekly asset
  classification, channel-agnostic install pipeline, checksum sidecars), but
  `BuildsController.loadCatalog` drops every non-stable candidate, the Available UI has no
  channel concept and `UpdatesController.outdatedBuilds` assumes a stable-only list. The real
  catalog holds 83 dated weekly releases plus a rolling `weeklies` release last published
  2025-11-26 (stale) while dated weeklies continue weekly.
- **Decision**:
  - Scope for this increment is weekly only; the legacy (1.0.x) channel stays in B-01.
  - Weekly builds are exposed through a channel filter on Versions → Available (Stable
    default, Weekly selectable); weekly rows use a human label ("Weekly 2026-09-30"), a
    development badge and an install confirmation warning. The Install action stays explicit
    (D-008) and weekly builds are never auto-installed or auto-updated.
  - The rolling `weeklies` release is skipped: it duplicates dated Linux assets and is
    outdated; only `weekly-YYYY.MM.DD` tags are collected.
  - Weekly update checks are notify-only; FR-1.8's apply is deferred to B-02 (in-place build
    updates). Stable and weekly suggestions are never mixed.
  - Catalog collection uses `AssetClassifier.selectFor` so each release yields one candidate
    per platform/arch (resolves macOS10/11/15 weekly variants).
- **Consequences**: weekly profiles work end-to-end (checksum verify, Python probe, isolated
  launch) but weekly builds have no semver, so they do not appear in the Addons
  FreeCAD-version filter (addon installs still work through the unfiltered branch list); the
  `stableLine`/legacy rules are untouched.
- **Refs**: FR-1.7/FR-1.8, spec 06 §1.3/§1.5, spec 03 §2.2, `TASKS.md` B-01 breakdown, D-008,
  D-021, D-058, `docs/impl/STATUS.md` session R6

### D-078 — CalVer transition readiness (FreeCAD 26.3+)
- **Date**: 2026-09-30
- **Status**: Accepted
- **Context**: Owner states FreeCAD changes from semver to calendar versioning starting with the
  next stable (26.3). `FreeCadVersion.tryParse` already accepts `26.3` and numeric ordering puts
  CalVer above every 1.x line, so catalogs, update checks and sorting keep working; but the
  stable/legacy split uses the hardcoded `stableLine = 1.1`, so once 26.3 is current, 1.1.x would
  still classify as `stable` instead of `legacy`. RC suffixes (`1.1rc3`, presumably `26.3rc1`)
  are ignored by the tag regexes, as before.
- **Decision**:
  - The current stable line is derived from the catalog at load: the highest supported stable
    version (`major.minor`) present defines the line; supported stable versions below it are
    `legacy`. Example: while the newest tag is 1.1.x, 1.0.x is legacy; once 26.3 appears, 1.1.x
    and 1.0.x become legacy; once 27.3 ships, 26.3 becomes legacy too.
  - Cross-schema ordering stays numeric (CalVer > semver); weekly dates are only compared inside
    the weekly channel, never against stable versions.
  - `FreeCadVersion.stableLine`/`isLegacy` are retired in favor of the catalog-derived line
    (backlog task B-14); spec 06 §1.3/§1.5 updated with the new tag pattern and ordering rule.
- **Consequences**: classification now needs catalog context (a second pass over collected
  candidates), including offline/stale loads; tests must cover `26.3 > 1.1.4`, the transition
  split and RC tags still being ignored. The legacy channel work (B-01) consumes the derived
  line.
- **Refs**: spec 06 §1.3/§1.5, spec 02 FR-1.1/FR-1.7/FR-1.8, `TASKS.md` B-14, D-021, D-077

### D-079 — Copyright notices in sources, docs and About
- **Date**: 2026-09-30
- **Status**: Accepted
- **Context**: D-074 shipped SPDX license identifiers and generated third-party notices, but no
  per-file copyright line and no visible holder notice in the app. The owner asked to include
  copyright notices while keeping the holder identity already recorded in D-074.
- **Decision**:
  - Every hand-written file that carries an `SPDX-License-Identifier` also carries
    `SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>` immediately above it
    (generated files excluded, same rule as D-074).
  - README's license section and the Settings → About card show
    `Copyright 2026 Frank Martínez <mnesarco at gmail>`; the third-party notices generator emits
    the same line in its header.
  - The holder string stays as recorded in D-074: `Frank Martínez <mnesarco at gmail>`.
- **Consequences**: source headers gain one line; regenerating `THIRD_PARTY_NOTICES.md` keeps
  the line deterministic; the About card needs one l10n string.
- **Refs**: D-074, `TASKS.md` R-11, `LICENSE`, `README.md`, `THIRD_PARTY_NOTICES.md`,
  `tool/generate_third_party_notices.dart`

### D-080 — About dialog with the official FreeCAD logo
- **Date**: 2026-09-30
- **Status**: Accepted
- **Context**: D-070/R-02 deliberately shipped no FreeCAD artwork and the README/notices stated
  so. The owner wants the About experience to show the official FreeCAD logo (big) together
  with the FPA trademark notice and the independent-project statement.
- **Decision**:
  - The official `org.freecad.FreeCAD.svg` app icon (extracted from the official FreeCAD 1.1.3
    AppImage, bundled unmodified) is stored at `assets/images/freecad-logo.svg`.
  - A dedicated About dialog, opened from the Settings › About card, shows the logo at 96 px,
    the trademark line ("FreeCAD and the FreeCAD logo are trademarks of the FreeCAD Project
    Association AISBL.") and the statement that FreeCAD Launcher is an independent, community
    driven, open source project developed and maintained by Frank D. Martínez (aka mnesarco).
  - README and `THIRD_PARTY_NOTICES.md` change from "ships no FreeCAD artwork" to "bundles the
    official logo unmodified for attribution only".
- **Consequences**: the repo and AppImage now contain FreeCAD artwork; the trademark section
  documents its attribution-only use; D-070's glyph-font decision is unaffected.
- **Refs**: D-070, D-011, `TASKS.md` R-12, `assets/images/freecad-logo.svg`, `README.md`,
  `tool/generate_third_party_notices.dart`

### D-081 — GitHub publishing: public repo, `devel` branch, manual CI AppImage
- **Date**: 2026-09-30
- **Status**: Accepted
- **Context**: OQ-7 (git remote) is resolved: the project publishes at
  `https://github.com/mnesarco/FreeCAD-Launcher`. The local `v2` branch holds all work while
  `main` is an ancestor 73 commits behind. CI/release workflows existed but the release path
  needed an explicit manual trigger and the repository URL was unknown.
- **Decision**:
  - The public repository is `mnesarco/FreeCAD-Launcher`; the public development branch is
    `devel` (renamed from `v2`) and becomes the default branch. `main` stays local for a future
    release line (D-015's "merge to main after M2" is superseded).
  - The AppImage is produced by CI only, through the manually triggered **Release AppImage**
    workflow (`workflow_dispatch`): every run uploads AppImage + `.sha256` + `.zsync` artifacts;
    optional inputs (`create_release`, `tag`, `prerelease`) create or update a GitHub Release.
    Pushing a `vX.Y.Z` tag triggers the same workflow.
  - CI keeps the 3-OS test matrix, runs on `devel`/`main`, and now fails on
    `THIRD_PARTY_NOTICES.md` drift in addition to generated-file drift.
  - The tracked 4 MB prototype artifact `addon_catalog_cache.json` is removed from the tree
    (kept in history).
  - README/user guide point to the Releases page; badges link the CI and release workflows.
- **Consequences**: the first push publishes the full history (prototype included); releases
  require a `vX.Y.Z` tag matching `appVersion` (packaging/check_version.sh); OQ-7 closes.
- **Refs**: OQ-7, spec 07 §4/§5, `TASKS.md` M8-01/M8-02, D-015, D-068, D-071

### D-082 — CI test scope during the Linux-first phase
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: The first GitHub CI run (M8-02) was green on Linux but exposed 21 test failures
  on Windows/macOS from POSIX assumptions (path separators, `/var` symlink resolution,
  `xdg-open` vs `explorer.exe`, shell-script fake interpreters, Linux AppImage probe behavior).
  The product is Linux-first for v0.1 (D-072) and Windows/macOS work is M8-03/M8-04.
- **Decision**: the CI matrix keeps version/codegen/analyze and a release build on all three
  OSes (D-003), but `flutter test` runs on Linux only until the suite is portabilized
  (M8-06). Windows/macOS artifacts may be built from CI before their tests run there.
- **Consequences**: Windows/macOS test coverage is paused and tracked as M8-06; Linux coverage
  is unchanged; the three-OS build/analyze guarantee remains.
- **Refs**: D-003, D-072, `TASKS.md` M8-02/M8-06, OQ-1

### D-083 — macOS CI jobs disabled until M8-04
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: macOS arm64 runners queue slowly and the macOS build still needs dedicated
  attention; the owner asked to disable macOS in CI for now. Linux is the v0.1 target (D-072)
  and the release workflow is Linux-only, so publishing is unaffected.
- **Decision**: remove `macos-latest` from the CI matrix (Linux + Windows remain, each with
  analyze and release build; tests stay Linux-only per D-082). The macOS job and its
  `flutter build macos` step return with M8-04.
- **Consequences**: macOS compile regressions are not caught in CI until M8-04; nothing else
  changes for the AppImage pipeline.
- **Refs**: D-072, D-082, `TASKS.md` M8-04, `TASKS.md` M8-06

### D-084 — Pin the AppImage type-2 runtime to a dated release
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: The first manual AppImage workflow run on GitHub failed at runtime
  verification: the runtime was fetched from the rolling `continuous` release
  (`1cc49bcf…`, pinned by D-068) whose asset had been rebuilt since. `continuous` is a moving
  target and cannot be treated as reproducible.
- **Decision**: pin `runtime-x86_64` to the dated, immutable release `20251108`:
  `https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64`,
  SHA-256 `2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d`.
  `build_appimage.sh` defaults updated; ``continuous`` is no longer used.
- **Consequences**: runtime upgrades are explicit (bump URL + hash); the AppImage build stays
  reproducible on CI and locally.
- **Refs**: D-068, S5, M7-01, `.github/workflows/appimage-release.yml`,
  `packaging/appimage/build_appimage.sh`

### D-085 — Custom addon provenance and conflict policy
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: B-10 adds addon installs from a repository URL, a local archive and a local
  directory link. The existing `installed_addons` row has no way to tell these apart from
  catalog installs, and update/remove behavior differs per source.
- **Decision**: schema v6 adds `installed_addons.source` (`catalog|repo|zip|symlink`, default
  `catalog`) and `sourcePath` (local archive path or symlink target); `sourceUrl` keeps the
  catalog zip URL and additionally stores the repository URL for `repo`. Update checks
  (`AddonsController.isUpdateAvailable`, `UpdatesController.outdated`) only consider `catalog`
  rows. A fresh custom install is blocked while the resolved id already exists in the profile
  (DB row or an orphaned `Mod/<id>` directory); explicit `Update` (repo) / `Reinstall` (zip)
  actions may replace the row of the same source with the usual `.old` backup.
- **Consequences**: provenance is queryable and drives UI/actions; existing rows migrate to
  `catalog`; users must remove an addon before installing a different source over it.
- **Refs**: `docs/impl/PLAN-B10-custom-addons.md`, FR-4.8, D-039, D-040, B-10a/B-10b

### D-086 — Custom addon source resolution: package.xml, id and hosts
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: Repository/archive/directory sources carry no catalog metadata; the addon
  identity (the `Mod/<id>` directory) must be derived deterministically and safely.
- **Decision**: every custom source must contain a parseable `package.xml` at the addon content
  root (after the existing single-root stripping); otherwise the install is rejected. The addon
  id is derived from the repository path segment (URL), the single archive root directory name
  (fallback: archive filename stem), or the directory basename (dev link), then validated
  (no path separators/control chars, not `.`/`..`, ≤ 64 chars). Repository URLs support GitHub
  (`…/archive/<ref>.zip`), GitLab (`…/-/archive/<ref>/<name>-<ref>.zip`) and Gitea/Forgejo/
  Codeberg (`…/archive/<ref>.zip`); a direct `.zip`/`.tar.gz`/`.tgz` URL is used as-is (ref
  optional). Unknown hosts are rejected with guidance to paste a direct archive URL. package.xml
  parsing is extracted from the catalog parser into `domain/addons/package_xml.dart` and reused.
- **Consequences**: no guessing when metadata is missing; `requirements.txt` is read from the
  fetched content (archive member or target directory) so consent still happens before placement;
  package.xml `<icon>` rendering is deferred (generic icon).
- **Refs**: `docs/impl/PLAN-B10-custom-addons.md`, FR-4.8/FR-4.11 (to add), D-037, B-10a

### D-087 — Dev directory installs use symlinks only
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: The developer workflow needs a live link to a working copy. D-023 allowed a copy
  fallback for local build AppImages, but copying an addon directory would silently go stale.
- **Decision**: `AddonInstaller.linkDirectory` creates `Mod/<id>` as a symlink to the selected
  directory (atomic `.part` + rename). If the filesystem/OS cannot create symlinks, the install
  fails with a clear error (no copy fallback). Removal detects a link and deletes only the link,
  never the target; the target is validated as an existing directory and the profile's own `Mod`
  path is rejected. Symlinked addons are live (no update action) and are not counted in profile
  sizes twice (`followLinks: false` walks).
- **Consequences**: dev edits are immediately visible to FreeCAD; Windows installs require
  symlink privileges and will be rejected otherwise; a broken link stays listed until removed
  (addon reconciler deferred).
- **Refs**: `docs/impl/PLAN-B10-custom-addons.md`, D-023, FR-4.12 (to add), B-10d

### D-088 — Custom addon update policy and bundle/manifest scope
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: Custom sources have no catalog timestamps; pretending they update like catalog
  addons would produce wrong badges, and bundles/manifests can only reinstall catalog ids.
- **Decision**: repository installs are updateable by re-fetching the stored URL + ref (backup,
  metadata refresh; pinned rows block); zip installs offer "Reinstall from file"; symlinked
  installs are live and have no update action. Custom rows are excluded from catalog update
  checks. Bundles keep searching the catalog only. Profile manifest export marks addon entries
  with a `source` field and import skips non-catalog entries, reporting the number not
  reinstalled (additive manifest schema).
- **Consequences**: no false update badges; custom addons are not portable via bundles/manifests
  (documented limitation); manifest import cannot silently substitute a catalog addon for a
  custom one with the same id.
- **Refs**: `docs/impl/PLAN-B10-custom-addons.md`, D-040, D-055, B-10b/B-10e

### D-089 — Addon enable/disable uses the ADDON_DISABLED marker as the source of truth
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: FreeCAD treats an addon as disabled when a file named `ADDON_DISABLED` exists in
  the addon root (Addon Manager convention). The launcher needs a per-profile toggle without
  duplicating state or migrating the schema.
- **Decision**: Profile → Addons rows get an enable/disable switch. Enabling/disabling
  creates/deletes `Mod/<id>/ADDON_DISABLED`; the controller derives the disabled set from the
  filesystem (`refreshDisabledState`, refreshed from the installed-addons stream and on tab
  mount) and keeps no DB column. `setAddonDisabled` validates the row and directory and returns
  a `Result`. The rule is uniform for catalog, repository, archive and dev-link addons; for a
  dev link the marker is written through the symlink into the working copy, because FreeCAD
  reads the resolved addon root.
- **Consequences**: no schema change; markers created or removed outside the launcher are picked
  up on refresh; disabled addons stay installed and remain updatable/pinnable; a dev-link working
  copy gets an untracked `ADDON_DISABLED` file while disabled.
- **Refs**: FR-4.13 (added), `docs/impl/TASKS.md` B-15a, `lib/state/addons_controller.dart`,
  `lib/ui/profiles/profile_detail_view.dart`

### D-090 — Launch log opens in the default text editor from the profile Overview
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: The profile detail Overview shows the last launch log path as read-only
  selectable text, so inspecting the log means locating the file manually.
- **Decision**: The log row keeps the path and size but becomes a clickable link (primary
  color, underline, tooltip) whose tap calls `FileActions.open(path)` — the existing
  platform action that delegates to the OS default application (`xdg-open` / `open` /
  `start`). Failures surface as a snackbar; no new platform code. The row label switches
  from the hardcoded `log` to the localized `jobsLog` key.
- **Consequences**: A missing file or a headless session shows the standard file-action
  failure snackbar; the jobs-dialog log lines are unchanged (only the Overview row is a
  link for now).
- **Refs**: `docs/impl/TASKS.md` R-13, `lib/ui/profiles/profile_detail_view.dart`,
  `lib/ui/profiles/profile_actions.dart`, `lib/platform/file_actions.dart`, R-08

### D-091 — Windows launcher distribution: portable zip, unsigned
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: OQ-1 (how Windows/macOS launcher binaries are distributed) was still open while
  M8-03/M8-06 work started. The owner confirmed the direction for the Windows v0.2 artifact in
  the planning session for `PLAN-M8-windows-release.md`.
- **Decision**: The Windows launcher ships as an **unsigned portable `.zip`**
  (`FreeCADLauncher-<ver>-windows-x86_64.zip`) containing the Flutter release bundle plus
  `7zr.exe`, `LICENSE`, `THIRD_PARTY_NOTICES.md` and the README, with a `.sha256` sidecar,
  built, smoke-tested and published by the existing release workflow on `v*` tags and manual
  dispatch. No installer and no code signing in v0.2; the SmartScreen warning is documented in
  the user guide and release notes. OQ-1 is resolved with option (b) for Windows (macOS stays
  M8-04).
- **Consequences**: CI needs a Windows packaging script and a release job; the artifact must
  keep `7zr.exe` beside `freecad_launcher.exe` (required by `SevenZipExtractor.bundled`);
  signing can be revisited later without changing the archive layout.
- **Refs**: `docs/spec/09-open-questions.md` OQ-1, `docs/spec/07-distribution.md` §2,
  `docs/impl/PLAN-M8-windows-release.md`, `docs/impl/TASKS.md` M8-03, D-018

### D-092 — `MacroPath` is written to user.cfg with forward slashes
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: `FreeCadPreferences.ensureMacroPath` appended `Platform.pathSeparator`, so the
  forced `MacroPath` ended with `\` on Windows while the Linux-verified behavior (D-053) and the
  cross-platform tests expect `/`. FreeCAD/Qt accept `/` on Windows, and a single canonical
  form keeps the config diffable and the tests OS-independent.
- **Decision**: Normalize backslashes to `/` and always terminate the forced `MacroPath` with a
  single `/` in `user.cfg`, independent of the host OS.
- **Consequences**: Config files read identically on all platforms; the Windows manual pass
  (M8-03) must confirm FreeCAD loads macros from the forced path on Windows.
- **Refs**: `docs/impl/PLAN-M8-windows-release.md`, D-053, `lib/platform/freecad_preferences.dart`,
  `docs/impl/TASKS.md` M8-06

### D-093 — Network diagnostics and catalog failure causes are surfaced
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: The Windows manual pass hit `CatalogUnavailableException` with no visible cause:
  the wrapping exceptions hid the underlying error and catalog failures were not logged, so a
  Windows Firewall/AV block could not be distinguished from a code or server issue. The Linux
  build worked, making it a machine-specific (environmental) failure.
- **Decision**: `DiagnosticsService` gains a `Network` check that probes `api.github.com`,
  `addons.freecad.org` and `blog.freecad.org/feed/atom/` (injected `NetworkProbe`, 5 s timeout;
  not-applicable when no probe is configured, so unit tests stay offline). `AppServices` wires
  it to the shared `http.Client`. The check appears in Settings → Diagnostics and debug bundles
  and reports the failing target with the exact error. Catalog-unavailable/exception classes
  append their `cause` to `toString()`, and catalog load failures are logged with stack traces.
  The user guide/README document the Windows Firewall/AV/SmartScreen workarounds and the
  direct-connection proxy limitation.
- **Consequences**: Windows support can distinguish blocks from bugs; diagnostics need outbound
  HTTPS on the three hosts; system proxy support remains a documented limitation (no proxy
  auto-detection in v0.2).
- **Refs**: `docs/impl/PLAN-M8-windows-release.md`, M8-03, `lib/platform/diagnostics.dart`,
  `lib/data/catalog/*.dart`, `lib/ui/settings/settings_view.dart`, `docs/user-guide.md`,
  `README.md`

### D-094 — Windows TLS trust uses the system stores plus an optional PEM bundle
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: The Windows manual pass failed every catalog with
  `CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate` (the Linux build works).
  On Windows, Dart's `SecurityContext.defaultContext` trusts Mozilla's roots only (confirmed in
  the `dart:io` docs), so corporate TLS-inspection/AV roots and private CAs installed in the
  Windows certificate store are ignored. `DownloadException` also hid the handshake error.
- **Decision**: after binding initialization and before the UI starts, `installAdditionalTrust`
  (a) loads the **machine-wide and current-user** Windows `ROOT` and `CA` stores via `crypt32`
  FFI (`CertOpenStore` with `CERT_SYSTEM_STORE_LOCAL_MACHINE` + `CERT_SYSTEM_STORE_CURRENT_USER`,
  `CertEnumCertificatesInStore`, deduplicated) as PEM into `SecurityContext.defaultContext`, and
  (b) additionally trusts `<data dir>/ca-bundle.pem` when present. Failures are non-fatal and
  logged (with certificate counts); no insecure bypass is added. `DownloadException.toString()`
  now includes its `cause`. The first iteration used `CertOpenSystemStoreW`, which only reads
  the current-user stores (24 certs on the VM) and did not fix the machine-store root; the
  Windows-only test requires >40 certificates so a user-only regression fails CI.
- **Consequences**: Windows machines with TLS inspection or private CAs work without
  configuration; startup performs a one-time store enumeration before the first HTTP request;
  macOS already uses the platform store, Linux keeps Mozilla roots; unusual setups can drop a
  PEM bundle at the data root; a Windows-only CI test validates store loading and FFI layout.
- **Refs**: `docs/impl/PLAN-M8-windows-release.md`, M8-03, D-093, `lib/platform/tls_trust.dart`,
  `lib/main.dart`, `lib/platform/downloader.dart`, `test/platform/tls_trust_test.dart`

### D-095 — Dynamic filesystem segments are portable ASCII
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: The Windows smoke pass failed every catalog install with
  `FileSystemException ... file exists` while extracting `FreeCAD_1.1.3-Windows-x86_64-py311.7z`.
  Catalog build IDs are `channel:versionLabel:platform:arch` (e.g.
  `stable:1.1.3:windows:x86_64`, `BuildCandidate.id`) and were joined directly as directory names
  (`AppPaths.buildDir`); `:` is illegal in Windows file names, so the staging directory
  `<builds>/stable:1.1.3:windows:x86_64.part` could not be created. The download succeeded
  because it uses the asset name. Linux accepted the colon names silently. The owner decided
  against a migration: "current data in the dev machine is not important, it can be removed".
- **Decision**: any dynamic value used as a filesystem segment goes through
  `safePathSegment` (`lib/core/path_segments.dart`): trim, replace every run of characters
  outside `[A-Za-z0-9._-]` with `_`, drop leading/trailing `-._`, fall back to `unnamed` when
  empty (also neutralizes `..`), and prefix a `_` on Windows reserved device names
  (`CON`, `NUL`, `COM1`…). Applied to build directories, launch-log names, macro file/icon
  names and addon backup directories. No migration of existing colon-named directories: Linux
  dev installs can be removed/reinstalled.
- **Consequences**: catalog builds install on Windows (`stable_1.1.3_windows_x86_64`); paths stay
  portable across OSes and filesystems; directory names differ from before D-095 (old Linux
  installs show as `missing` and are removed with their directories if still present); any future
  dynamic path segment must use the shared helper.
- **Refs**: `lib/core/path_segments.dart`, `lib/platform/paths.dart`, M8-03, R-14,
  `docs/impl/PLAN-M8-windows-release.md`

### D-096 — Windows process launches never send an empty environment block
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: The first Windows `.7z` install with the R-14 artifact got past the directory
  problem and failed inside 7zr extraction with `ProcessException: El parámetro no es correcto`
  (ERROR_INVALID_PARAMETER) at `process_win.cc:577` (CreateProcessW). `IoProcessLauncher` passed
  `environment: null` + `includeParentEnvironment: false` for a spec with an empty environment;
  Dart's Windows runtime then builds a **one-wchar** environment block (2 bytes), while
  CreateProcessW requires a four-byte terminator for an empty Unicode block, so the call is
  rejected. Linux accepts an empty environment, and pip/launch/probe specs always carry an env
  map, so 7zr was the only caller that hit it.
- **Decision**: in `IoProcessLauncher.start`, when `spec.environment` is empty **on Windows**,
  inherit the parent environment (`includeParentEnvironment: true`) instead of sending an empty
  block. Non-empty environments and all non-Windows behavior stay unchanged.
- **Consequences**: `.7z` extraction (7zr) works on Windows; an empty-environment spec inherits
  the parent environment on Windows only (workaround for a Dart runtime limitation — revisit if
  upstream fixes the block size); a Windows-only test executes a real process with an empty spec
  environment so a regression fails CI.
- **Refs**: `lib/platform/process.dart`, `test/platform/process_test.dart`, R-15, M8-03,
  `docs/impl/PLAN-M8-windows-release.md`

### D-097 — Release workflow renamed to `release.yml`; `v0.3.0` is the cross-platform release
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: `appimage-release.yml` grew a `windows` job (M8-03) and will gain macOS (M8-04),
  so its filename no longer matches what it builds. `v0.2.0` was tagged and published earlier
  today from the AppImage-only pipeline (tag at commit `b2a881c`); the owner chose to leave that
  release as-is and cut a new minor tag for the first release that carries both artifacts.
- **Decision**: rename the workflow file to `.github/workflows/release.yml` (workflow `name:
  Release` unchanged; inputs, jobs and the tag path untouched). Publish `v0.3.0` from the tag
  path with the Linux AppImage + Windows portable zip; `v0.2.0` remains an AppImage-only interim
  release. Version `0.3.0` in `pubspec.yaml`/`core/constants.dart`.
- **Consequences**: the README badge and other references point to `release.yml`; future macOS
  builds slot into the same workflow; the Windows smoke matrix (M8-03) was verified against the
  `v0.3.0` artifact line.
- **Refs**: `.github/workflows/release.yml`, `README.md`, M8-03, M8-04, D-068, D-091, R16

### D-098 — System file openers get a sanitized environment outside the AppImage
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: R-08 made `FileActions` inherit the parent environment so `xdg-open` receives
  DISPLAY/DBus. Inside the AppImage, `AppRun` exports `LD_LIBRARY_PATH` (bundled GTK/GLib) and
  `XDG_DATA_DIRS`; the spawned `xdg-open` then runs the system `gio`, which aborts with
  `symbol lookup error: undefined symbol: g_string_free_and_steal` because the AppImage's older
  GLib wins. Opening the logs folder therefore fell back to the browser instead of the file
  manager. Reproduced locally with `env LD_LIBRARY_PATH=<appdir>/usr/lib gio mime inode/directory`
  (clean env resolves `nemo.desktop`).
- **Decision**: `FileActions` spawns openers with a full copy of the parent environment minus the
  AppImage runtime variables (`APPIMAGE`, `APPDIR`, `OWD`, `ARGV0`, `LD_LIBRARY_PATH`,
  `LD_PRELOAD`) and with `XDG_DATA_DIRS` filtered of the AppDir prefix (fallback
  `/usr/local/share:/usr/share`); `includeParentEnvironment` is false because the copy is
  complete. Outside an AppImage the environment is unchanged.
- **Consequences**: open/reveal (Settings, profile folder, launch log, macro, addon) work from the
  AppImage; any system-tool spawn from the AppImage should reuse `openerEnvironment`; DISPLAY/
  Wayland/DBus stay inherited; unit tests cover the sanitizer.
- **Refs**: `lib/platform/file_actions.dart`, R-19, R-08, D-068, `packaging/appimage/AppRun`

### D-099 — Pre-D-095 build directories remain resolvable
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: D-095 changed managed build directories from `<channel>:<version>:<platform>:<arch>`
  to a sanitized ASCII name on every platform. POSIX installs made before D-095 (for example
  `builds/stable:1.1.3:linux:x86_64`) were still referenced by absolute paths in the database,
  but status/verify/remove resolved the new sanitized name, so upgraded installs were reported
  `missing` (launch blocked) and removal left the real directory orphaned. Found in the Linux
  regression audit of the Windows-support changes (R40).
- **Decision**: `AppPaths.existingBuildDir` and `buildDirCandidates` resolve the sanitized name
  first and fall back to the legacy unsanitized name; `BuildsController` (status, reconcile,
  verify, remove) and the Python resolvers use the resolved directory. New installs keep writing
  the sanitized name; `remove` deletes both candidates. No directory migration is performed.
- **Consequences**: upgrading keeps pre-D-095 builds usable; legacy directories are cleaned on
  removal or on a later reinstall; Windows is unaffected because colon names could never exist
  there; the fallback only ever reads a second path when the sanitized directory is absent.
- **Refs**: `lib/platform/paths.dart`, `lib/state/{builds,python,addons}_controller.dart`, D-095,
  R-20

### D-100 — Pre-0.4.0 releases withdrawn; the 0.4.x line continues
- **Date**: 2026-10-01
- **Status**: Accepted
- **Context**: Releases `v0.1.0`–`v0.3.0` were built during the Linux-first phase (`v0.1.0` and
  `v0.2.0` AppImage-only, `v0.3.0` the first cross-platform one) and `v0.3.0` carried the Linux
  regressions fixed in `v0.4.0`. The owner removed their GitHub Releases so the public Releases
  page only offers the current line; the git tags remain for history.
- **Decision**: `v0.4.0` is the only available release (published as a pre-release) and the
  `0.4.x` line is the supported release line going forward; future fixes ship as `0.4.x`
  releases, promoted to stable when the owner decides.
- **Consequences**: README and spec 07 describe `v0.4.0` as the current release; verification
  records for the withdrawn releases remain in `VERIFICATION.md`/STATUS as history; tags
  `v0.1.0`–`v0.3.0` still exist for reference.
- **Refs**: `README.md`, `docs/spec/07-distribution.md`, `docs/impl/VERIFICATION.md`, R41/R42,
  M8-03

### D-101 — Signals 7.1: defer build-phase writes and adopt implicit tracking
- **Date**: 2026-10-02
- **Status**: Accepted
- **Context**: Testing the `signals_flutter` 7.1.0 upgrade (B-16) crashed on the profile detail
  Backups tab: `ProfilesController.refreshConfigSnapshots` wrote `configSnapshots` from
  `didChangeDependencies` (build phase) and `preact_signals`' `endBatch` rethrew the Flutter
  "setState() or markNeedsBuild() called during build" error as a `SignalEffectException`.
  7.1 subscriptions call `markNeedsBuild()` synchronously, while 6.3.1's `ElementWatcher`
  deferred to `endOfFrame`. A throwaway test confirmed implicit
  `SignalWidget`/`SignalStatefulWidget` tracking fails identically in the same `TabBarView`
  structure, so the deprecated `.watch(context)` API (127 sites) is not the cause and migrating
  to implicit tracking would not fix the crash.
- **Decision**:
  - Signal writes must never run inside a frame (`build`/`didChangeDependencies`/layout). The
    Config/Backups tab mounts now defer `refreshConfigSnapshots` to a post-frame callback
    (R-23), with a widget regression test (Config -> Backups).
  - Implicit tracking is the target widget API for the signals 7.1 line: whole widgets use
    `SignalWidget`/`SignalStatefulWidget`, localized scopes use `SignalBuilder`, and
    `.watch(context)`/`Watch` are removed per `PLAN-signals-implicit-migration.md` (B-17),
    sequenced after the B-16 signals dependency commit is stable.
- **Consequences**: `.watch(context)` keeps working (deprecated) until B-17, so 127
  `deprecated_member_use` infos remain in the meantime; the no-write-during-build rule is
  enforced in review and any lazily invoked read must use `SignalBuilder` (only synchronous
  build reads are tracked). Worth reporting upstream: `SignalEffectException.toString()` hides
  the inner error, and the 7.1 elements lost the 6.x end-of-frame deferral.
- **Refs**: `docs/impl/PLAN-signals-implicit-migration.md`, `TASKS.md` B-16/B-17/R-23,
  `lib/ui/profiles/config_snapshots_view.dart`, `lib/state/profiles_controller.dart`,
  `test/ui/config_snapshots_view_test.dart`, signals_flutter 7.1.0 `src/widgets/*.dart`

### D-102 — `signals_lint` deferred from the B-16 signals group
- **Date**: 2026-10-02
- **Status**: Accepted
- **Context**: The signals 7.1 upgrade WIP added `signals_lint` 7.1.0 as an analyzer plugin to
  aid the `.watch()` migration. Its transitive constraint `analyzer <14` downgraded the project
  toolchain (analyzer 14.4.0 -> 13.3.0, `_fe_analyzer_shared` 108 -> 103, `source_gen` 4.3.0 ->
  4.2.4) and the SDK warns that legacy analyzer plugins are being removed. 7.1.0 is the latest
  release, no upgrade avoids the cap, and it produced no additional diagnostics here.
- **Decision**: Keep the P1 dependency commit signals-only (`signals_flutter` 7.1.0) with the
  analyzer chain at 14.4.0; defer `signals_lint` to B-17 and re-evaluate only if upstream drops
  the analyzer cap or migrates to the supported analyzer-plugin API.
- **Consequences**: `.watch()` sites are found through the normal `deprecated_member_use`
  diagnostics and `analysis_options.yaml` keeps no plugin block; B-17 decides whether to adopt a
  compatible linter at migration time.
- **Refs**: `TASKS.md` B-16/B-17, `docs/impl/PLAN-signals-implicit-migration.md`, `pubspec.lock`

### D-103 — CI and release toolchain moves to Flutter 3.47.6
- **Date**: 2026-10-02
- **Status**: Accepted (supersedes D-071's toolchain-pin clause only)
- **Context**: The B-16 drift upgrade (`drift_dev` 2.35.1) requires `analyzer >=13.1` and thus
  `meta ^1.18.3`, while the D-071 pin Flutter 3.41.4 ships `meta 1.17.0`; `flutter pub get`
  therefore failed in CI on both Linux and Windows before any test ran. The working-tree lock was
  resolved with Flutter 3.47.6 (stable, 2026-09-30, `meta 1.19.0`), the SDK the 615-test suite
  and the live pass already run on locally.
- **Decision**: Pin CI (`ci.yml`) and both release jobs (`release.yml`) to Flutter **3.47.6**
  (stable) and update the user-guide/plan references; the Dart SDK constraint stays `^3.11.0`.
  D-071's other clauses (placeholder policy, icon sizes) remain in force.
- **Consequences**: Release artifacts are built with 3.47.6 from the next run on, so B-16
  Phase 3 must smoke the AppImage/Windows jobs on the new SDK before a release; drift 2.35.1
  resolves on CI; dev machines must match 3.47.6.
- **Refs**: `.github/workflows/{ci,release}.yml`, `pubspec.lock`, `TASKS.md` B-16,
  `docs/impl/PLAN-dependency-upgrades.md`, D-071

### D-104 — Home shows a row of recent profiles instead of a single last-used card
- **Date**: 2026-10-02
- **Status**: Accepted (supersedes D-067's single last-used-card clause)
- **Context**: D-067/M6-12 gave Home one “Last used profile” card with a Launch button. The owner
  wants quicker access — one click to launch any of the recently used profiles.
- **Decision**: Home's top section becomes a “Recent profiles” row of up to five compact cards:
  profiles with a `lastUsedAt`, newest launch first, build status `installed` only (missing/
  broken builds are hidden). The whole card launches through the existing `launchProfile` guards
  (health check, macOS quarantine consent, failure snackbar); a chevron opens the profile detail.
  The row scrolls horizontally with fixed ~220 px cards and is hidden when no profile qualifies.
  The old last-used card and its empty branch are removed.
- **Consequences**: `ProfilesController` gains a derived `recentProfiles` computed (no schema
  change); `HomeView` gains an optional `onOpenProfile` callback wired by `AppShell` to
  `ProfilesViewState.openProfile`; spec 03 §2.1 and the Home widget tests are updated. A profile
  whose build later goes missing disappears from Home but stays reachable in Profiles.
- **Refs**: `TASKS.md` B-18, `docs/impl/PLAN-B18-home-recent-profiles.md`, `docs/spec/03-ux.md`
  §2.1, D-067, `lib/ui/home/home_view.dart`

### D-105 — Cache deletion guards: Build downloads and Clean up now confirm first
- **Date**: 2026-10-02
- **Status**: Accepted
- **Context**: Settings ▸ Cache cleared any category with a single click, although spec 03 §4
  already required confirmation for cache clears (implementation gap since D-063). Build
  downloads can be multiple GB, so an accidental clear forces a full re-download.
- **Decision**: The **Build downloads** Clear and **Clean up now** actions show a confirmation
  dialog naming the size (or the retention window), stating that installed versions/profiles are
  not affected and that cleared archives will be downloaded again when needed. Other categories
  (GitHub releases, addon/macro catalog, news) are regenerable and stay one click. Clean up now
  with retention **Forever** shows an informational dialog with only Close.
- **Consequences**: spec 03 §2.6/§4 wording aligned; six new l10n strings; three new widget
  tests (confirm clears, cancel keeps, prune respects the retention window). No schema,
  controller or service change.
- **Refs**: `TASKS.md` R-24, `docs/spec/03-ux.md`, `lib/ui/settings/settings_view.dart`, D-063

### D-106 — Visual identity refresh: brand palette, semantic tones and Home hero (R-25)
- **Date**: 2026-10-03
- **Status**: Accepted
- **Context**: The v2 UI ran on stock Material 3 seeded from `Colors.blueGrey`, with only the
  D-059 input theme customized, so every surface rendered flat gray. The product owner asked for
  a more vivid but still professional look; the direction was confirmed in four questions
  (2026-10-03): launcher brand palette, medium vividness, keep Roboto with a tuned scale, slim
  Home hero. The icon master (D-070) already documents the brand palette: Tufts Blue `#418FDE`,
  Light Red `#FF585D`, Dark Red `#CB333B`, Off Black `#212529`.
- **Decision**:
  - `ColorScheme.fromSeed(seedColor: #418FDE, dynamicSchemeVariant: fidelity)` for light and dark;
    the reds stay semantic accents (running/alert/destructive) rather than scheme roles.
  - New `lib/ui/theme/app_colors.dart`: brand constants plus the `AppStatusColors`
    `ThemeExtension` (success/warning/info/running container pairs, light and dark values).
  - `buildAppTheme` moves to `lib/ui/theme/app_theme.dart`; component themes are defined for
    cards, navigation rail, chips, list tiles, dialogs, snackbars, tabs, buttons, segmented
    buttons, progress indicators, tooltips and scrollbars, with a tuned text scale (600-weight
    titles, muted `bodySmall`).
  - D-059 form style is unchanged: dense outlined inputs, 4 px corners, label-left `FormRow`s.
  - `CompactBadge` gains semantic tones (`neutral/info/success/warning/danger/running`); raw
    `Colors.green`/`Colors.orange` are replaced by `AppStatusColors` everywhere.
  - Home gets a slim rounded gradient hero (brand mark, app title, profile/version/addon summary
    or tagline, New profile + Check updates) above the existing sections; the B-18 counters stay
    removed.
- **Consequences**: The visual tone shifts from gray to brand blue; new UI code must use
  `AppStatusColors`/badge tones instead of raw colors; `app_theme_test` locks the brand seed,
  status extension and shape policy; README screenshots are recaptured. No schema/controller
  change; D-059's input regression test is untouched.
- **Refs**: `TASKS.md` R-25, `docs/spec/03-ux.md` §1/§2.1, `lib/ui/theme/`, D-059, D-070, D-104

### D-107 — Profile-context catalog pickers for addons and macros (R-27)
- **Date**: 2026-10-03
- **Status**: Accepted
- **Context**: Spec 03 §2.3 requires the Profile ▸ Addons tab to add addons and the Profile ▸
  Macros tab to install from the catalog, but both actions were missing (the catalog could only
  push into a profile through its own target-profile picker). Collections already had a
  searchable `AddAddonDialog`; the owner asked for the same affordance inside the profile
  context. Single-select, primary-branch, no-update-action and header+empty-state-entry choices
  were confirmed (2026-10-03).
- **Decision**:
  - Collections' addon dialog becomes the shared `AddonPickerDialog` (text + `#tag` search,
    loading/error states, already-present rows show the Installed badge and no action); addon
    requirements consent is preserved through `installAddonIntoProfile`, which the Addons catalog
    tab now uses too.
  - Profile ▸ Addons: header "Add addon" plus an empty-state action; picks install the addon's
    primary branch into that profile.
  - Profile ▸ Macros (and Macros ▸ Installed): a matching `MacroPickerDialog` (search over
    name/comment/description/author, installed-in-profile rows disabled) installs through
    `MacrosController.install(name, profileId)`.
  - One item per dialog (matching Collections); no update action in the pickers (updates stay in
    the profile list and batch flows).
- **Consequences**: The pickers require the catalog to be loaded; both profile tabs already
  start/ensure it (`addons.start()/ensureCachedCatalog()`, `macros.start()`). No schema or
  controller changes; installs reuse the existing jobs and snackbars. Live installs are not
  exercised against the owner's profiles; UI wiring is covered by widget tests with spy
  controllers and the install side effects by the existing controller tests.
- **Refs**: `TASKS.md` R-27, `docs/spec/03-ux.md` §2.3, `lib/ui/addons/addon_picker_dialog.dart`,
  `lib/ui/addons/addon_install_flow.dart`, `lib/ui/macros/macro_picker_dialog.dart`, D-046,
  D-104

### D-108 — package.xml `<depend>` parsing and resolution semantics (B-19)
- **Date**: 2026-10-04
- **Status**: Accepted
- **Context**: 79 of 191 real catalog branch entries declare `<depend>` tags and 73 of them have
  no `requirements.txt`; the launcher ignored them, installing addons whose Python packages or
  companion addons were missing (e.g. `Ondsel-Lens` → `pyjwt`, `requests`, `tzlocal`). The
  AddonManager parses the tag with `type` (`automatic|addon|internal|python`), `optional` and
  version attributes (`version_lt/lte/eq/gte/gt`), then resolves `automatic` entries against the
  known addons first, then internal workbenches, then treats them as Python packages.
- **Decision**:
  - `parsePackageXml` parses every `<depend>` found anywhere in the document (including nested
    `<content>` items, matching the AddonManager recursion) into `AddonDependency { name, type,
    optional, versionLt/Lte/Eq/Gte/Gt }`; unknown `type` values fall back to `automatic`;
    `optional` is case-insensitive.
  - Version attributes are parsed and retained but **ignored** for matching and installation
    (AddonManager parity): Python packages are passed to pip by bare name and addons match by
    name only.
  - Resolution (pure `resolveAddonDependencies`): a `<depend>` matches a catalog addon by exact
    `id` or package display name (case-insensitive fallback), then an internal workbench
    (`name`/`nameWB`/`nameWorkbench` against the 20 standard names), otherwise it is a Python
    requirement — including explicitly missing `addon` entries (AddonManager parity).
  - The dependency closure recurses through dependent addons even when they are already
    installed (their missing transitive dependencies must still install) and filters the install
    list by the profile's installed addons; a visited set breaks cycles.
  - `requirements.txt` entries are merged first (their specifiers win), `<depend>` Python entries
    fill gaps; entries are deduped by PEP 503 name with required beating optional, and the first
    declaring addon is recorded for provenance.
  - The plan exposes `orderedAddons` (post-order DFS, deepest dependency first).
- **Consequences**: The resolver is pure and catalog-driven; no schema change. Internal
  workbenches are informational (standard builds provide them; the launcher does not probe the
  build). Version constraints are a future extension.
- **Refs**: `docs/impl/PLAN-B19-addon-dependencies.md`, `TASKS.md` B-19a,
  `lib/domain/addons/package_xml.dart`, `lib/domain/addons/addon_dependencies.dart`,
  `addon_index_spec.md`, <https://wiki.freecad.org/Package_Metadata>

### D-109 — Unified dependency consent dialog (B-19)
- **Date**: 2026-10-04
- **Status**: Accepted
- **Context**: The existing consent dialog only covered `requirements.txt` (Install packages /
  Addon only / Cancel). Dependencies introduce dependent addons and optional entries, and the
  owner chose one unified dialog with checkboxes for optional addons and Python packages.
- **Decision**:
  - `showAddonDependenciesDialog` replaces `showRequirementsConsentDialog`: sections for required
    addons, optional addons (unchecked checkboxes), required Python, optional Python (unchecked
    checkboxes) and internal workbenches (“provided by FreeCAD”); invalid `requirements.txt`
    lines keep the red monospace style. Actions: **Install dependencies** /
    **Addon only** / **Cancel**.
  - The dialog appears when there is anything installable or invalid, including when only
    optional entries exist; internal-only plans do not prompt.
  - Consent is per addon install: catalog installs ask before download using the embedded
    `package_xml` when available; custom installs ask after staging from the real `package.xml`.
    If staging reveals required entries the pre-download prompt could not know (catalog entry
    without metadata), the same dialog is shown once more through the install handler. Optional
    entries discovered late are skipped (they were not selected).
  - A selection object (`AddonDependencySelection`) carries the decision into the controller;
    optional selections are per addon install and never auto-applied on updates.
- **Consequences**: The addon detail page lists declared dependencies (with `*` for optional)
  instead of the old yes/no requirements row; bundle apply and manifest import reuse the same
  selection type; the old `requirements_dialog.dart` is removed and l10n keys are renamed.
- **Refs**: `docs/impl/PLAN-B19-addon-dependencies.md`, `TASKS.md` B-19d/B-19e,
  `lib/ui/addons/addon_dependencies_dialog.dart`, D-041, D-046, D-055

### D-110 — Already-available Python detection via a batched interpreter probe (B-19)
- **Date**: 2026-10-04
- **Status**: Accepted
- **Context**: `<depend>` Python entries include stdlib names (`math`, `inspect`, `getpass`,
  `tkinter`) and packages already bundled with FreeCAD (e.g. `requests`); pip-installing them
  fails (poisoning a batch) or shadows the bundled version. The AddonManager checks importability
  inside FreeCAD; the launcher runs outside and must reproduce that check.
- **Decision**:
  - `PythonPackageProbe.availablePackages` runs the build's interpreter once with all candidate
    names as argv, checks `importlib.util.find_spec(name)` or `importlib.metadata.distribution`
    per name and returns PEP 503-normalized results; `PYTHONPATH` points at the profile
    `AdditionalPythonPackages/pyXY` so profile-local packages count; stdin is closed and the
    environment is sanitized.
  - Candidates already available are removed from the dialog and from the pip install set.
  - Probe failure returns `null` and the controller falls back to recorded `python_packages`
    rows plus a generated `sys.stdlib_module_names` snapshot so stdlib names are never handed to
    pip; the probe result is memoized per (build, profile) for the session.
- **Consequences**: The first dependency install may pay one interpreter start (cached AppImage
  extraction is reused); no probe runs when there are no Python candidates. The stdlib snapshot
  is regenerable data (`lib/domain/python/python_stdlib_names.dart`).
- **Refs**: `docs/impl/PLAN-B19-addon-dependencies.md`, `TASKS.md` B-19b,
  `lib/platform/python_package_probe.dart`, D-006, D-041

### D-111 — Dependency execution order, provenance and lenient failures (B-19)
- **Date**: 2026-10-04
- **Status**: Accepted
- **Context**: Dependent addons and Python packages must install before/around the main addon
  without deadlocking the single-install job queue, without losing provenance, and without
  turning a failed optional dependency into a failed addon install (D-041/D-008).
- **Decision**:
  - Execution order per addon install: required Python pip → dependent addons in
    `orderedAddons` order → main addon placement. Dependencies run inside the same job through
    internal recursion (never through the public `install`), so the queue cannot deadlock;
    progress is reported as `detail` strings.
  - Catalog installs switch from the atomic `AddonInstaller.install` to
    `downloadArchive` + `prepareFromArchive` so the staged `package.xml` can be read before the
    commit; `commitPrepared` keeps the atomic replace/rollback semantics.
  - Each installed Python package is recorded in `python_packages` with
    `source = addon:<declaringAddonId>`; dependent addons are ordinary `installed_addons` rows
    with `source = catalog`.
  - Failures are lenient: a required Python failure lands in `requirementsErrors[mainAddonId]`
    and a dependent addon failure in `installErrors[dependencyId]`; the main addon still
    installs. A failed pip batch is retried package-by-package to isolate bad names.
  - Updates resolve the new branch's dependencies and install only what is missing; already
    installed dependencies are never auto-updated (notify-only updates stay, D-008). A one-shot
    consent is shown when new installable dependencies appear.
  - Removing an addon that other installed addons depend on shows a “Required by: …” warning
    but is still allowed; `dependentsOf` derives this from catalog metadata at runtime.
  - No schema change (schema stays v6); `installed_addons.hasRequirements` is set when any
    Python dependency (requirements.txt or `<depend>`) is declared.
- **Consequences**: Dependency installs are visible inside the parent job; the Python tab shows
  packages attributed to the addon that declared them; reverse dependencies are advisory only.
  Pinning remains per addon row and is unaffected.
- **Refs**: `docs/impl/PLAN-B19-addon-dependencies.md`, `TASKS.md` B-19c..B-19f, D-008, D-039,
  D-041, D-043, D-057

### D-112 — AppImage Python execution via headless macros (no extraction)
- **Date**: 2026-10-04
- **Status**: Accepted
- **Context**: Catalog AppImages are single-file SquashFS bundles; the bundled Python only
  exists while the image is mounted, so pip (and the availability probe) required a persistent
  `--appimage-extract` copy under `builds/<id>/extracted/` — several GB per AppImage and a slow
  first run. The launcher already runs headless macros inside the very same binary for Python
  detection (D-022): `<appimage> -c -M <dir> <macro>`, and FreeCAD's AddonManager itself runs
  pip inside FreeCAD. Verified manually on the real 1.1.3 AppImage: `pip` 25.3 is importable in
  the mounted environment, `pip._internal.cli.main.main(['install','--target',…])` installs
  into the profile target, and an import-availability check completes in ~1 s.
- **Decision**:
  - New `FreeCadMacroRunner` runs a generated `.FCMacro` headless with the same isolated
    environment used by the Python probe (`FREECAD_USER_HOME`/`FREECAD_USER_TEMP`, sanitized
    Python env, closed stdin) and parses a tagged JSON payload from stdout. `runAppImage`
    retries once with `APPIMAGE_EXTRACT_AND_RUN=1` when the first run produced no payload (no
    FUSE).
  - `PipRunner.install` accepts either an interpreter path (archive/dmg/custom) or an AppImage
    path; the AppImage path writes the pip log and prints the tagged result from inside the
    macro, keeping the global pip queue and log naming unchanged.
  - `PythonPackageProbe.availablePackagesInFreeCad` runs the same `find_spec` +
    `importlib.metadata` check inside the AppImage with the profile target appended to
    `sys.path` (matching FreeCAD's runtime order).
  - `PythonExecutionResolver` picks the strategy: AppImage + FUSE → macro execution (never
    extract); AppImage without FUSE → one-time persistent extraction as before (chosen over
    per-run temp extraction); other kinds → bundled interpreter.
  - `AddonsController` and `PythonController` branch on the resolved execution; the dependency
    consent preview deliberately skips the macro probe to stay instant and lists all declared
    candidates, while the install-time probe filters packages already available (bundled,
    stdlib, profile target).
  - Macro runs use a persistent `cache/pip` `PIP_CACHE_DIR` so wheels are not re-downloaded
    with the isolated home.
- **Consequences**: AppImage profiles no longer create or need `builds/<id>/extracted/` on
  FUSE-capable systems; disk use drops by GBs and first pip install no longer extracts. FUSE-
  less systems keep the old one-time extraction. Macro execution adds one short FreeCAD start
  (~1 s) per probe/pip batch. The `pip` internal API is used with a `runpy.run_module('pip')`
  fallback.
- **Refs**: `docs/impl/PLAN-B19-addon-dependencies.md`, `TASKS.md` B-20,
  `lib/platform/freecad_macro_runner.dart`, `lib/platform/pip_runner.dart`,
  `lib/platform/python_package_probe.dart`, `lib/platform/python_execution.dart`, D-006,
  D-022, D-041, D-110

### D-113 — Archive symlinks are skipped with a warning, never created (R-30)
- **Date**: 2026-10-04
- **Status**: Accepted
- **Context**: Installing the catalog **History Workbench** failed with
  `ArchiveExtractionException: Symlink entries are not allowed` because its GitHub archive carries
  three git symlinks (two relative, one absolute pointing at the author's machine:
  `/home/flyer/Repositories/...`). The D-039 extractor rejected every symlink outright, so any
  addon repo using links for docs/assets was uninstallable. Blindly creating links is unsafe:
  a link plus a later entry can write outside the destination (zip-slip via symlink), absolute
  links can expose host paths, and resolving/copying link targets during extraction would read
  arbitrary host files.
- **Decision**:
  - `SafeArchiveExtractor` **skips** symlink entries (both zip and tar) instead of throwing; it
    never creates a link and never reads the link target from the host.
  - Skipped entries are reported through an optional `ArchiveWarningCallback`
    (`SkippedArchiveEntry { path, symlinkTarget }`) and surfaced per addon:
    `AddonsController.installWarnings` (path → target messages) plus `appLogger.warn` and a job
    detail line; `AddonInstaller.prepareFromArchive` returns them in `PreparedAddonInstall`.
  - Catalog installs, custom repo/archive installs and FreeCAD build archive installs all skip
    and log; addon installs additionally show a “Some files were skipped” dialog listing every
    skipped link with its target.
  - Path-name validation still rejects absolute/escaping entry names before the skip decision.
- **Consequences**: History Workbench installs; only its docs-site links are missing (the
  workbench content itself is regular files). Addons that genuinely rely on symlinked content
  install incomplete, but the user is told exactly which entries were skipped. Security posture
  is unchanged from D-039: no link is ever materialized. The former unit test that expected a
  throw now expects a skip + report.
- **Refs**: `TASKS.md` R-30, `docs/spec/06-integrations.md` §2, `lib/platform/archive_extract.dart`,
  `lib/platform/addon_installer.dart`, `lib/state/addons_controller.dart`,
  `lib/ui/addons/addon_install_warnings_dialog.dart`, D-039

### D-114 — The Windows portable zip bundles the MSVC C++ runtime app-local (R-31)
- **Date**: 2026-10-05
- **Status**: Accepted
- **Context**: Windows users reported that the launcher does not start on machines without the
  system-wide Microsoft Visual C++ Redistributable ("VCRUNTIME140.dll was not found" /
  "MSVCP140.dll was not found"). The Flutter Windows release bundle (`freecad_launcher.exe`,
  the plugin DLLs and the prebuilt `flutter_windows.dll`) links the C++ runtime dynamically, so a
  portable zip should carry it instead of requiring a separate system prerequisite.
- **Decision**:
  - `packaging/windows/build_portable.ps1` locates the Visual Studio x64 CRT redistributable
    folder on the build machine (`vswhere` →
    `VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT`, `$env:VCToolsRedistDir` as fallback) and copies
    every `*.dll` from it next to `freecad_launcher.exe` (documented app-local deployment),
    unmodified.
  - The script fails unless `vcruntime140.dll`, `vcruntime140_1.dll` and `msvcp140.dll` are
    present in the staged bundle and in the written zip.
  - The DLLs are not committed to the repository (fetched from the toolchain at package time); no
    `VC_redist*.exe` and no UCRT (in-box since Windows 10, the Flutter platform floor).
  - `tool/generate_third_party_notices.dart` gains a "Microsoft Visual C++ runtime" section:
    Microsoft copyright, redistributed unmodified as Distributable Code by app-local deployment
    under the Microsoft Visual Studio license terms, with the Microsoft documentation link.
  - Static CRT linking (`/MT`) was considered and rejected: the prebuilt `flutter_windows.dll`
    still imports the dynamic runtime DLLs.
- **Consequences**: The zip grows by ~1.6 MB uncompressed (~0.7 MB compressed) and starts on
  machines without the redistributable. DLL versions follow the runner's Visual Studio install, so
  zips are not bit-reproducible across runner image upgrades (already true for the Flutter engine).
  FreeCAD builds managed by the launcher are unaffected (their conda bundles ship their own
  MSVC/UCRT files; spec 06 §1.4).
- **Refs**: `TASKS.md` R-31, `docs/spec/07-distribution.md` §2, `docs/spec/06-integrations.md`
  §1.4, `docs/user-guide.md`, `packaging/windows/build_portable.ps1`, D-091, D-018

### D-115 — The asset-name Python hint is version metadata, never an interpreter path (R-32)
- **Date**: 2026-10-05
- **Status**: Accepted
- **Context**: Installing an addon with `<depend>` Python packages on Windows opened FreeCAD's
  “Initialization of FreeCAD failed — unrecognised option '-m'” dialog. Catalog assets encode the
  bundled Python version in the name (`FreeCAD_1.1.3-Windows-x86_64-py311.7z` →
  `pythonVersionHint: '3.11'`). `ProcessPythonProbe.detect` short-circuited on that hint and
  returned `BundledPython(executablePath: <FreeCAD.exe>, version: hint)`; the installer persisted
  it as `builds.pythonPath`, so `PipRunner` later executed `FreeCAD.exe -m pip install …`.
  FreeCAD's CLI parser does not know `-m` and shows a GUI error dialog (the interpreter was never
  looked for). The same shortcut could store the AppImage path as the interpreter on FUSE-less
  Linux. Spec 06 §4.1 already defines the real interpreters (Windows `<build>\bin\python.exe`,
  macOS `Contents/Resources/bin/python`, AppImage extraction fallback) and §4.2 states the version
  is reported by the interpreter, never guessed.
- **Decision**:
  - `ProcessPythonProbe.detect` always attempts real interpreter discovery/probing; the
    asset-name hint only fills `PythonDetection.version` when no interpreter can be probed (and
    never populates `pythonPath`). `python_probe` also sanitizes `PYTHONPATH`/`PYTHONHOME`/
    `VIRTUAL_ENV`/`PYTHONUSERBASE` for the interpreter probe (case-insensitive, Windows).
  - `PythonEnvResolver.resolve` ignores a stored `builds.pythonPath` that equals the build
    executable or names a FreeCAD launcher (`FreeCAD`/`FreeCADCmd`/`AppRun`), falling back to
    discovery, so pre-fix build rows are healed without a migration.
  - `PipRunner` refuses (`ArgumentError`) to run a FreeCAD executable as Python. FreeCAD binaries
    are only ever spawned with `-c` (console) via `FreeCadMacroRunner`/the headless probe; no
    Python arguments are ever passed to them.
- **Consequences**: Windows/macOS catalog builds store the probed bundled interpreter path; the
  Python version may still come from the asset-name hint when the interpreter cannot be probed, and
  profiles remain creatable. Older rows with `pythonPath == FreeCAD.exe` work again: the resolver
  finds `bin\python.exe`. If a build genuinely ships no Python, dependency installs fail with a
  clear “no execution target” error instead of a FreeCAD error dialog.
- **Refs**: `TASKS.md` R-32, `docs/spec/06-integrations.md` §4.1/§4.2, `lib/platform/python_probe.dart`,
  `lib/platform/python_env.dart`, `lib/platform/pip_runner.dart`, B-19, D-108..D-112

### D-116 — Platform metadata copyright alignment and the Windows data root (M8-07)
- **Date**: 2026-10-05
- **Status**: Accepted (the rename migration was replaced by D-117 after it invalidated stored
  absolute paths; the metadata alignment and the pinned data root stand)
- **Context**: The owner's copyright holder is `Frank Martínez <mnesarco at gmail>` (D-074/D-079),
  but the Windows `Runner.rc` and macOS `AppInfo.xcconfig` still carried the Flutter-template
  “FreeCAD Launcher contributors” values. On Windows the exe VERSIONINFO is load-bearing:
  `path_provider_windows` derives the app-support path from `CompanyName\ProductName`, so the data
  root was `%APPDATA%\FreeCAD Launcher contributors\FreeCAD Launcher` — not the
  `org.freecad.ext.launcher` location D-016 records — and changing `CompanyName` would orphan
  existing data (`config.db`, builds, profiles, caches). `LegalCopyright` itself has no effect on
  the path.
- **Decision**:
  - `LegalCopyright` (Windows) and `PRODUCT_COPYRIGHT` (macOS) become exactly
    `Copyright 2026 Frank Martínez <mnesarco at gmail>`; Windows `CompanyName` becomes
    `Frank Martínez`.
  - The Windows data root is pinned to `%APPDATA%\org.freecad.ext.launcher` (application id,
    D-016), computed from `APPDATA` instead of the executable's version resource; if `APPDATA` is
    missing, `getApplicationSupportDirectory()` is the fallback. Linux/macOS keep
    `getApplicationSupportDirectory()`.
  - On first start the legacy `%APPDATA%\FreeCAD Launcher contributors\FreeCAD Launcher` directory
    is renamed to the pinned root (same volume, atomic). If the pinned root already holds data it
    wins and the legacy directory is left untouched. If the move fails (locked files, antivirus),
    the legacy root stays in use for the session, a warning is logged after the logger is
    configured, and the move is retried on the next start — never a partial copy, never deletion.
  - Windows CI (`ci.yml` and `release.yml`) asserts the built exe's
    `LegalCopyright`/`CompanyName`/`ProductName`/`ProductVersion` via
    `packaging/windows/check_version_info.ps1`.
- **Consequences**: exe metadata matches the recorded holder and the data location no longer
  depends on mutable version metadata, so future `CompanyName`/`ProductName` edits cannot orphan
  data; D-016 is now accurate on Windows. Upgraded installs keep the legacy path when the move
  could not complete (Settings shows the actual location); running an old ≤0.4.7 build after a
  successful migration recreates an empty legacy directory, and the new build prefers the
  non-empty pinned root. A live Windows upgrade retest remains pending (no machine, B-16 smoke on
  hold).
- **Refs**: `TASKS.md` M8-07, D-016, D-074, D-079, `lib/platform/paths.dart`, `lib/main.dart`,
  `windows/runner/Runner.rc`, `macos/Runner/Configs/AppInfo.xcconfig`,
  `packaging/windows/check_version_info.ps1`, `docs/spec/05-data-model.md` §3, `README.md`,
  `docs/user-guide.md`

### D-117 — The data root is never renamed; stale stored paths are repaired (M8-08)
- **Date**: 2026-10-05
- **Status**: Accepted
- **Context**: D-116's one-time rename of `%APPDATA%\FreeCAD Launcher contributors\FreeCAD Launcher`
  to the pinned `%APPDATA%\org.freecad.ext.launcher` left every installed build marked **Broken**
  on Windows (owner report with the 0.4.8 test build). The database is an index over the
  filesystem and stores absolute paths (`builds.localPath`, `builds.pythonPath`,
  `catalog_cache.payloadPath`, `installed_addons.sourcePath`, `python_packages.targetDir`), so
  moving the tree invalidates all of them; FreeCAD's own `user.cfg` inside profiles can also carry
  absolute macro/tool paths. The fallback design protected against a failed rename but not against
  a successful one.
- **Decision**:
  - The Windows data root is never moved. `AppPaths.resolve` uses the pinned
    `%APPDATA%\org.freecad.ext.launcher` when it already contains `config.db`, otherwise the
    pre-M8-07 `%APPDATA%\FreeCAD Launcher contributors\FreeCAD Launcher` when it contains
    `config.db`, otherwise the pinned root (fresh installs).
  - `AppPaths.legacyRoot` exposes the old root when the pinned root is active.
    `DataRootRepair.rewritePathPrefix` rewrites stored paths under it into the active root, but
    only when the mapped target exists on disk. It runs once per start in
    `AppServices.bootstrap` (idempotent, a no-op when nothing matches) and the repaired count is
    logged after the logger is configured.
  - Repairs cover `builds.localPath`, `builds.pythonPath`, `catalog_cache.payloadPath`,
    `installed_addons.sourcePath` and `python_packages.targetDir`. Nothing is deleted, renamed or
    copied.
- **Consequences**: installs whose data was moved by an early 0.4.8 build recover on the next
  start; legacy installs keep their directory and every stored path stays valid; fresh installs
  use the pinned app-id path, so exe metadata changes remain harmless. Absolute paths inside
  FreeCAD's own `user.cfg` are not repaired — profiles moved by 0.4.8 can still show stale
  macro/tool paths inside FreeCAD.
- **Refs**: `TASKS.md` M8-08, D-016, D-116, `lib/platform/paths.dart`,
  `lib/data/data_root_repair.dart`, `lib/state/app_services.dart`, `lib/main.dart`, `README.md`,
  `docs/user-guide.md`, `docs/spec/05-data-model.md` §3

### D-118 — Interpreter pip runs through a launcher bootstrap that registers DLL directories and reports ssl (R-34)
- **Date**: 2026-10-05
- **Status**: Accepted
- **Context**: Installing Ondsel-Lens (declares `pyjwt`, `requests`, `tzlocal`) into a profile backed by the
  FreeCAD 1.1 **weekly** build on Windows failed while the same install on a stable build worked. The pip log
  showed `WARNING: Disabling truststore since ssl support is missing` and
  `The 'ssl' module is unavailable but required for HTTPS URLs`, so pip could not reach PyPI over HTTPS. The
  weekly archive is not broken: it ships Python 3.13 with `bin\DLLs\_ssl.pyd` and
  `bin\libssl-3-x64.dll`/`bin\libcrypto-3-x64.dll` (the imported OpenSSL symbols all resolve), and
  `bin\python.exe -c "import _ssl"` succeeds when run by hand. The failure was specific to the process the
  launcher spawned. `python.exe -m pip` also gave no way to register DLL directories, and the underlying
  `ImportError` was swallowed; `_installPythonRequirements` treats dependency failures as non-fatal
  (D-111) and only the catalog detail page displayed `requirementsErrors`, so the addon looked installed
  with the packages missing.
- **Decision**:
  - `PipRunner` interpreter installs run a generated bootstrap (`run_pip.py` in a temp directory) instead of
    `-m pip`: it writes an interpreter/target/packages header into the pip log, registers the interpreter's
    directory and its `DLLs` subdirectory with `os.add_dll_directory()` (keeping the returned handles alive)
    and prepends them to `PATH` (Windows only; the `hasattr` guard is a no-op elsewhere), prints the `ssl`
    availability with the full traceback when the import fails, then executes
    `runpy.run_module("pip", run_name="__main__", alter_sys=True)` with the same
    `install --upgrade --target … --disable-pip-version-check --no-warn-script-location` arguments.
  - `requirementErrorKey(profileId, addonId)` scopes `requirementsErrors`/`requirementsInstalling` to one
    profile+addon pair (previously the raw addon id, so a failure in one profile leaked into the others).
  - Dependency failures are surfaced on the profile Addons tab row and in the install snackbar (the catalog
    detail already showed them); `python_packages` rows are still recorded only for successful pip runs.
  - The Linux AppImage path (D-112 macro) and the `PYTHONPATH`/`PYTHONHOME` sanitization are unchanged; the
    bootstrap is used by every interpreter install (Linux/macOS/Windows).
- **Consequences**: HTTPS failures in pip are no longer silent — the pip log now names the interpreter and
  carries the `ssl` traceback. On Windows the DLL directories are registered the same way FreeCAD's own
  startup does, which fixes bundles whose `libssl`/`libcrypto` are not discoverable from the spawned
  `python.exe`. Minor behavior change: pip runs via `runpy` from a temp script (equivalent to `-m pip`) and
  `sys.path[0]` is the temp script's directory instead of the process cwd.
- **Refs**: `TASKS.md` R-34, `docs/spec/06-integrations.md` §4.2, `lib/platform/pip_runner.dart`,
  `lib/domain/addons/addon_dependencies.dart`, `lib/state/addons_controller.dart`,
  `lib/ui/addons/addon_install_flow.dart`, `lib/ui/addons/addons_view.dart`,
  `lib/ui/profiles/profile_detail_view.dart`, `test/platform/pip_runner_test.dart`, D-111, D-115
