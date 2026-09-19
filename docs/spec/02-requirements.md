# 02 — Requirements

Priority tags: **[v0.1]** MVP, **[v0.2]** next, **[v1.0]** before public stable release.

## Functional requirements

### FR-1 Build management

- FR-1.1 **[v0.1]** The app lists installable stable builds for the current OS/arch from the
  official GitHub releases, with version, channel, size, date, and checksum availability.
- FR-1.2 **[v0.1]** Installing a build downloads it, verifies SHA-256 against the
  `-SHA256.txt` sidecar (when present), extracts if needed, and records it atomically.
- FR-1.3 **[v0.1]** Supported formats: Linux AppImage, Windows portable `.7z`, macOS `.dmg`
  (`.app` extracted), and user-supplied local files/URLs. A local FreeCAD executable may also be
  referenced in place (self-compiled or installed by other methods), Linux-first.
- FR-1.4 **[v0.1]** Installed builds are listed with disk usage, status (`installed`, `missing`,
  `broken`), and which profiles use them.
- FR-1.5 **[v0.1]** Deleting a build is blocked while visible profiles reference it; unused
  builds can be deleted with their files.
- FR-1.6 **[v0.1]** User-supplied builds: pick a file or paste a URL, optionally provide a
  version label and checksum; trust confirmation is required. Selecting an executable references
  it in place (never copied or deleted by the launcher), and a local AppImage is symlinked into
  the builds directory rather than duplicated. Hashing runs only when a checksum is provided and
  progress is shown; its Python version is detected best-effort with a manual interpreter picker
  as fallback.
- FR-1.7 **[v0.2]** Weekly/pre-release channel (`weekly-YYYY.MM.DD` and rolling `weeklies`) and
  older supported stable lines (currently 1.0.x as `legacy`). Releases older than 1.0 are
  ignored (D-021).
- FR-1.8 **[v0.2]** "Check for updates" marks installed stable/weekly builds with a newer
  release; user confirms an in-place update that keeps profiles intact.
- FR-1.9 **[v0.2]** Each build reports its bundled Python version, detected once on install.
- FR-1.10 **[v1.0]** Re-verify integrity ("verify files") and repair a broken build.

Acceptance (v0.1): on each OS, installing the latest stable build produces a launchable
binary; a corrupted download fails checksum verification and leaves no partial install.

### FR-2 Profiles

- FR-2.1 **[v0.1]** Create a profile with name + build; the directory layout and env vars are
  created automatically and atomically.
- FR-2.2 **[v0.1]** Profiles list shows name, FreeCAD version, channel, addon count, Python
  package count, last used, and build health.
- FR-2.3 **[v0.1]** Editing a profile allows rename and build change; changing to a build with
  a different Python version warns that installed addons/Python packages may need reinstall.
- FR-2.4 **[v0.1]** Duplicate a profile (fresh id, copied config) and delete a profile
  (confirmation, optional "keep exported backup").
- FR-2.5 **[v0.1]** Launch a profile in-app; running state is shown while the process lives.
- FR-2.6 **[v0.1]** "Show launch command" reveals the exact executable + env + args.
- FR-2.7 **[v0.1]** Deleting a profile never deletes shared builds.
- FR-2.8 **[v0.2]** Profile templates (empty / inherit from existing / from a bundle).

Acceptance (v0.1): two profiles on the same build have disjoint `FREECAD_USER_HOME` trees;
editing a setting in one never affects the other.

### FR-3 Launchers (CLI + in-app)

- FR-3.1 **[v0.1]** The application binary supports a CLI mode before the UI starts:
  `freecad-launcher list`, `freecad-launcher run <profile>`, `--version`, `--help`.
- FR-3.2 **[v0.1]** Generate a platform wrapper (`~/.local/bin/freecad-launcher` on Linux/macOS,
  `freecad-launcher.cmd` on Windows) on user request, reporting PATH availability.
- FR-3.3 **[v0.1]** `run` exits with FreeCAD's exit code and passes through extra args after `--`.
- FR-3.4 **[v0.1]** Re-running `run` for an already-running profile is allowed (documented;
  no single-instance guarantee).
- FR-3.5 **[v0.2]** CLI subcommands for addon install/remove and bundle apply.

