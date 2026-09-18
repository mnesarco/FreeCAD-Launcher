# 01 — Vision

## 1. Problem

FreeCAD's official builds are portable bundles (AppImage, `.7z` archives, `.dmg`) that share
one global user data directory by default. Users who want more than one environment must
manually:

- download and extract multiple FreeCAD versions,
- juggle environment variables (`FREECAD_USER_HOME`, `HOME`, `XDG_*`) to keep configs apart,
- manage `Mod/` addon folders and `AdditionalPythonPackages` per environment,
- install Python dependencies into the right interpreter without breaking the system Python,
- fight platform quirks: AppImage/FUSE, macOS Gatekeeper, Windows `pip.exe` paths.

The prototype proved the concept but was built before this scope was clear. It supported
Flatpak/Snap, had a hard-coded profile model, an empty Launchers/Macros surface, no tests,
and a schema that no longer matches the desired feature set.

## 2. Vision

**FreeCAD Launcher is the one tool that lets any user install FreeCAD, build isolated
profiles, equip them with addons/macros/Python packages, and launch them — on Linux, Windows,
and macOS — without touching system Python or global config.**

One sentence: *"Multiple FreeCAD environments, cleanly separated, one click to launch."*

## 3. Goals

| ID | Goal |
|---|---|
| G1 | Install and manage official FreeCAD builds from GitHub (stable, weekly, older) plus user-supplied files |
| G2 | Create unlimited profiles on shared builds with fully isolated config, data, addons, macros, and temp |
| G3 | Install/update/remove addons per profile from the official catalog, with bundles for one-click setups |
| G4 | Install Python packages per profile using FreeCAD's bundled interpreter, never system Python |
| G5 | Manage macros per profile (list, install from catalog, delete, reveal) |
| G6 | Launch from the app or via a generated CLI command, with transparent, reproducible env handling |
| G7 | Back up, export, and import profiles (manifest-only or full archive) |
| G8 | Keep everything observable and safe: checksums, confirmation before executing third-party code, visible logs, no telemetry |

## 4. Non-goals

| ID | Non-goal |
|---|---|
| NG1 | Managing Flatpak or Snap FreeCAD installs |
| NG2 | Compiling FreeCAD from source |
| NG3 | Managing distro-packaged FreeCAD (`apt`/`dnf`/`pacman`) |
| NG4 | Hosting addons, macros, or builds ourselves |
| NG5 | Cloud sync, accounts, telemetry |
| NG6 | Being an addon IDE or Python IDE |
| NG7 | A plugin/extension system for the launcher itself |
| NG8 | Mobile/web versions |
| NG9 | Desktop entries/shortcuts generation (CLI + in-app launch only, for now) |

## 5. Personas

| Persona | Needs | Success looks like |
|---|---|---|
| **New user "Ana"** | FreeCAD + a few popular addons, doesn't know what `Mod/` is | Install app, click "Add FreeCAD", click "New profile", pick addons, launch |
| **Power user "Ben"** | Try weekly builds without touching his stable config; multiple projects with different addon sets | Installs both channels, profiles are independent, can roll back a build |
| **Workflow owner "Chi"** | Ship a predefined environment to a class/team | Builds a bundle, exports it, others import and apply in one step |
| **Addon author "Dee"** | Test an addon across versions and fresh configs | Creates throwaway profiles, installs local zips, inspects logs, deletes cleanly |

## 6. Principles

1. **Isolate by default.** Every profile is self-contained; nothing leaks into `$HOME` or system Python.
2. **Transparent.** The exact command and environment used to launch a profile is inspectable
   and copy-pasteable ("Show launch command").
3. **Safe.** Downloads are checksum-verified when a checksum exists. Installing addons and
   Python packages is code execution and always requires explicit user action with a clear summary.
4. **Offline-tolerant.** Installed builds and profiles work offline; catalogs are cached; network
   failures degrade gracefully and never destroy state.
5. **Atomic.** Mutations to profiles and installed builds are staged and committed atomically;
   failed installs never leave half-written directories.
6. **Portable data.** Profiles and exports are plain directories/archives that can be moved by hand.
7. **Native feel.** Material 3, dark/light, keyboard-friendly, platform file dialogs.

## 7. Success criteria

Functional (v1.0):

- [ ] Clean-machine flow: install launcher → install a FreeCAD build → create profile → install
      an addon with `requirements.txt` → launch → verify config/addons are profile-local.
- [ ] Two profiles on the same build do not share `user.cfg`, `Mod/`, macros, or Python packages.
- [ ] A profile exported on Linux imports on Windows/macOS (manifest mode) and reinstalls equivalent content.
- [ ] Removing a build that is in use is blocked with a clear explanation.
- [ ] Weekly channel install works and can be updated in place.
- [ ] App runs offline with an existing build/profile (banners instead of failures).

Quality:

- [ ] `flutter analyze` clean, unit/widget test suite green in CI on all three OSes.
- [ ] No crash logs in a 30-minute exercise of install/addon/pip/export/import.
- [ ] Time-to-first-launch from a warm app: < 3 seconds on a mid-range machine.
