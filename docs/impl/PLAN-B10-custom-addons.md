# PLAN B-10 — Custom addon installs (repository URL, local archive, dev symlink)

> **Status**: Planned — no code yet. Target: backlog `B-10` (v0.2). Created 2026-10-01.
> The choices below were confirmed by the owner in the planning session; they become decisions
> D-085..D-088 when implementation starts (see *Decisions to record*).

## Goal

Let users install an addon into a profile from three non-catalog sources, on top of the existing
official-catalog flow:

1. **Repository URL + branch/ref** — clone-free install from a Git host archive.
2. **Local/downloaded archive** — install a zip/tar the user already has (FR-4.8, B-10).
3. **Local directory symlink** — live-link a working copy for addon development.

The custom installs must be recorded with their provenance, removable without touching source
data, and must never conflict silently with catalog installs.

## Confirmed choices (owner answers, 2026-10-01)

| Topic | Choice |
|---|---|
| UI entry | New **Custom** tab in the Addons screen (Catalog \| Collections \| Custom), mirroring Versions → Custom |
| Repo sources | Native URL patterns for GitHub, GitLab, Gitea/Codeberg; direct `.zip`/`.tar.gz` URLs also accepted |
| Metadata | `package.xml` **required** at the addon content root; missing/invalid → install rejected |
| Updates | Repo installs get an **Update** action; zip gets **Reinstall from file**; symlink is **live** (no update) |
| Symlink fallback | **Hard-fail** when symlinks cannot be created (no silent copy) |
| Conflicts | Fresh install with an existing id (DB row or existing `Mod/<id>`) is **blocked until removed** |
| Bundles/manifest | **Not round-tripped**: custom addons stay out of bundle pickers; manifest import skips/warns (see §9) |

## Current state (baseline)

- Catalog installs: `AddonsController.install` (`lib/state/addons_controller.dart:426`) →
  `_installInternal` (`:463`) downloads `branch.zipUrl`, calls `AddonInstaller.install`
  (`lib/platform/addon_installer.dart:40`) which downloads via `Downloader`, extracts with
  `SafeArchiveExtractor` (`lib/platform/archive_extract.dart:31`), strips a single archive root
  (`_contentRoot`, `:102`), stages to `Mod/<id>.part` and atomically renames with a `.old`
  backup, then upserts an `installed_addons` row.
- Requirements: the catalog supplies `requirements.txt` text; the UI shows the consent dialog
  (`lib/ui/addons/requirements_dialog.dart`) *before* install, and `_installRequirements`
  (`:535`) runs pip after placement.
- Update detection: `isUpdateAvailable` (`:302`) and `UpdatesController.outdated`
  (`lib/state/updates_controller.dart:59`) compare catalog timestamps/versions; pinned rows are
  skipped, non-catalog rows are not (only `byId == null` skips).
- Remove: `AddonsController.remove` (`:381`) deletes the directory recursively + DB row (would
  follow/delete a symlink target — must change).
- Table: `lib/data/tables/installed_addons.dart` (unique `{profileId, addonId}`, schema v5 in
  `lib/data/database.dart:57`).
- UI: `AddonsView` has Catalog and Collections tabs; `AddonDetailView` resolves addons from the
  catalog only. Profile detail Addons tab (`lib/ui/profiles/profile_detail_view.dart:304`) lists
  rows with pin and (catalog-only) update badges.
- Manifest: `ManifestAddon` (`lib/domain/profiles/profile_manifest.dart:30`) exports every row
  and import reinstalls catalog ids (`lib/state/profile_manifest_controller.dart:215`).
- Symlink precedent: D-023 (builds referenced in place; remove deletes only the link).

## Scope

### In

- Schema v6 provenance columns + migration.
- Domain helpers: package.xml parsing reuse, addon id rules, archive URL builder.
- `AddonInstaller`: local-archive entry point and directory linking; link-safe removal.
- `AddonsController`: three custom install flows, repo update, zip reinstall, conflict blocking,
  source-aware update guards, source-aware remove.
- Addons → Custom tab UI (three forms + custom-install list + actions).
- Profile Addons tab source chip.
- Requirements consent reused before placement for all three sources.
- Manifest export `source` marker + import skip with warning; bundle pickers unchanged.
- Tests, docs, decisions, verification.

### Out (documented limitations)

