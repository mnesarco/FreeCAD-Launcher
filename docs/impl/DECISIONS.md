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
