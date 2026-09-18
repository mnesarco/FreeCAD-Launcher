# 04 — Architecture

## 1. Stack (locked)

| Concern | Choice |
|---|---|
| UI | Flutter (stable channel), Material 3 |
| State | `signals_flutter` (signals, streamSignal); controller classes per feature |
| Persistence | `drift` + `sqlite3_flutter_libs`, codegen via `build_runner` |
| HTTP | `package:http` with a shared client (timeouts, ETag cache, optional token) |
| Archives | `package:archive` (zip, tar.gz, gzip); **7z requires an external strategy** (see risks) |
| Crypto | `package:crypto` (SHA-256) |
| Files | `path_provider`, `path`, `file_selector` |
| Misc | `xml` (package.xml, user.cfg), `uuid`, `collection`, `intl`, `url_launcher`, `flutter_svg` |

Dropped from the prototype: `snapd` (Snap is out of scope), Flatpak process probing, the
prototype's bespoke download service.

## 2. Layering

```
ui/          views + widgets, no business logic, reads controllers
state/       controllers exposing signals; orchestrates services; single writer per domain
domain/      pure Dart: models, value objects, policies (version rules, bundle apply plan,
             env building, asset classification, path mapping)
data/        drift database, DAOs, repositories, cache stores
platform/    OS integration: process runner, filesystem ops, extraction, checksums,
             diagnostics, CLI wrapper install
core/        Result/AppError, logging, config, extensions
```

Rules:

- `domain/` imports nothing from `state/`, `data/`, `platform/`, or `ui/`.
- `ui/` never touches `platform/` directly; controllers mediate.
- One controller owns each aggregate: `BuildsController`, `ProfilesController`,
  `AddonsController`, `MacrosController`, `BundlesController`, `PythonController`,
  `JobsController`, `UpdatesController`, `SettingsController`, `DiagnosticsController`.
- Controllers are created once in an `AppServices` container exposed via an `InheritedWidget`
  (`AppScope`), replacing the prototype's `MainController`.

## 3. Proposed directory layout

```
lib/
  main.dart                     # CLI arg parsing; runApp
  app.dart                      # MaterialApp, theme, sidebar shell
  core/                         # result.dart, errors.dart, log.dart, constants.dart
  domain/
    builds/                     # Build model, asset classification, version compare
    profiles/                   # Profile model, env builder, path mapping
    addons/                     # catalog models/parser, update rules
    macros/                     # macro catalog model
    bundles/                    # bundle model, apply planner
    python/                     # package spec parsing, target dir rules
  data/
    database.dart + database.g.dart
    daos/                       # builds_dao, profiles_dao, addons_dao, ...
    repositories/               # BuildRepository, ProfileRepository, ...
    catalog/                    # github_releases_client, addon_catalog_cache
  platform/
    process.dart                # ProcessRunner (arg arrays, env, streaming, kill tree)
    launch.dart                 # FreeCadRuntime: command + env per build kind/OS
    extract.dart                # zip safe-extract, tar, dmg, 7z strategy
    checksum.dart               # sha256 file/string
    python_env.dart             # interpreter discovery, pip invocation
    diagnostics.dart            # FUSE, Gatekeeper, disk, permissions
    cli_wrapper.dart            # generate shell/cmd wrappers
    paths.dart                  # app dirs, build paths, profile paths
  state/
    app_services.dart           # container + AppScope
    jobs.dart                   # job queue, progress signals
    builds.dart
    profiles.dart
    addons.dart
    macros.dart
    bundles.dart
    python.dart
    updates.dart
    settings.dart
  ui/
    shell/                      # sidebar, status bar
    home/  profiles/  builds/  addons/  macros/  settings/
    widgets/                    # shared: job tile, badge, empty state, confirm dialogs
```

## 4. Launch and environment model

A profile launch is a pure function of (build, profile, user args, OS) → (executable, argv, env).
This function lives in `domain/profiles/env.dart` and is **unit-tested per OS**.

### 4.1 Environment (isolation)

| Variable | Linux | Windows | macOS |
|---|---|---|---|
| `FREECAD_USER_HOME` | `<profile>` | `<profile>` | `<profile>` |
| `FREECAD_USER_TEMP` | `<profile>/temp` | `<profile>\temp` | `<profile>/temp` |
| `HOME` | `<profile>/home` | (not set) | `<profile>/home` |
| `XDG_CONFIG_HOME` / `XDG_DATA_HOME` / `XDG_CACHE_HOME` | `<profile>/xdg/{config,data,cache}` | n/a | n/a |
| `APPDATA` / `LOCALAPPDATA` | n/a | `<profile>\AppData\{Roaming,Local}` | n/a |
| `TMPDIR` / `TEMP`+`TMP` | `<profile>/temp` | `<profile>\temp` | `<profile>/temp` |
| `PYTHONPATH`, `PYTHONHOME`, `VIRTUAL_ENV`, `PYTHONUSERBASE` | removed | removed | removed |

Notes:

- FreeCAD ignores a custom dir that does not exist, so the launcher creates all dirs first.
- With a custom user home, FreeCAD's macro dir collapses to the profile root (no `Macro/`
  subdir). The macro manager therefore scans `<profile>/*.FCMacro` and `<profile>/Macro/` if present.
- FreeCAD 1.1's versioned user dirs (`v1-1/`) do not apply to custom env dirs; profiles are
  stable across FreeCAD minor upgrades.
