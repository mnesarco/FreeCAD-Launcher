# PLAN — Signals implicit-tracking migration (post-B-16)

> **Status**: **done** (2026-10-02). P0/R-23, P1 (dependency group merged), P2 (all four
> batches) and the local P3 checks are complete; only the B-17 PR CI and the packaging smoke
> (B-16 Phase 3) remain. Adopting this plan is **D-101**; it is tracked as **B-17** and belongs
> to the B-16 dependency-upgrades work.

## Goal

Remove the deprecated `FlutterReadonlySignalUtils.watch(context)` / `Watch` API from the UI and
adopt the signals_flutter 7.1 implicit-tracking widgets, ending with zero
`deprecated_member_use` diagnostics and no behavior regressions.

Target API:

- whole-widget tracking → `SignalWidget` (stateless) / `SignalStatefulWidget` (stateful);
- localized, surgical scopes → `SignalBuilder` (`SignalAnimatedBuilder` when a cached `child`
  is useful);
- no `Watch` (it is deprecated in 7.1.0 too, despite the `.watch` deprecation message mentioning
  it), no `.watch(context)`.

## Why this is *not* the fix for R-23 (read before starting)

The R-23 error (`SignalEffectException` building `TabBarView`) is caused by **writing a watched
signal during the build/layout phase**, not by the deprecated API. Verified 2026-10-02 with a
throwaway `TabBarView` test (watcher tab + writer tab writing in `didChangeDependencies`):

- with `.watch(context)`: `SignalEffectException` → inner
  `setState() or markNeedsBuild() called during build`;
- with `SignalStatefulWidget` implicit tracking: **identical exception**;
- with `SignalWidget` implicit tracking: **identical exception**.

Root cause: signals_flutter 7.1 subscriptions are effects that call `el.markNeedsBuild()`
directly (`SignalElement`/`SignalStatefulElement.watchSignal`, `src/widgets/*.dart:57-64`). The
6.3.1 `ElementWatcher.rebuild()` awaited `SchedulerBinding.endOfFrame` when the scheduler was not
idle; 7.1 dropped that deferral. So the invariant below survives any subscription API and is a
hard rule for this migration:

> **Never write a signal watched by widgets from `build`, `didChangeDependencies`,
> `initState`, layout callbacks, or any other point inside a frame.** Defer the write
> (post-frame callback, microtask after an `await`, user event, or async completion).

## Scope (measured 2026-10-02, working tree at `signals_flutter` 7.1.0)

- **127** `.watch(context)` call sites in **16 UI files + `app.dart`**, in **34 widget classes**;
  `flutter analyze` reports one `deprecated_member_use` per site.
- Rebuildable in place today (no logic change needed): the call sites are direct reads in
  `build` methods (or helpers called from them); no `ListView.builder`/`LayoutBuilder`/dialog
  closure reads were found in `lib/ui`.

| File | Sites | Classes |
|---|---|---|
| `lib/ui/addons/addons_view.dart` | 22 (incl. 2 multi-line) | 3 |
| `lib/ui/addons/collections_view.dart` | 16 | 5 |
| `lib/ui/macros/macros_view.dart` | 14 | 3 |
| `lib/ui/settings/settings_view.dart` | 13 | 1 |
| `lib/ui/home/home_view.dart` | 12 | 1 |
| `lib/ui/profiles/profile_detail_view.dart` | 11 | 4 |
| `lib/ui/builds/builds_view.dart` | 10 | 5 |
| `lib/ui/updates/updates_summary_sheet.dart` | 9 | 1 |
| `lib/ui/profiles/profiles_view.dart` | 9 | 2 |
| `lib/ui/shell/app_shell.dart` | 2 | 2 |
| `lib/ui/profiles/config_snapshots_view.dart` | 2 | 2 |
| `lib/ui/macros/installed_macros.dart` | 2 | 1 |
| `lib/ui/addons/custom_addons_view.dart` | 2 | 1 |
| `lib/ui/updates/updates_status_chip.dart` | 1 | 1 |
| `lib/ui/jobs/jobs_dialog.dart` | 1 | 1 |
| `lib/app.dart` | 1 | 1 |

## API mapping

| Situation | Target | Notes |
|---|---|---|
| `class X extends StatelessWidget` reading signals in `build` | `extends SignalWidget` | replace `s.watch(context)` with `s.value` |
| `class X extends StatefulWidget` + `State<X>` reading signals in `build` | widget `extends SignalStatefulWidget`; keep `State<X>` | the element swap does the tracking; `State` mixins (`AutomaticKeepAliveClientMixin`, `SingleTickerProviderStateMixin`, …) keep working |
| large build watching many signals | keep the whole-widget form | rebuild granularity is unchanged: `.watch(context)` already rebuilt the element that called it |
| small leaf (tile/card/chip) or a read that must not rebuild its parent | `SignalBuilder(builder: (context) => …)` | implicit read inside the builder callback; optional `dependencies:` |
| `Watch` / `Watch.builder` used anywhere later | `SignalBuilder` / `SignalAnimatedBuilder` | `Watch` is deprecated in 7.1.0 |

## Hard rules and traps

1. **No signal writes during a frame** (see above). R-23 is the reference incident.
2. Only signals read **synchronously during the widget's own `build`** are tracked. Reads in
   `initState`/`didChangeDependencies`, event handlers, futures and lazily invoked closures
   (`itemBuilder`, `LayoutBuilder`, dialogs) are *not* tracked — wrap the actual reading widget
   in `SignalBuilder` or move the read into a real widget's `build`. Implicit tracking also
   **drops subscriptions the latest build no longer reads**, unlike the old sticky `watch()`
   extension: a child must track its own reads instead of relying on a parent's stale
   subscription (B-17c: `BundleDetailView`, whose parent early-returns before reading
   `bundles`/`items`).
