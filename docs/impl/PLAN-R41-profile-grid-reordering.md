# PLAN — R-41: Manual profile ordering (drag & drop grid)

> Status: **done** (2026-10-14) — implemented per the approved options (D-124): long-press
> trigger, `flutter_reorderable_grid_view`, drag disabled while filtering, CLI follows the
> manual order. Verification recorded in `VERIFICATION.md` §R-41; task R-41 DONE.

## Goal

Let the user reorder profile cards in the Profiles grid by drag & drop. The order is persisted
in the DB and becomes the canonical order everywhere profiles are listed. Home "Recent profiles"
stays usage-based (last used), unaffected.

## Current state (analysis)

- Schema is v6 (`lib/data/database.dart:57`); the `profiles` table has no order column
  (`lib/data/tables/profiles.dart`).
- `ProfilesDao.watchAll()`/`getAll()` order by `name ASC` (`lib/data/daos/profiles_dao.dart:13`);
  everything consumes that order: the grid (`ProfilesController.profiles`), the addon/macro
  install-target pickers, the manifest import picker and the CLI `list` (`lib/cli/cli.dart:54`).
- The grid is an Addons-style `GridView.builder` + `_ProfileCard` (R-40/D-123); card tap opens
  the detail, the circular play button launches.
- Profile rows are created only in `ProfilesRepository.create`/`duplicate`; the manifest import
  funnels through `create` (`lib/state/profile_manifest_controller.dart:199`), so "append at the
  end" can be centralized.
- There is no drag-and-drop anywhere in the app and no reorder package in `pubspec.yaml`.
- Access is desktop-only (Linux/Windows/macOS); no touch assumption.

## Proposed design

### 1. Persistence (schema v7)

- Add `sort_order INTEGER NOT NULL DEFAULT 0` (`IntColumn get sortOrder`) to `profiles`.
- Migration v6→v7 via the existing `onUpgrade` chain: add the column, then backfill `0..n-1`
  following today's display order (name) so the upgrade is visually a no-op.
- Queries become `ORDER BY sort_order ASC, name ASC` (name as deterministic tiebreak for
  equal/legacy values).
- `ProfilesDao.saveOrder(List<String> ids)`: one transaction renumbering all rows in the given
  order. The profile count is small (tens), so a full renumber avoids gaps/duplicates and
  fractional-rank complexity.
- `create`/`duplicate` assign `max(sort_order) + 1` so new profiles land at the end.
- The order is presentation-only: **not** exported in manifests (imported profiles append).

### 2. State

- `ProfilesController.reorder(List<String> orderedIds)` applies the new order to the `profiles`
  signal immediately (grid must not snap back while the write completes) and awaits
  `repository.saveOrder`; failures surface like the other profile actions (snackbar).
- The drift watch stream re-emits the same order after the transaction, so no flicker.

### 3. Grid drag & drop — options

**Option A (recommended): `flutter_reorderable_grid_view` 5.7.0** (BSD-3-Clause, verified
publisher, 255 likes / 36.7k downloads; `dart pub add --dry-run` resolves cleanly against the
current lock — adds exactly this package):

- Wraps the existing `GridView.builder` via `ReorderableBuilder.builder`
  (`childBuilder` + `itemCount` + `onReorder`); each card keeps a `ValueKey(profile.id)`.
- Animates displacement and auto-scrolls while dragging to the viewport edge.
- Drag trigger: long-press by default (`longPressDelay`, 500 ms) or immediate with
  `Duration.zero`; `enableDraggable`/`nonDraggableIndices` can disable dragging.
- Requires a `ScrollController` shared with the grid.
- Cost: new dependency + `THIRD_PARTY_NOTICES.md` regeneration (CI drift check) + D-124.

**Option B: custom `LongPressDraggable` + `DragTarget` per cell** — no new dependency, but
hand-rolled hover-index detection, insertion animation and edge auto-scroll; roughly a
package's worth of UI code plus widget tests, higher regression risk.

### 4. Interaction rules

- Reordering is only possible while the search box is empty; with an active query the grid shows
  a filtered subset and positions would not map to the real order → `enableDraggable: false`
  then (or equivalent for the custom option).
- Card tap still opens the detail; the play button and menu keep working (they win the gesture).
- Long-press anywhere on the card starts the drag (the package lifts/scales the card).
- Home recent row, update badges and build grouping are unaffected.
- All profile pickers and CLI `list` follow the manual order automatically (same DAO order).

### 5. Accessibility / discoverability

- Drag is pointer-only (no keyboard reorder). Optional follow-ups (separate requests):
  "Move up/down" entries in the card menu and/or a drag hint. Decide whether a one-line hint
  (e.g., tooltip) ships with this task.

## Test plan

- DAO: `ORDER BY sort_order, name`; `saveOrder` transaction; next-order helper.
- Repository: create/duplicate append at the end; reorder round-trips.
- Controller: `reorder` updates the signal immediately and persists; failure path (snackbar).
- Widget: long-press drag moves the first card to position 2 and persists (TestGesture with
  `pump(longPressDelay)`); dragging is disabled while the query is non-empty; the R-40 grid
  tests stay green.
- Migration: live check v6→v7 on the dev DB (current practice for v3–v6); optionally extract the
  backfill into a pure helper with unit tests.
- `flutter analyze` + full `flutter test`; notice regeneration; live pass incl. app restart.

## Out of scope

- Reordering on Home or other screens; syncing order across machines/manifests; drag between
  sections; multi-select reorder; keyboard reorder (possible follow-up).

## Open questions (owner)

1. **Trigger**: long-press (recommended, no UI change) / immediate drag / explicit "Reorder"
   mode (header toggle)?
2. **Implementation**: package `flutter_reorderable_grid_view` (recommended) / custom widgets.
3. **While searching**: disable dragging (recommended) / something else?
4. **CLI `list`**: follow the manual order (recommended) / keep alphabetical there explicitly?

## Records to update on approval

- D-124 (ordering semantics + interaction + persistence), TASKS R-41 (WIP → DONE), spec 03 §2.3
  (drag to reorder, search disables it), spec 05 (schema v7 + column), STATUS, VERIFICATION,
  `THIRD_PARTY_NOTICES.md`.
