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
- **Status**: Accepted
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
- **Status**: Accepted
- **Context**: Multi-session rewrite needs a clean baseline and reversible prototype.
- **Decision**: Tag `prototype-final` before v2 work; develop v2 on branch `v2`; merge to `main` after M2 exit review; `main` always releasable after that. Prototype data is not migrated.
- **Consequences**: v2 PRs target `v2` until merge; CI runs on both.
- **Refs**: `TASKS.md` M1-01, `../spec/07-distribution.md` §4.3

### D-016 — Application identity: `org.freecad.ext.launcher`
- **Date**: 2026-09-18
- **Status**: Accepted
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
