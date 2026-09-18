# 08 — Roadmap

## 1. Milestones

### M0 — Decisions complete

- Exit: open questions OQ-1..OQ-8 answered or explicitly deferred; spec reviewed.
- No code.

### M1 — Foundation

- Flutter project reset on `v2`: new `lib/` layout, `AppServices` + signals wiring, drift
  schema v1 + DAOs, logging, `Result`/`AppError`, `ProcessRunner`, paths, diagnostics.
- CI matrix added (analyze, tests, build per OS).
- Exit: app shell with sidebar + empty states runs on all three OSes; schema tests green.

### M2 — Builds

- GitHub releases client with ETag cache and rate-limit handling, asset classifier, version
  compare; stable channel UI; download/checksum/extract pipeline; AppImage/7z/dmg handling
  (spike S1/S2 resolved before this milestone ends).
- Custom build import (local file/URL).
- Exit: latest stable FreeCAD installs and launches by hand on all three OSes; corrupted
  download is rejected.

### M3 — Profiles and launch

- Profile CRUD, env builder per OS (unit tested), process launch + logs, running state,
  "Show launch command", CLI mode + wrapper generation.
- Exit: two profiles are provably isolated (different `user.cfg`, `Mod/`, macros, pip targets);
  `freecad-launcher run <profile>` works from a fresh shell.

### M4 — Addons and Python

- Catalog cache + parser, browse/search/detail, install/update/remove into profiles,
  requirements detection + pip flow, package list, job queue UI.
- Exit: install a workbench with a `requirements.txt`; module import works only in that profile.

### M5 — Collections, macros, config, export

- Bundles CRUD/apply/export/import; macro catalog + file management; config paths/backup/reset;
  manifest export/import.
- Exit: bundle round-trip between machines; macro appears in FreeCAD only in its profile;
  manifest import recreates the addon set.

### M6 — Updates and polish

- Addon/build update checks, badges, batch update, Settings, cache management, debug bundle,
  empty/error/offline states, accessibility pass.
- Exit: full success-criteria checklist in `01-vision.md` passes manually.

### M7 — v0.1 release

- Linux AppImage pipeline, release workflow, docs (README + user guide), `THIRD_PARTY_NOTICES`.
- Exit: a clean Linux machine can install from the published AppImage and complete the
  first-run flow.

### Post-v0.1 (v0.2 → v1.0)

- v0.2: weekly + legacy channels, in-place build updates, full profile export, preference
  browser, macro run via `FreeCADCmd`, launcher self-update, GitHub token UX, Cmd/KDE polish.
- v1.0: i18n (if OQ-6 says yes), Windows/macOS launcher artifacts (OQ-1), stability hardening,
  user documentation, possibly bundle sharing/curated collections.

## 2. MVP cut line (v0.1)

In:

- Stable build install/manage/remove + custom builds
- Profiles with full isolation, launch in-app + CLI wrapper
- Addon catalog install/update/remove + collections (basic)
- Python packages via bundled pip (manual + requirements)
- Macro list/install/reveal/open/delete
- Manifest export/import; config backup/reset
- Addon update checks + build release checks (notify only)
- Diagnostics, logs, settings, cache clearing

Out / deferred:

- Weekly and legacy channels (v0.2)
- Full-archive export and profile import with payloads (v0.2)
- Preference browser, config reset, macro run (v0.2)
- Launcher self-update (v0.2)
- Windows/macOS launcher artifacts (OQ-1)
- i18n (OQ-6)

## 3. Spikes (before or during M2/M4)

| ID | Question | Exit criteria |
|---|---|---|
| S1 | How to extract `.7z` in Dart/Flutter reliably? | Working extractor chosen: pure-Dart package, FFI libarchive, or bundled 7-Zip helper; measured on a real FreeCAD 7z; no shell injection; license compatible; cross-platform |
| S2 | macOS `.dmg` handling | `hdiutil` mount/copy/detach works unattended; quarantine removal consent flow tested; app launches from `builds/<id>` |
| S3 | pip uninstall with `--target` | A documented, tested removal procedure (recompute + delete) or a decision to ship install-only in v0.1 |
| S4 | Macro catalog source | Verified repo/API for macros, stable download URL, license notes, index format |
| S5 | AppImage packaging for Flutter | Reproducible AppImage built in CI (linuxdeploy or appimage-builder), runs on clean Ubuntu/Fedora without missing libs, zsync update info present |
| S6 | FUSE-less Linux launching | `APPIMAGE_EXTRACT_AND_RUN=1` works for FreeCAD AppImages on a system without libfuse2; detection logic validated |
| S7 | Weekly channel availability | Confirm `weekly-YYYY.MM.DD` and `weeklies` assets for all three OSes remain stable over a month; define fallback |

## 4. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| `.7z` extraction has no mature pure-Dart option | Windows MVP blocked | Spike S1 early; fallback: ship a small helper or prefer `.zip`/installer silent extract if a portable format changes |
| macOS notarization failures (FreeCAD#30621) | App won't launch without user steps | Consent-based quarantine removal, diagnostics, clear right-click→Open guidance; never claim notarized |
| GitHub API 60 req/h | Catalog/update checks fail | 6 h TTL, ETag cache, backoff, optional PAT, offline stale cache |
| Weekly builds are unstable/changing | Broken builds installed | Weekly marked development; install alongside stable; never auto-update; S7 |
| pip conflicts with bundled modules | Addon breakage | Warn, last on `sys.path` note, per-profile isolation, clear error surfacing |
| Disk usage (multi-version builds, addon backups) | User frustration | Show sizes, cap backups (last 3), easy removal, single extraction per build |
| AppImage self-replacement while running | Corruption | Stage + swap on restart only; checksum before swap |
| Prototype users lose data | Complaints | Fresh start is locked; document clearly in README/release notes; offer manual copy of old `Mod` folders into new profiles |
| Cross-platform env isolation gaps (Windows registry Qt state) | Settings leak between profiles | Document known limitation; keep FreeCAD-level isolation complete; revisit with `-settings` if Qt supports it |

## 5. Definition of done (per feature)

1. Requirements (FR/NFR) implemented and acceptance criteria manually verified per OS.
2. Unit/widget tests added where logic exists; `flutter analyze` clean.
3. Error, empty, loading, offline states implemented.
4. Logs and diagnostics cover failures; no sensitive data logged.
5. Docs updated (`docs/spec/` status, user guide when it exists).
6. Works offline unless the feature is explicitly network-only, and says so clearly.
