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
