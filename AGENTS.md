# freecad_launcher

Flutter desktop app (Linux/Windows/macOS) that manages FreeCAD builds, isolated profiles,
addons, macros, and per-profile Python packages.

## Repo state — read this first

- The project is a **greenfield v2 rewrite**. The product spec is in `docs/spec/`; the
  implementation plan, task board, and decision log are in `docs/impl/`.
- `lib/` contains the **v2 implementation**. The legacy prototype is frozen at tag
  `prototype-final` and must not be resurrected; v2 work lands on the `v2` branch.
- **Current state lives in `docs/impl/STATUS.md`** (milestone, next action, blockers) — read it
  and `docs/impl/TASKS.md` rather than trusting this file for progress details.
- As of M3 (profiles/launch), the catalog floor is FreeCAD 1.0+ (D-021); custom user binaries
  are unconstrained.

## Persistent context & session protocol (mandatory)

Chat context is disposable; `docs/impl/` is the durable memory. Every session must follow this:

**Start**
1. Read `docs/impl/STATUS.md` (current milestone, next action, blockers).
2. Read the active milestone tables in `docs/impl/TASKS.md`.
3. Read `docs/impl/DECISIONS.md` (all entries; they are short).
4. Read only the spec sections referenced by the task.
5. Confirm scope with the user, then mark task(s) `WIP` in `TASKS.md`/`STATUS.md`.

**During**
- One milestone at a time; only planned tasks. New requests get added to `TASKS.md` first.
- Any architecture/UX/data/integration choice not already covered must be asked about and
  recorded in `docs/impl/DECISIONS.md` before implementing.
- Keep `flutter analyze` and `flutter test` green; run `build_runner` after drift changes.

**End**
1. Run the matching verification in `docs/impl/VERIFICATION.md`.
2. Update task statuses (`DONE` only if acceptance criteria are verified), append decisions,
   update `STATUS.md` including a session-log row.
3. Commit only when the user approved, using `<type>(<scope>): <summary> [M#-##]`.

## Commands

```sh
flutter pub get                                            # install deps
dart run build_runner build --delete-conflicting-outputs   # drift codegen
flutter analyze                                            # lint (flutter_lints)
flutter test                                               # tests
flutter run -d linux                                       # run on Linux
flutter build linux                                        # production bundle
```

## v2 architecture (authoritative details in docs/spec/04-architecture.md)

- **State**: `signals_flutter` (signals + streamSignal), NOT Provider/Riverpod/Bloc.
  Controllers live in `state/`, created once in `AppServices` and exposed via `AppScope`.
- **Layering**: `ui/` → `state/` → `domain/` (pure Dart) → `data/` (drift, repositories,
  catalog clients) and `platform/` (process, extraction, checksums, diagnostics, paths).
  `domain/` must not import `ui/`, `state/`, `data/`, or `platform/`.
- **Drift**: schema v2 with `builds` (incl. `pythonPath`), `profiles`, `installed_addons`,
  `python_packages`, `bundles`, `bundle_items`, `macros`, `catalog_cache`, `settings`. DB is an
  index over the filesystem; a reconciler marks missing/broken entries.
- **Builds**: catalog installs are managed copies; user-supplied executables and local
  AppImages are referenced in place (executable paths, symlinks) per D-020/D-023.
- **Isolation**: shared build + per-profile `FREECAD_USER_HOME` (see decision D-005).
- **Launch**: pure `LaunchPlanBuilder` (executable + argv + env) executed by `FreeCadRuntime`;
  `ProfilesController` guards build health, tracks running launches and writes per-launch logs
  (D-029..D-031).
- **Python**: bundled interpreter + `pip install --target <profile>/AdditionalPythonPackages/pyXY`
  (decision D-006). Never touch system Python.
- **Protocol**: never shell out with interpolated strings; `ProcessRunner` takes argument arrays.

## Legacy prototype (frozen — reference only)

- The prototype exists only at tag `prototype-final`; `lib/` no longer contains its code.
- Old `MainController` + `FlatpakService`/`SnapService`/`ExecutableService` are pre-v2 and out
  of scope. Old drift tables (`Apps`, `Profiles`, `Launchers`, `DownloadedAddons`) are
  discarded; no migration (decision D-009).
- `addon_index_spec.md` (repo root) documents the addon catalog format and **remains valid**
  for v2; it is referenced by `docs/spec/06-integrations.md` §2.

## Style conventions

- Line length: **100** (`.vscode/settings.json` sets both editor and `dart lineLength`).
- Generated files (`*.g.dart`) are committed; never hand-edit them.
- No comments unless they explain non-obvious "why"; all user-facing UI strings go through
  `AppLocalizations` (decision D-017).
