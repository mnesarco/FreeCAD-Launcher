<!-- SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# FreeCAD Launcher — User Guide

This guide covers everything needed to install the launcher, manage FreeCAD builds and run
isolated profiles.

- [Concepts](#concepts)
- [Installing the launcher](#installing-the-launcher)
- [First run](#first-run)
- [Builds](#builds)
- [Profiles](#profiles)
- [Addons](#addons)
- [Collections (bundles)](#collections-bundles)
- [Python packages](#python-packages)
- [Macros](#macros)
- [Config and backups](#config-and-backups)
- [Profile manifest export/import](#profile-manifest-exportimport)
- [Updates](#updates)
- [Settings](#settings)
- [Command line interface](#command-line-interface)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Data locations](#data-locations)
- [Troubleshooting](#troubleshooting)
- [Known limitations (v0.1)](#known-limitations-v01)

## Concepts

- **Build** — an installed FreeCAD version. Catalog builds are downloaded once into a managed
  directory; local custom AppImages are symlinked; self-compiled executables are referenced
  where they are (never copied or deleted).
- **Profile** — isolated user data for a task or project: its own `user.cfg`/`system.cfg`,
  addons (`Mod/`), macros, Python packages and temporary files. Profiles share the installed
  build, so multiple profiles do not duplicate FreeCAD binaries.
- **Isolation** — when a profile is launched, FreeCAD gets a private `FREECAD_USER_HOME` (plus
  private XDG and temporary directories; your `HOME` is left untouched), so nothing touches your
  global FreeCAD setup.
- **Job** — any download/install/uninstall runs through a shared job queue with progress,
  cancel/retry and logs, visible in the status bar.

## Installing the launcher

### Linux (AppImage)

Download the latest AppImage from the
[Releases page](https://github.com/mnesarco/FreeCAD-Launcher/releases) (built by CI through the
manually triggered *Release AppImage* workflow) or build it locally (see the README). Then:

```sh
chmod +x FreeCADLauncher-<version>-x86_64.AppImage
./FreeCADLauncher-<version>-x86_64.AppImage
```

- If the system has no FUSE (`libfuse2`), run the launcher with
  `APPIMAGE_EXTRACT_AND_RUN=1 ./FreeCADLauncher-<version>-x86_64.AppImage`.
- Optional desktop integration: install the AppImage with AppImageLauncher or copy the bundled
  `.desktop` file from `usr/share/applications/freecad-launcher.desktop` inside the AppImage.

### From source (development)

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d linux
```

Requires Flutter 3.41.4 (stable) and the usual Linux desktop build dependencies.

## First run

1. The launcher fetches the official FreeCAD release catalog (cached for 6 hours; it works
   offline with a stale-data notice).
2. Go to **Versions → Available** and install a stable release (1.0 or newer). The first visit
   loads the catalog automatically; use *Check for updates* to refresh.
3. Go to **Profiles → New profile**, name it and bind it to the installed build.
4. Click **Launch**. FreeCAD starts with a clean, isolated configuration; the first start creates
   `user.cfg`/`system.cfg` in the profile directory.

The Home dashboard shows counts, the last-used profile with a launch button, update checks and a
news feed with a short excerpt of each post (URL configurable in Settings).

## Builds

### Install from the catalog (Versions → Available)

- Each entry shows version, size and detected Python version.
- Use the **Stable | Weekly** channel selector: weekly builds are dated development snapshots
  (`weekly-YYYY.MM.DD`) shown with a badge; the latest 52 (one year) are listed, newest first.
  Installing one asks for confirmation because they are development-quality and not covered by
  support.
- **Install** downloads the asset (`.part` file, cancellable), verifies the published SHA-256
  when available, installs it as a managed copy and detects the bundled Python interpreter.
- Successful installs switch to the **Installed** tab automatically.

### Import custom builds (Versions → Custom)

- **Local file** — pick an AppImage, archive (`.7z`, `.zip`, `.tar.gz`, `.tgz`, `.tar`) or a
  self-compiled executable. Executables are validated (exist, executable bit) and referenced in
  place: the launcher never copies, moves or deletes them. Local AppImages are symlinked into
  the launcher's build directory (the original stays untouched).
- **URL** — paste a direct download URL; an optional SHA-256 checksum is verified when given
  (hashing is skipped otherwise).
- Custom imports are confirmed with a trust dialog; when Python cannot be detected automatically
  the launcher offers *Choose Python…* to select the interpreter the build uses.
- Local custom builds without a detected Python cannot be bound to a profile (addons and pip
  need an interpreter); the picker or a build with a detectable interpreter solves this.

### Manage installed builds

- **Relabel** (pencil) — give a build a friendly name; clear the field to restore the version.
- **Verify** (shield) — re-check that the executable/files still exist and that AppImage hashes
  match; the status badge updates to Missing/Broken when needed.
- **Remove** (trash) — catalog/URL installs delete their managed files; custom executables and
  local AppImages only lose the launcher entry (your file stays where it is). Removing a build
  used by a profile is blocked until the profile is reassigned or deleted.
- Builds that disappear from disk are marked **Missing** at startup and cannot be launched.

## Profiles

### Create and edit

- **New profile** from the Profiles header; name rules: trimmed, 1–64 characters, unique.
- The build list only offers installed builds with a detected Python.
- Edit (pencil on the profile detail page), duplicate (kebab menu; config only by default, or
  with payload), delete (removes the profile directory and database rows; shared builds are not
  affected).

### The profile detail page

- **Overview** — build, channel, Python, health, paths and config file state.
- **Addons / Python / Macros** — per-profile content (see below).
- **Config / Backups** — config snapshots and restore.
- **Launch** — starts FreeCAD; while running, a **Running** badge appears (and on the profile
  card) with a live log path. The badge clears when the process exits.
- **Show launch command** (terminal icon) — the exact executable, arguments and environment
  overrides, ready to copy. You can run the printed POSIX command in a shell to reproduce a
  launch.

### Isolation details

Each launch sets a private `FREECAD_USER_HOME` pointing at the profile directory, plus private
XDG and temporary variables (`HOME` is inherited unchanged). FreeCAD therefore reads/writes only
inside the profile:

```
<data>/profiles/<id>/
  user.cfg, system.cfg     # FreeCAD settings
  Mod/                     # addons
  Macros/                  # macros (FreeCAD's MacroPath is pointed here)
  AdditionalPythonPackages/# pip --target packages (pyXY subdirectory)
  backups/                 # config snapshots, addon pre-update backups
  temp/, xdg/              # private temp/cache
```

Per-launch logs are written to `<data>/logs/launch-<profile>-<timestamp>.log` with the command
header and FreeCAD's console output.

## Addons

The **Addons** section shows the official catalog (cached 6 hours; stale cache is used offline
with a notice).

- Search by text or `#tag`; filter by content type, installed state and, when builds are
  installed, required FreeCAD version. The filter button applies multiple filters at once.
- The detail page shows description, authors, version, license, tags and branches. Pick a branch
  and **Install**, then choose the target profile in the dialog.
- If the addon ships a `requirements.txt`, a consent dialog offers to install its Python
  packages, install the addon only, or cancel.
- Installed addons are listed per profile (Addons tab) with **Update** and **Remove**; updates
  keep a backup under `<profile>/backups/addon-<id>-<timestamp>/`.
- **Pin** an addon per profile to freeze it: pinned addons are skipped by update checks, batch
  updates and bundle apply in that profile. Other profiles are unaffected.
- **Enable/disable**: the switch on each row writes or removes FreeCAD's `ADDON_DISABLED`
  marker in the addon folder. Disabled addons stay installed (and updatable/pinnable) but are
  not loaded by FreeCAD. For a dev link the marker is written into the working copy, since
  FreeCAD reads the linked folder.
- Installed addons show `Installed in N profile(s)` in the catalog; the profile Addons tab uses
  cached catalog icons offline.

### Custom sources (repository, archive, dev link)

The **Custom** tab installs addons that are not in the official catalog. All three sources
require a `package.xml` at the addon root, and an id that is already installed in the profile
must be removed first:

- **Repository**: paste a GitHub/GitLab/Gitea/Codeberg repository URL and a branch/ref — or a
  direct `.zip`/`.tar.gz` URL — and pick the target profile. The resolved archive URL is shown
  before installing. Repository addons get an **Update** action that re-downloads the stored
  URL/ref (backup under `<profile>/backups/addon-<id>-<timestamp>/`).
- **Archive file**: choose a local `.zip`/`.tar.gz` addon archive; **Reinstall from file** later
  replaces it from a new archive.
- **Local folder (development)**: choose an addon working copy; it is symlinked into
  `<profile>/Mod/<id>`, so edits are visible in FreeCAD immediately. Removing the addon deletes
  only the link — the working copy is untouched. This requires symlink support (no copy
  fallback; Windows needs the appropriate privileges).

Each custom addon in the list has an **Install in another profile…** action: the addon is
installed into the chosen profile from the same source (repository re-fetch, the same archive —
or pick the file again if it moved — or a second link to the same working copy). Profiles that
already have the addon are not offered.

Custom addons are excluded from catalog update checks and collections, and profile manifest
import skips them (they cannot be reinstalled from JSON).

## Collections (bundles)

Collections are named lists of addons with optional branch pins, used to reproduce a setup.

- Create/edit a collection; seed it from a profile's installed addons or add entries via the
  catalog picker.
- **Apply** to a profile: a preview shows install/update/skip/unavailable actions (pinned
  addons and up-to-date ones are skipped), then runs sequentially through the job queue with a
  summary; requirements consent is requested once.
- **Export/import** as JSON. Imports validate the format, skip malformed entries, deduplicate
  and report addon ids that are not in the current catalog.

## Python packages

- The profile **Python** tab lists packages installed into that profile
  (`AdditionalPythonPackages/pyXY`) with their source (manual/requirements).
- **Install** takes a requirements string (e.g. `six>=1.16`); the launcher resolves the
  interpreter (detected `pythonPath`, nearby, bundled or AppImage extraction), runs pip with a
  sanitized environment and records the result. Per-run logs are kept.
- **Remove** uses the package's `RECORD` file to delete exactly its files inside the profile and
  prunes empty directories. Pip has no native `--target` uninstall; updates therefore reinstall
  cleanly.
- The system Python is never touched; packages are visible only in the profile that installed
  them.

## Macros

- **Catalog** lists the official macro catalog with search; install targets a profile. Macros
  show their catalog icon when one is available (PNG/SVG; iconless and XPM macros use a generic
  icon). Icons are served from `cache/macros/icons/`, cleared with the macros cache in Settings.
- **Installed** lists macros per profile (name, size, date) with open/reveal/delete actions.
  Deleting removes the file from the profile.
- Macros live in `<profile>/Macros/`; the launcher rewrites FreeCAD's `MacroPath` preference at
  launch so FreeCAD sees exactly that directory.
- Use *Open with editor* / *Reveal in file manager* to edit or inspect a macro outside the
  launcher.

## Config and backups

The profile **Config** tab shows the paths of `user.cfg` and `system.cfg` (created on first
launch) and lets you:

- **Snapshot** the current configuration (both files) — timestamped, newest first, capped at 10
  snapshots per profile.
- **Restore** a snapshot (overwrites the current config files).
- **Delete** individual snapshots; **Open/reveal** the config directory.

Addon updates additionally store backups of the replaced addon under `<profile>/backups/`.

## Profile manifest export/import

Manifest export/import recreates a profile on another machine without copying payloads:

- **Export manifest** (profile card kebab or detail page) writes a JSON file with the profile
  name, build version/channel, embedded `user.cfg`/`system.cfg` text (≤ 4 MiB each), installed
  addons (with branch and pinned state) and Python package specs.
- **Import manifest** (Profiles header) previews the contents, resolves the build by
  version/channel with a picker fallback, and optionally reinstalls addons and Python packages
  from their sources. Name clashes get a `(imported)` suffix.
- Absolute paths found in configs are reported so you can adjust them; `MacroPath` is rewritten
  to the new profile automatically.

## Updates

- The status chip / Updates sheet checks addons against the cached catalog and catalog builds
  against stable releases. Checks run manually or automatically according to the Settings
  cadence (default Manually).
- Updates are **notify-only** — nothing is installed silently. Addons can be updated
  individually or with *Update selected* (per-item toggles), sequentially through the job queue
  with a summary and *Retry failed*.
- **Build updates** are shown as `installed → latest` badges on Versions → Installed and in the
  summary sheet; installing the newer version is a manual action in Versions → Available.
- Pinned addons are skipped per profile.

## Settings

- **General** — theme (System/Light/Dark), update-check cadence, data directory shortcut.
- **Logs** — log level (applied live), open the logs folder, export a **debug bundle** (zip with
  redacted logs, environment and diagnostics; no database) and reveal it.
- **CLI wrapper** — installs a `freecad-launcher` wrapper into a user binary directory so you
  can launch profiles from a terminal; shows PATH guidance (report-only) and removal.
- **Cache** — per-category sizes (downloads, GitHub releases, addons, macros, news), clear a
  category, and *Clean up now* to prune downloads older than the retention period
  (Forever/7/30/90 days, default 30). The next catalog load refetches cleared data.
- **Diagnostics** — FUSE presence, disk/permissions, platform checks.
- **About** — launcher version and project links.

## Command line interface

When the CLI wrapper is installed (Settings → CLI wrapper):

```sh
freecad-launcher list                      # list profiles
freecad-launcher run "My profile"          # launch a profile
freecad-launcher run "My profile" -- --arg # pass arguments through to FreeCAD
freecad-launcher --version
freecad-launcher --help
```

Exit codes: `0` success, `1` failure, `2` usage error. Running the binary without arguments opens
the graphical application.

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl/Cmd+1..6` | Jump to Home, Profiles, Versions, Addons, Macros, Settings |
| `Ctrl/Cmd+N` | New profile |
| `Ctrl/Cmd+F` | Focus search (Macros switches to its Catalog tab) |
| `F5` | Refresh the current section |
| `Esc` | Close the open dialog |

## Data locations

Linux: `~/.local/share/org.freecad.ext.launcher/` (Windows: under `%APPDATA%`; macOS:
`~/Library/Application Support/`).

```
config.db          # index over the filesystem (builds, profiles, addons, packages, bundles, macros)
builds/            # managed build copies and local AppImage symlinks
profiles/          # isolated profile directories
cache/             # downloaded assets and catalog payloads
exports/           # manifest/bundle exports
logs/              # app logs and per-launch logs
```

The database is an index — if you move or delete files behind its back, the startup reconciler
marks the entries as missing/broken instead of losing data.

## Troubleshooting

### The AppImage does not start

- Install FUSE 2 (`libfuse2`) or run with `APPIMAGE_EXTRACT_AND_RUN=1`.
- On a truly headless system the GTK runner still needs an X/Wayland display (even for
  `--version`).

### "No versions available"

- Check your connection and press *Check for updates*. The catalog is cached for 6 hours and
  reused offline (a stale banner appears). GitHub's API may rate-limit unauthenticated requests
  (~60/hour); wait and retry.

### A build is Missing or Broken

- The Installed tab badge explains the state: the executable or its directory is gone
  (**Missing**) or files are corrupted (**Broken**).
- Use *Verify* to re-check; reinstall the build or remove the entry if unused.

### FreeCAD does not launch

- The launcher refuses to launch unhealthy builds; fix or rebind the profile's build first.
- Read the launch log (Running card / `<data>/logs/launch-*.log`) and the app log.
- If the profile's FreeCAD exits immediately, launch it once from a terminal using
  **Show launch command** to see the raw output.

### An addon or pip install fails

- Open the job's log from the jobs dialog (status bar) for the full pip/extraction output.
- Check the profile has a detected Python (profile card / Overview).
- Requirements installs run in the profile only; conflicts with FreeCAD's bundled modules can
  break addons — the consent dialog exists for that reason.

### Report a bug

Settings → Logs → **Export debug bundle** and attach the zip. It contains redacted logs,
environment details and diagnostics — never your database, profiles or tokens.

## Known limitations (v0.1)

- Linux only: Windows/macOS artifacts are planned (packaging/deployment phase).
- Weekly builds are available (Versions → Available → Weekly); the legacy 1.0.x channel is not
  exposed yet (the support floor is FreeCAD 1.0+ for catalog builds).
- Build updates are notify-only: install the new version from Versions → Available and rebind
  profiles manually.
- No launcher self-update yet; replace the AppImage manually.
- i18n scaffolding is in place but v0.1 ships English only.