Acceptance (v0.1): after wrapper installation, a new terminal can run
`freecad-launcher run "My Profile"` and FreeCAD starts isolated.

### FR-4 Addons

- FR-4.1 **[v0.1]** Browse/search/filter the official addon catalog (cached; works offline with
  the last cache). Filter by tag, content type, and installed state.
- FR-4.2 **[v0.1]** Addon detail: name, description, authors, license, tags, version, required
  FreeCAD range, branches, last update, repository link, icon.
- FR-4.3 **[v0.1]** Install an addon into a chosen profile: download, safe-extract (no path
  traversal/symlink escape), place in `<profile>/Mod/<AddonId>`, record version/branch.
- FR-4.4 **[v0.1]** When several branches exist, the user picks one; the default is the first
  compatible entry.
- FR-4.5 **[v0.1]** Detect and show an update when the catalog entry is newer than the
  installed version; update replaces the addon folder after backing up.
- FR-4.6 **[v0.1]** Remove an addon from a profile; the catalog stays untouched.
- FR-4.7 **[v0.1]** If the addon archive contains `requirements.txt`, show the packages and
  offer the FR-6 install flow (never automatic).
- FR-4.8 **[v0.2]** Install a local addon zip (developer workflow).
- FR-4.9 **[v0.2]** Warn when an addon's FreeCAD range does not match the profile's build.

Acceptance (v0.1): installing a workbench adds exactly one directory under `Mod/`, survives
restart, and is usable inside FreeCAD.

### FR-5 Addon bundles (collections)

- FR-5.1 **[v0.1]** Create a bundle from a profile's installed addons; edit name, description,
  and items (add/remove/branch).
- FR-5.2 **[v0.1]** Apply a bundle to a profile: preview (install/update/skip/conflict per item),
  then execute; nothing is applied without confirmation.
- FR-5.3 **[v0.1]** Export/import a bundle as JSON (`schema`, `name`, `description`, `addons`);
  imported bundles are validated against the catalog.
- FR-5.4 **[v0.2]** Mark bundles as favorites and show them on the Home screen.

Acceptance (v0.1): a bundle exported from one machine applies cleanly on another, skipping
items already installed at the same version.

### FR-6 Python packages

- FR-6.1 **[v0.1]** Install a package into a profile using the build's bundled interpreter:
  `<python> -m pip install --target <profile>/AdditionalPythonPackages[/pyXY]`.
- FR-6.2 **[v0.1]** Show installed packages per profile (name, version, source: manual/addon)
  and allow uninstall.
- FR-6.3 **[v0.1]** Package spec input supports `name`, `name==version`, and pasted
  `requirements.txt` content; a preview of resolved packages is shown before install.
- FR-6.4 **[v0.1]** Stream pip output to a log view; failures are surfaced with the raw error
  and never leave a half-updated DB state.
- FR-6.5 **[v0.2]** Show a `pip --dry-run` resolution preview and detect conflicts with
  bundled modules (`AdditionalPythonPackages` is last on `sys.path`) before installing.
- FR-6.6 **[v0.2]** Record every pip install in a per-profile log with the full command used.

Acceptance (v0.1): `pip install --target` via the bundled interpreter makes the module
importable inside that profile's FreeCAD and invisible to other profiles.

### FR-7 Macros

- FR-7.1 **[v0.1]** List macros found in the profile's macro location(s), with size and date.
- FR-7.2 **[v0.1]** Install macros from the official macro catalog/repository.
- FR-7.3 **[v0.1]** Delete a macro (confirmation) and reveal it in the OS file manager.
- FR-7.4 **[v0.1]** Open a macro with the system default editor.
- FR-7.5 **[v0.2]** Run a macro via `FreeCADCmd` with the profile environment and show output
  (GUI-session macros remain "open FreeCAD and run there").

Acceptance (v0.1): macros installed by the launcher appear in FreeCAD's Macro menu for that
profile and not in others.

### FR-8 Per-profile configuration

- FR-8.1 **[v0.1]** Show config/data paths and file presence (`user.cfg`, `system.cfg`) for a
  profile; open the config dir in the file manager.