- Private-repo authentication (waits for B-07 token support).
- Writing package.xml or converting legacy addons (package.xml required).
- package.xml `<icon>` rendering for custom addons (generic icon in this increment).
- FreeCAD-range warnings for custom installs (FR-4.9, separate v0.2 task).
- Bundle/manifest round-trip of custom addons (they are not reinstallable from JSON).
- Addon filesystem reconciler (a symlink whose target disappears stays "installed" until
  removed; optional follow-up).
- CLI subcommands (B-09).

## Design

### 1. Data model (schema v6)

`installed_addons` gains:

| Column | Type | Notes |
|---|---|---|
| `source` | `TEXT NOT NULL DEFAULT 'catalog'` | `catalog` \| `repo` \| `zip` \| `symlink` |
| `sourcePath` | `TEXT NULL` | local archive path or symlink target |

- `sourceUrl` semantics: catalog zip URL (unchanged) or repository URL for `repo`.
- `gitRef`: branch/ref for `repo` and catalog; null for zip/symlink.
- Migration v5→v6 adds both columns with defaults; existing rows become `catalog`.
- Domain enum `AddonSource` in `lib/domain/addons/addon_source.dart`; DB stores `.name`.
- `build_runner build --delete-conflicting-outputs` after the table change.

### 2. Domain (pure, no IO)

- `lib/domain/addons/package_xml.dart` — extract the XML parsing currently in
  `addon_catalog_parser.dart:110` (`_parseMetadata`) into `parsePackageXml(String)` returning
  name/description/version/license/tags/people/content/minPython; the catalog parser is
  refactored to reuse it (existing tests are the regression net).
- `lib/domain/addons/addon_id_rules.dart` — trim, reject empty/`.`/`..`, path separators and
  control characters, cap 64 chars, keep case (`A2plus`); helpers `addonIdFromRepoUrl`,
  `addonIdFromArchive` (single root dir name, else archive filename stem), `addonIdFromDirectory`
  (basename).
- `lib/domain/addons/repository_archive.dart` — `archiveUriFor(repoUrl, ref)`:
  - GitHub: `https://github.com/{owner}/{repo}/archive/{ref}.zip` (works for branches and tags)
  - GitLab: `https://gitlab.com/{path}/-/archive/{ref}/{name}-{ref}.zip`
  - Gitea/Forgejo/Codeberg: `https://{host}/{owner}/{repo}/archive/{ref}.zip`
  - Direct archive URL (path ends `.zip`/`.tar.gz`/`.tgz`): passthrough, `ref` optional
  - Normalize trailing `/` and `.git`; reject non-`http(s)`; unknown host → typed error telling
    the user to paste a direct archive URL.

### 3. Platform

`lib/platform/addon_installer.dart`:

- Split `install()` into download → `installFromArchive({archivePath, destinationDirectory,
  cancellationToken})` with the existing staging/`_contentRoot`/atomic rename/`.old` logic
  shared verbatim.
- `linkDirectory({sourceDirectory, destinationDirectory})` — create the link at
  `<destination>.part` (`Link(...).createSync(target)`), rename into place; any failure throws
  (no copy fallback).
- `isLink(path)` helper for the controller.
- `lib/platform/addon_manifest_reader.dart`:
  - `readPackageXml(directory)` → parsed metadata or `AddonInstallException`.
  - `readRequirementsFromArchive(archivePath)` (zip/tar, root or single subdir) and
    `readRequirementsFromDirectory(directory)` so requirements consent happens *before*
    placement/linking.

### 4. State (`AddonsController`)

Public API:

- `installFromRepository({repoUrl, gitRef, profileId, onRequirements})`
- `installFromZip({archivePath, profileId, onRequirements})`
- `installFromDirectory({sourcePath, profileId, onRequirements})`
- `updateFromRepository({addonId, profileId})`
- `reinstallFromZip({addonId, profileId, archivePath})`

Shared `_installCustom`:

1. Wrap in `JobsController.run(kind: install)` (progress + cancel + retry), like catalog installs.
2. Validate profile; derive/resolve destination id; **conflict block**: if a row exists for the
   id or `Mod/<id>` exists on disk → typed error "remove it first".
3. Obtain content: download (repo), use file (zip), or read target (symlink).
4. Require `package.xml` at the content root; parse metadata.
5. Peek requirements; if any, call the UI-provided `onRequirements` callback to show the existing
   consent dialog (Cancel aborts with no changes; "addon only" proceeds without pip).
6. Commit atomically (extract/rename or link), upsert the row with `source`, `sourcePath`/
   `sourceUrl`, `gitRef`, `version`, `catalogLastUpdate: null`, `hasRequirements`.
