# FreeCAD Launcher v2 — Specification

Status: **Draft for review** · Date: 2026-09-18 · License: GPL-3.0-or-later

This directory is the authoritative specification for the v2 rewrite. The current `lib/`
prototype is treated as disposable learning material: v2 is a greenfield implementation that
keeps only the proven stack choices (Flutter + signals + drift) and drops the current code,
schema, and data.

No implementation work should start until the open questions in
[09-open-questions.md](09-open-questions.md) are answered or explicitly deferred.

## Locked decisions

| Area | Decision |
|---|---|
| Trigger | Prototype to rebuild |
| Product | FreeCAD environment manager (builds + isolated profiles + addons/macros + launch) |
| Platforms | Linux, Windows, macOS |
| Build sources | GitHub official stable releases, weekly/pre-release, older versions, user-supplied files |
| Profile model | Shared build per installed version; each profile has an isolated user data dir |
| Features | Isolated profiles, addon catalog install/update, macro manager, launchers, Python deps, profile backup/export, per-profile config, addon bundles |
| Audience | Public OSS, all FreeCAD users |
| Rewrite strategy | Greenfield, same stack (Flutter + signals_flutter + drift) |
| Launcher distribution | AppImage (Linux). See open question OQ-1 for Windows/macOS. |
| Data migration | Fresh start — no migration from the prototype DB |
| Spec format | Multi-file under `docs/spec/` |
| MVP matrix | Linux AppImage + Windows portable archive + macOS dmg |
| Python deps | `pip install --target` into a profile-local dir using FreeCAD's bundled interpreter |
| Macro tooling | Manager only (list/install/delete/reveal); editing external; run deferred |
| Launcher outputs | CLI command + in-app launch (no desktop/shortcut generation) |
| Updates | Check + notify; user confirms download/install |
| Navigation | Sidebar (NavigationRail) |
| Branding | Keep "FreeCAD Launcher"; application id `org.freecad.ext.launcher` (D-016); original icon, no FreeCAD logo bundled (D-070) |
| License | GPL-3.0-or-later |

## Document index

1. [01-vision.md](01-vision.md) — problem, goals, non-goals, personas, principles
2. [02-requirements.md](02-requirements.md) — functional and non-functional requirements with acceptance criteria
3. [03-ux.md](03-ux.md) — navigation, screen inventory, user flows, states, interaction rules
4. [04-architecture.md](04-architecture.md) — stack, layering, services, process/env model, update engine, testing, CI
5. [05-data-model.md](05-data-model.md) — drift schema, filesystem layout, env matrix, export formats
6. [06-integrations.md](06-integrations.md) — GitHub releases, addon catalog, macro catalog, bundled Python/pip
7. [07-distribution.md](07-distribution.md) — AppImage packaging, versioning, self-update, release process
8. [08-roadmap.md](08-roadmap.md) — milestones, MVP cut, risks, spikes, definition of done
9. [09-open-questions.md](09-open-questions.md) — decisions still needed

Reference material kept from the prototype:

- [`../../addon_index_spec.md`](../../addon_index_spec.md) — addon catalog cache format (still valid)

Execution tracking (tasks, status, decisions) lives in [`../impl/`](../impl/README.md).

## Glossary

| Term | Meaning |
|---|---|
| **Build** | One installed FreeCAD binary bundle: an AppImage, an extracted portable archive, or a user-supplied executable. Identified by version + channel + platform + arch. |
| **Channel** | Where a build comes from: `stable`, `weekly`, `legacy` (older supported 1.x stable lines, e.g. 1.0.x), or `custom`. |
| **Profile** | An isolated FreeCAD environment: its own user data, config, macros, addons, and Python packages, bound to one build. |
| **Shared build** | The FreeCAD binary is installed once and reused by any number of profiles; isolation happens through environment variables at launch. |
| **Addon** | A workbench/macro/preference pack/bundle from the official FreeCAD addon catalog. |
| **Addon bundle / collection** | A named, exportable set of addon references that can be applied to a profile in one action. |
| **Macro** | A `.FCMacro` file installed in a profile. |
| **Launcher** | The generated CLI wrapper that starts a profile, or an in-app launch action. |
| **Catalog cache** | Locally cached GitHub release metadata and addon catalog used for offline operation. |