- FR-8.2 **[v0.1]** Back up / restore a profile's config files (timestamped copies inside the profile).
- FR-8.3 **[v0.2]** In-app preference browser for a curated set of safe `user.cfg` parameters,
  with raw XML editing behind an "advanced" gate and validation.
- FR-8.4 **[v0.2]** Reset a profile's config to defaults with a pre-reset backup.

### FR-9 Backup, export, import

- FR-9.1 **[v0.1]** **Manifest export**: JSON with profile metadata, addon list, Python packages,
  bundles, and config file list; no addon payloads. Import recreates the profile and reinstalls
  from catalogs.
- FR-9.2 **[v0.2]** **Full export**: `.zip` containing config, macros, addons, and package
  manifests (payloads optional toggles). Import restores files directly.
- FR-9.3 **[v0.1]** Import never overwrites an existing profile; it creates `<name> (imported)`.
- FR-9.4 **[v0.1]** Export/import must be portable across OSes; manifest mode is authoritative.

Acceptance (v0.1): Linux→Windows manifest import produces a profile with the same addon set
and config intent (paths rewritten, absolute paths reported).

### FR-10 Updates

- FR-10.1 **[v0.1]** Check addon updates against the cached catalog; badge affected profiles/addons.
- FR-10.2 **[v0.1]** Check for new stable FreeCAD releases on demand and on a configurable schedule.
- FR-10.3 **[v0.1]** All checks are notify-only; every install/update requires confirmation.
- FR-10.4 **[v0.1]** "Check all" action + per-item check; results are cached with timestamps.
- FR-10.5 **[v0.2]** Launcher self-update (AppImage): download, verify, replace on restart.
- FR-10.6 **[v0.2]** Changelog display from the GitHub release body.

### FR-11 Downloads and jobs

- FR-11.1 **[v0.1]** A visible job queue with per-job progress, speed, cancel, retry, and logs.
- FR-11.2 **[v0.1]** Jobs run concurrently with a small limit (downloads 2, no parallel installs
  into one profile).
- FR-11.3 **[v0.1]** Cancelled/failed jobs clean up partial files.
- FR-11.4 **[v0.1]** Cache management: catalog zips and downloads can be cleared with size info.

### FR-12 Settings and diagnostics

- FR-12.1 **[v0.1]** Settings: theme, data directory, update check cadence, cache size + clear,
  log level, logs folder, about/license.
- FR-12.2 **[v0.1]** Optional GitHub token (for higher API rate limits), stored securely
  (see OQ-3); never logged.
- FR-12.3 **[v0.1]** Environment diagnostics: FUSE availability (Linux), Gatekeeper state and
  quarantine handling (macOS), path/permission checks, disk space.
- FR-12.4 **[v0.1]** Export a debug bundle (logs + versions + diagnostics, no secrets).

## Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-1 | **Platform support**: Linux x86_64/aarch64 (glibc, FUSE optional), Windows 10/11 x86_64, macOS 11+ x86_64/arm64 |
| NFR-2 | **Startup**: Home interactive in < 2 s warm; first catalog load must not block the UI |
| NFR-3 | **Offline**: full profile/build management offline; catalogs from cache; clear offline banners |
| NFR-4 | **Atomicity**: all filesystem mutations staged in `<target>.part`/temp and renamed; DB updated after commit |
| NFR-5 | **Security**: checksum verification; no shell string interpolation (arg arrays only); zip-slip/symlink guards; explicit consent before running third-party installers/scripts; token redaction |
| NFR-6 | **Privacy**: no telemetry, no analytics, no background network calls without a user-visible reason |
| NFR-7 | **Reliability**: crashes leave DB consistent; logs rotate (max ~5 × 2 MB) |
| NFR-8 | **Accessibility**: keyboard navigable, semantic labels, minimum contrast per Material 3 |
| NFR-9 | **i18n-ready**: all user strings in ARB files; v0.1 ships English only (OQ-6) |
| NFR-10 | **Disk**: every destructive size operation shows an estimate; no duplicate extraction of an installed build |
| NFR-11 | **Testing**: unit tests for parsers/version logic/env builders/path mapping; drift tests in-memory; widget tests for key screens; CI on 3 OSes |
| NFR-12 | **Code quality**: `flutter analyze` clean (flutter_lints), 100-char lines, generated files checked in |