7. If packages were accepted, run the existing pip step (refactor `_installRequirements` to take
   `addonId` + requirements text instead of catalog `Addon`/`AddonBranch` objects).

Update/remove guards:

- `isUpdateAvailable` returns false unless `installed.source == catalog`; same guard in
  `UpdatesController.outdated`.
- `updateFromRepository`: pinned blocks; backup via existing `_backupAddon`; re-resolve archive
  from stored `sourceUrl` + `gitRef`; re-derive id and fail if it no longer matches `addonId`;
  replace; refresh row version/requirements.
- `reinstallFromZip`: same, from a newly picked file; `sourcePath` updated.
- `remove`: if `FileSystemEntity.isLinkSync(Mod/<id>)` → delete the link only (never the target);
  otherwise recursive delete as today; then delete the row.

### 5. UI

`lib/ui/addons/addons_view.dart` — add a third tab **Custom** (`Catalog | Collections | Custom`)
containing, top to bottom:

1. **Repository form** — repository URL, branch/ref, target profile, resolved-archive preview,
   Install. Inline validation (URL shape, required ref unless direct archive, unsupported host).
2. **Archive form** — `file_selector` file picker (`.zip`, `.tar.gz`, `.tgz`), target profile,
   Install.
3. **Local folder form** — directory picker, target profile, warning that the link is live and
   that removing the addon deletes only the link, Install.
4. **Custom installs list** — rows: display name, source chip (`Repository`/`Zip`/`Dev link`),
   version, target profile, actions Update (repo only), Reinstall from file (zip only), Remove
   (all), Reveal target (symlink). Empty and error states per M6-07 conventions.

`lib/ui/profiles/profile_detail_view.dart:304` — add the source chip to installed rows. No new
actions there (custom actions live in the Custom tab).

Forms use the shared D-059 `FormRow`/`FormTextField`/`FormDropdown` widgets. Requirements consent
reuses `showRequirementsConsentDialog`.

### 6. Update / remove semantics

| Source | Update action | Remove | Live edits |
|---|---|---|---|
| catalog | catalog update (unchanged) | dir + row | n/a |
| repo | re-fetch stored URL+ref, backup, refresh metadata | dir + row | no |
| zip | Reinstall from file, backup, refresh metadata | dir + row | no |
| symlink | none (live link) | link only | yes, immediately |

Pin still applies to all sources (pinned rows are skipped by update flows; repo update requires
unpinning, matching catalog semantics).

### 7. Requirements consent flow

The catalog flow asks before placement because the catalog carries the requirements text. Custom
sources have it only after fetching content, so the flow becomes:

1. Download/extract (repo/zip) or read target (symlink) to staging/target **without committing**.
2. Read `requirements.txt` (root or single subdir).
3. UI consent dialog via the injected `onRequirements` callback.
4. Commit placement/link, then pip if accepted (failure is reported per addon, as today).

### 8. Security and edge cases

- Archives go through `SafeArchiveExtractor` unchanged (zip-slip, symlink entries, size/entry
  caps, drive-letter paths rejected).
- `package.xml` must be at the content root after single-root stripping; flat multi-root archives
  are rejected with a clear message.
- Addon ids are validated before any path join; destination is always `Mod/<id>` inside the
  profile.
- Symlink: target must exist and be a directory; reject the profile's own `Mod` directory or a
  path nested under the destination; hard-fail on `Link.createSync` errors (Windows privileges).
- Repo URLs must be `http(s)`; download failures (404/private) surface as actionable errors.
- Conflict blocking covers both the DB row and an orphaned `Mod/<id>` directory.
- Profile size already walks with `followLinks: false` (`profiles_controller.dart:161`), so
  symlinked content is not counted twice.

### 9. Bundles and manifest

- Bundles: no changes — the item picker searches the catalog, so custom addons are naturally
  absent.
- Manifest (small hardening): export adds `"source": "<value>"` to addon entries; import skips
  non-`catalog` entries and reports them in the summary ("N custom addons were not reinstalled").
  Without this, a custom addon whose id matches a catalog addon would silently import the catalog
  version. `ManifestAddon` gains an optional `source` (codec schema stays version 1, additive).
- Documented in the user guide and spec 05 §4.2.

### 10. i18n