3. `SignalWidget.build` reads must stay direct (`.value`); `peek()`/`.get()`/`call()` do not
   register with `onSignalRead`.
4. Audit that each removed `.watch(context)` used the widget's own build context; a different
   context would have changed the rebuild target. (Current tree: all use the build `context`.)
5. Do not combine this migration with dependency bumps, feature work or release commits (B-16
   rule).
6. Keep `flutter analyze` free of `deprecated_member_use` after each batch; the repo-level
   `signals_lint` legacy-plugin warning (`analysis_options_deprecated_plugins`) is unrelated.

## Phases

### P0 — unblock signals 7.1 (R-23) — done in this session

- [x] Defer `ProfilesController.refreshConfigSnapshots` at the Config/Backups tab mount points
      (post-frame callback) so the first-view refresh no longer writes during build.
- [x] Widget regression test: first visit Config → then Backups does not throw (fails on the old
      code with the exact `SignalEffectException`).

### P1 — land the B-16 signals group (upgrade stabilization)

- [x] Landed 2026-10-02 as `2b2cdf7` (`[dep] upgrade signals_flutter`; 6.3.1 → 7.1.0,
      `signals_core`/`preact_signals` 7.0.0). `signals_lint` is intentionally **not** included:
      7.1.0 (latest) caps `analyzer <14` and would downgrade the toolchain (D-102).
      Verified: `build_runner` codegen fresh, 615 tests green, analyze has only the 127 `.watch`
      deprecations, and a live click-through (Home, Profiles + all six tabs including the R-23
      Config → Backups path, Versions Installed/Available/Custom, Addons
      Catalog/Collections/Custom, Macros Installed/Catalog, Settings) with zero runtime errors
      and a successful hot reload.
- [x] Only after P1 is stable (green CI + live pass), start P2. PR #2 was green on run
      37047738009 (Linux + Windows) and merged to `devel` (`393a841`); P2 ran 2026-10-02.

### P2 — migration batches (one commit each)

| Batch | Files | Sites | Status |
|---|---|---|---|
| B-17a small files | `app.dart`, `app_shell`, `jobs_dialog`, `updates_status_chip`, `config_snapshots_view`, `installed_macros`, `custom_addons_view` | 11 | [x] `6c9f375` |
| B-17b profiles/builds/home | `profiles_view`, `builds_view`, `profile_detail_view`, `home_view` | 42 | [x] `f2c24ee` |
| B-17c addons/macros | `addons_view`, `collections_view`, `macros_view` | 52 | [x] `8009cfc` |
| B-17d settings/updates + verification | `settings_view`, `updates_summary_sheet` | 22 | [x] `9233ad3` |

### P3 — verification and cleanup

- [x] `flutter analyze` has zero `deprecated_member_use` and reports **No issues found**;
      `grep -rn "\.watch(context\|Watch(" lib` returns nothing.
- [x] `flutter test` green (Linux, 615 tests) and CI green on Linux + Windows — PR
      [#3](https://github.com/mnesarco/FreeCAD-Launcher/pull/3), run 37058324255.
- [x] `flutter analyze` default strictness restored (the `--no-fatal-infos` bridge is removed
      from `ci.yml`).
- [x] Live click-through per `PLAN-dependency-upgrades.md` risk table: Home, Profiles (all six
      tabs incl. Config → Backups), Versions (Installed/Custom/Available), Addons
      (Catalog/Custom/Collections + detail + Add-addon dialog), Macros (Installed/Catalog),
      Settings plus a live dark↔light theme switch; zero runtime errors (Jobs dialog not
      exercised — no active jobs).
- [ ] Packaging smoke: AppImage `--version` + GUI, Windows job smoke (deferred to B-16 Phase 3).
- [x] Update `STATUS.md`/`TASKS.md`; B-17d/B-17 are DONE (PR #3 CI green; merge on owner
      approval).

## Per-batch procedure

1. Pick one batch (keep the diff mechanical).
2. Convert classes and `.watch(context)` → `.value` (or `SignalBuilder` where the scope should
   stay local).
3. `flutter analyze` — batch introduces no new diagnostics.
4. `flutter test` (or the affected `test/ui/*_view_test.dart` + full suite before commit).
5. Live check the touched screen(s) with the Dart/Flutter MCP (`launch_app` + driver tools).
6. Update the checkbox table and `STATUS.md`; commit only with owner approval.

## Rollback

- One commit per batch; `git revert` the batch. The dependency-only upgrade commit (P1) is
  independent, so reverting P0/P2 does not touch `pubspec.*`.
- If implicit tracking causes a subtle rebuild regression in a screen, keep that file on
  `.watch(context)` and record the blocked file in `TASKS.md` B-17 rather than mixing a redesign
  into the migration.

## Resume protocol

1. Read this plan, `STATUS.md`, `TASKS.md` B-17, `DECISIONS.md` D-101.
2. `git status` must be clean; start from the first unchecked batch.
3. Run the per-batch procedure; `graphify update .` at the end of the session.

## Refs

`TASKS.md` B-16/B-17/R-23, `docs/impl/DECISIONS.md` D-101,
`docs/impl/PLAN-dependency-upgrades.md` (signals group), `pubspec.yaml`,
`lib/ui/profiles/config_snapshots_view.dart` (R-23 fix), signals_flutter 7.1.0:
`src/widgets/signal_widget.dart`, `src/widgets/signal_stateful_widget.dart`,
`src/widgets/signal_builder.dart`, `src/extensions/signal.dart`.