- Windows Qt registry state may remain shared (known limitation; document it).
- The env is passed as a full map with inherited vars sanitized, never through a shell.

### 4.2 Executable and argv per build kind

| Kind | Executable | Notes |
|---|---|---|
| AppImage (Linux) | `<build>/FreeCAD_*.AppImage` | Use FUSE when available, else set `APPIMAGE_EXTRACT_AND_RUN=1` (detected via `/dev/fuse`/`fusermount`) |
| Archive (Windows) | `<build>\FreeCAD.exe` (`bin\` layout respected) | extracted from `.7z` portable |
| Archive (macOS) | `<build>/FreeCAD.app/Contents/MacOS/FreeCAD` | spawn directly to keep env; strip quarantine on install with user consent |
| Custom | user-configured executable | env still applied |

Optional explicit args: `-u <profile>/user.cfg -s <profile>/system.cfg` are passed for clarity
even though `FREECAD_USER_HOME` already places them there.

### 4.3 Process tracking

- `Process.start(..., mode: normal)` per launch; the app keeps a handle while it lives and
  exposes a `running` signal per profile. If the launcher exits, FreeCAD keeps running.
- stdout/stderr are streamed to a per-launch log file under `logs/launch-<profile>-<ts>.log`.
- No `--single-instance` is ever passed (it is global, not profile-scoped).

## 5. Build installation pipeline

```
resolve asset → preflight (disk, network) → download to cache (.part)
→ verify sha256 → stage extract → detect python → atomic rename to builds/<id>/
→ DB insert (status=installed) → emit change signal
```

- Extraction is safe by construction: entries are normalized, absolute paths rejected, `..`
  rejected, symlinks are not recreated outside the target (zip-slip guard).
- `.dmg` handling: mount via `hdiutil attach -nobrowse -readonly`, copy `FreeCAD.app`, then
  `hdiutil detach`; quarantine removal (`xattr -dr com.apple.quarantine`) is offered with an
  explanation because official notarization has been unreliable (issue FreeCAD/FreeCAD#30621).
- `.7z`: strategy chosen after spike S1 (system `7z`/`7za` if present; otherwise a bundled
  decoder or a clear actionable error). A missing extractor must never corrupt state.
- AppImage needs no extraction; the file is stored with the exec bit set and verified.

## 6. Downloads, jobs, caching

- `JobsController` owns a queue; each job has kind, label, progress signal, log buffer,
  cancellation token, and a final `Result`.
- HTTP layer: one `http.Client`; conditional GET (ETag/Last-Modified) for GitHub API; a 6-hour
  TTL for catalogs; offline mode serves stale cache with a warning.
- GitHub rate limit strategy: anonymous 60 req/h; persist ETag + payload in DB/cache; use
  `X-RateLimit-Remaining` to back off; optional token raises the limit to 5,000 req/h (OQ-3).
- Caches: `cache/addons/addon_catalog_cache.zip`, `cache/addons/stats.json`,
  `cache/github/releases-<channel>.json`, `cache/downloads/<sha256>`.
- Downloads resume: not in v0.1; `.part` files are deleted on cancel/failure.

## 7. Update engine

| Target | Source | Detection |
|---|---|---|
| Launcher (v0.2) | own GitHub releases | semver compare vs `constants.version` |
| FreeCAD build | GitHub releases | same channel+arch, newer semver or newer weekly date |
| Addon | catalog cache | installed version/`last_update_time` vs catalog entry |
| Python package | installed list | manual check only (v0.2) |

All detections produce **suggestions** only; the UI batches confirmed actions through the job
queue. Update-in-place for a build uses "install new alongside → switch profiles → optional
delete old" so a failure never removes a working build.

## 8. Error model and logging

- `Result<T>` (`Ok`/`Err`) for fallible operations; `AppError` carries user message, detail,
  cause, and whether retry is safe.
- UI maps `AppError` to inline messaging; raw details go to logs and the "Details" expander.
- Logging: structured, leveled (`error/warn/info/debug`), rotating files in `logs/`,
  sensitive values (tokens, full env) redacted.
- A diagnostic bundle zips recent logs + environment summary (no secrets) for issue reports.

## 9. Testing and CI

- **Unit**: asset classification, version compare (semver + weekly dates), env builder per OS,
  path mapping, bundle apply planner, addon parser, pip spec parser, safe-extract guards.
- **Data**: drift tests against in-memory SQLite (no mocks of the DB).
- **Widget**: shell navigation, profile creation, addon install dialog, job failure rendering.
- **Platform smoke** (not required on every PR): extraction and process spawning behind
  `@Tags(['platform'])`, run on CI matrix.
- **CI (GitHub Actions)**: matrix `ubuntu-latest`, `windows-latest`, `macos-latest` →
  `flutter analyze`, `flutter test`, `dart run build_runner build --delete-conflicting-outputs`
  (fail if generated files are stale), then `flutter build` per OS.
- No integration tests requiring network in CI; HTTP is injected and faked at the client boundary.

## 10. Prototype disposal

- Keep the prototype retrievable via a git tag/branch (e.g. tag `prototype-final`) before
  replacing `lib/`.
- Delete: Flatpak/Snap services, old DB schema and generated files, old controllers/views.
- Reuse: `addon_index_spec.md` domain knowledge and the addon catalog parser as a starting
  reference, not as code to keep verbatim.
