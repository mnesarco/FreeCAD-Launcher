# PLAN — B-18: Home “Recent profiles” row

> **Status**: **implemented** (2026-10-02) on branch `b18-home-recent-profiles`; analyze clean,
> 624 tests green, live pass recorded; PR/CI pending. Owner choices confirmed; tracked as
> **B-18**, decision **D-104** (supersedes D-067's single last-used-card clause).

## Goal

Replace Home's single “Last used profile” card with a top row of up to five recent-profile
cards, each clickable to launch.

## Confirmed UX (owner, 2026-10-02)

- **Set/order**: profiles that have a `lastUsedAt`, newest launch first, at most 5.
- **Empty**: the whole section is hidden when no profile has been used (the first-run checklist
  already covers the no-data state); 1–4 qualifying profiles show 1–4 cards.
- **Card click**: clicking anywhere launches with the existing guards (`launchProfile` in
  `profile_actions.dart`: health guard, macOS quarantine consent, failure snackbar). A chevron
  affordance on the card opens the profile detail.
- **Card content** (compact): name, build display label + channel, last-used timestamp, running
  badge. No addon/package counts, no size, no health chip (unhealthy profiles are hidden).
- **Narrow windows**: fixed-width cards (~220 px) in a horizontally scrollable single row.
- **Unhealthy profiles**: a profile whose build is missing/broken is **hidden** from the row.

## Layout

Home section order becomes:

1. first-run checklist (only when builds/profiles are empty; unchanged);
2. **Recent profiles** — section title + horizontal card row (new; only when non-empty);
3. Updates, News (unchanged).

The old `_SectionTitle(homeLastUsed)` + single `Card`/`ListTile` block is removed, including its
empty branch (“No profiles yet”).

## Behavior

- **Selection** is derived, not persisted: `ProfilesController` gains a
  `late final recentProfiles = computed<List<Profile>>(...)` that reads `profiles` and
  `buildsById`, keeps profiles with `lastUsedAt != null` and
  `buildsById[buildId]?.status == BuildStatus.installed`, sorts by `lastUsedAt` descending and
  takes 5. This reuses the launch guard's health rule and updates automatically on launches,
  DB changes or build status changes.
- **Launching** reuses `launchProfile(context, profile)`; running profiles show the running badge
  and may be launched again (FR-3.4). `HomeView` already tracks `runningProfiles`.
- **Detail shortcut**: `ProfilesViewState` gains a public `openProfile(String id)` (sets
  `_selectedProfileId` via `setState`). `AppShell` passes a callback to `HomeView`
  (`onOpenProfile`) that selects the Profiles section and calls
  `_profilesKey.currentState?.openProfile(id)`, mirroring the existing Ctrl+N flow
  (`app_shell.dart` `_newProfile`). `HomeView.onOpenProfile` is optional so existing
  `const HomeView()` call sites/tests keep compiling; when null the chevron is hidden.

## Files and changes

| File | Change |
|---|---|
| `lib/state/profiles_controller.dart` | `recentProfiles` computed (selection + limit + health filter) |
| `lib/ui/home/home_view.dart` | new `_RecentProfilesRow` + `_RecentProfileCard`; row moved to the top; old last-used block removed; `onOpenProfile` parameter |
| `lib/ui/profiles/profiles_view.dart` | public `ProfilesViewState.openProfile(String id)` |
| `lib/ui/shell/app_shell.dart` | wire `HomeView(onOpenProfile: ...)` via `_profilesKey` |
| `lib/l10n/app_en.arb` + `lib/l10n/gen/**` | add `homeRecentProfiles` (“Recent profiles”), `homeOpenProfile` (“Open profile”, chevron tooltip); reuse `homeLaunch` as the card tooltip/semantic label; remove `homeLastUsed`, `homeNoProfiles`, `homeLastUsedNever` once unused |
| `test/state/profiles_controller_test.dart` | selection/order/limit/health/`lastUsedAt` null |
| `test/ui/home_view_test.dart` | row visibility, order, 5-cap, unhealthy hidden, running badge, launch tap, chevron callback; existing “last used” expectations replaced |
| `docs/spec/03-ux.md` §2.1 | normal-state description updated to the recent row |

Sketch (Home):

```dart
if (recent.isNotEmpty) ...[
  _SectionTitle(title: l10n.homeRecentProfiles),
  SizedBox(
    height: 128,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: recent.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) => SizedBox(
        width: 220,
        child: _RecentProfileCard(
          profile: recent[i],
          build: buildsById[recent[i].buildId],
          running: runningProfiles.contains(recent[i].id),
          onOpenDetail: onOpenProfile == null ? null : () => onOpenProfile!(recent[i].id),
        ),
      ),
    ),
  ),
  const SizedBox(height: 16),
],
```

Card: `Card` + `InkWell(onTap: () => launchProfile(context, profile))`; a trailing
`IconButton(Icons.chevron_right, tooltip: l10n.homeOpenProfile)` opens the detail; the play
semantics/tooltip use `homeLaunch`. Fixed width 220 px, height fills the 128 px row.

## Tests

- Controller: empty when nobody used; only `installed` builds; sorted newest-first; capped at 5;
  profiles with `lastUsedAt == null` excluded.
- Widget (`home_view_test.dart`, seed builds/profiles with distinct `touchLastUsed` values):
  - section hidden when no profile has been used; shown otherwise;
  - card order + at most 5;
  - unhealthy build hidden;
  - running badge renders from `runningProfiles`;
  - tapping a card calls the launch path (inject a fake `FreeCadRuntime`/`ProcessRunner` as in
    `test/state/profiles_controller_test.dart`);
  - chevron invokes `onOpenProfile(id)`.
- Keep the existing stats/updates/news assertions; replace the removed last-used ones.

## Verification

- `flutter analyze` + `flutter test`; `flutter gen-l10n` freshness (generated files committed);
  CI Linux + Windows.
- Live pass (Dart/Flutter MCP + xdotool, per B-17 practice): row at the top with real profiles,
  launch one card (verify running badge/log), chevron opens the detail, resize narrow to confirm
  horizontal scroll, screenshot reviewed; restore any dev-data changes.

## Risks / notes

- Horizontal `ListView` inside the outer Home `ListView` needs a fixed-height `SizedBox`.
- Keeping selection in a computed avoids a new persisted “recent” concept; `lastUsedAt` is
  already written on launch (D-030/M3-05).
- Hiding unhealthy profiles means a build that later goes missing silently drops the card; the
  profile remains reachable from the Profiles section.
- Removing the old empty branch must not affect the first-run state (`builds.isEmpty ||
  profiles.isEmpty`).
- `HomeView` becomes non-const at the AppShell call site; tests keep the const constructor when no
  callback is needed.

## Rollback

Single UI/controller revert; D-104 can be superseded if the owner prefers the old card.

## Refs

`TASKS.md` B-18, `DECISIONS.md` D-104/D-067, `docs/spec/03-ux.md` §2.1,
`lib/ui/home/home_view.dart`, `lib/ui/profiles/{profiles_view,profile_actions}.dart`,
`lib/ui/shell/app_shell.dart`, `lib/state/profiles_controller.dart`,
`test/ui/home_view_test.dart`, `test/state/profiles_controller_test.dart`