New keys in `lib/l10n/app_en.arb` (run `flutter gen-l10n` afterwards; generated `lib/l10n/gen/**`
is committed), roughly: `addonsTabCustom`, `addonsCustomRepo*`, `addonsCustomZip*`,
`addonsCustomDir*`, `addonsCustomSourceRepo/Zip/Link`, `addonsCustomConflict`,
`addonsCustomPackageXmlMissing`, `addonsCustomUnsupportedHost`,
`addonsCustomReinstall`, `addonsCustomReveal`, `addonsCustomLiveWarning`,
`addonsCustomInstallFailed`, `manifestAddonsCustomSkipped`.

## Tests

| Area | File | Coverage |
|---|---|---|
| Archive URL builder | `test/domain/addon_archive_url_test.dart` (new) | github/gitlab/gitea/direct/unknown, `.git`/trailing slash, tags, invalid schemes |
| Id rules | `test/domain/addon_id_rules_test.dart` (new) | repo/archive/dir derivation, invalid chars, traversal, length |
| package.xml | existing catalog parser tests + `test/domain/package_xml_test.dart` (new) | refactor regression, missing/invalid XML |
| Installer | `test/platform/addon_installer_test.dart` (extend) | `installFromArchive` root stripping + atomic replace/backup, `linkDirectory` failure, requirements peek from zip/tar |
| Controller | `test/state/addons_controller_test.dart` (extend) | source fields persisted, conflict block, missing package.xml, repo update + pin block, zip reinstall, custom rows excluded from `outdated`, symlink remove preserves target |
| UI | `test/ui/addons_custom_tab_test.dart` (new) | form validation, unsupported host, conflict error, empty/list states |

Existing catalog install/update tests must stay green after the installer and parser refactors.

## Manual verification (Linux)

1. Install a real GitHub-hosted workbench by URL + branch; it appears in `Mod/<id>` and loads in
   FreeCAD 1.0.2.
2. Install the same addon from a locally zipped clone (flat and single-root variants).
3. Symlink a local clone: edit a file, confirm the profile sees the edit without reinstalling;
   remove the addon and confirm the clone is untouched.
4. Attempt a second install with an existing id → blocked with a clear message.
5. Update a repo install after a new commit; confirm backup in `backups/` and refreshed version.
6. Missing `package.xml`, bad zip, unknown host, private repo → actionable errors, no leftovers.
7. Manifest export/import: custom entries are skipped with a count; catalog entries round-trip.
8. `flutter analyze`, `flutter test`, `build_runner` clean; app launches.

## Docs to update (with the code)

- `docs/spec/02-requirements.md`: FR-4.8 rewritten (zip/tar), new FR-4.11 (repo URL) and FR-4.12
  (dev symlink) at v0.2; conflict and package.xml rules.
- `docs/spec/03-ux.md` §2.4: Custom tab.
- `docs/spec/05-data-model.md`: `installed_addons.source`/`sourcePath`, schema v6, manifest
  `source` marker.
- `docs/spec/06-integrations.md` §2: custom-source integration rules (URL patterns, package.xml,
  removal semantics).
- `docs/user-guide.md`: custom installs section + limitations.
- `docs/impl/VERIFICATION.md`: new manual rows.
- `docs/impl/DECISIONS.md`: D-085..D-088 (below).
- `docs/impl/STATUS.md` + `TASKS.md`: statuses and session log.

## Decisions to record at kickoff

- **D-085** — Custom addon provenance: `source`/`sourcePath` columns (schema v6), source-aware
  update guards, conflict policy (block until removed).
- **D-086** — Custom source resolution: package.xml required, id derivation rules, supported
  repository hosts and archive URL patterns.
- **D-087** — Dev symlink semantics: hard-fail without symlink support, link-only removal, live
  edits, no update action.
- **D-088** — Custom update policy: repo update / zip reinstall / symlink live; excluded from
  catalog update checks; not in bundles; manifest exports a `source` marker and import skips
  non-catalog entries.

## Implementation order

1. **B-10a Foundations** — schema v6 + migration, domain helpers, installer split + linking,
   requirements reader, source-aware guards; unit/platform tests.
2. **B-10b Repository URL install + update** — controller, conflict block, Custom tab repo form,
   l10n, widget/controller tests.
3. **B-10c Local archive install + reinstall** — file picker, zip/tar, form + list actions, tests.
4. **B-10d Dev symlink install** — link flow, live warning, link-only remove, tests.
5. **B-10e Verification + docs** — real installs in FreeCAD, spec/user-guide/verification
   updates, final green run.

Each step lands with `flutter analyze` + `flutter test` green and, for schema changes,
regenerated drift/l10n output committed.
