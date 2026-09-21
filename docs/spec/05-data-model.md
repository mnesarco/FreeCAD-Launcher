# 05 — Data Model

## 1. Principles

- **DB is an index, not the source of truth.** Installed builds, profiles, and addons exist on
  disk; the drift DB indexes them. On startup a reconciler marks entries whose files vanished
  as `missing`/`broken` instead of assuming the DB is right.
- **Fresh start.** No migration from the prototype schema. `schemaVersion = 5`: v1 plus the
  nullable `builds.pythonPath` (D-020), `macros.license`/`macros.sizeBytes` (D-049, v3),
  `installed_addons.pinnedAt` (D-056, v4) and `builds.label` (D-069, v5) columns, all added
  through `onUpgrade` `addColumn`s.
- All timestamps stored as ISO-8601 strings (`store_date_time_values_as_text: true` in
  `build.yaml`, matching `driftRuntimeOptions.defaultSerializer` in `main.dart`).

## 2. Drift schema (v5)

### `builds`

| Column | Type | Notes |
|---|---|---|
| `id` | text (uuid) | PK |
| `kind` | text | `appimage` \| `archive` \| `dmg` \| `custom` |
| `version` | text | e.g. `1.1.3`, `weekly-2026.09.16`, or the label given at custom import |
| `label` | text? | user display name overriding `version` (D-069); never used for update/manifest logic |
| `channel` | text | `stable` \| `weekly` \| `legacy` \| `custom` |
| `platform` | text | `linux` \| `windows` \| `macos` |
| `arch` | text | `x86_64` \| `aarch64`/`arm64` |
| `sourceUrl` | text? | download URL for catalog builds |
| `assetName` | text? | original asset filename |
| `localPath` | text | absolute path to executable/bundle root (user-referenced path or symlink for in-place customs) |
| `sha256` | text? | expected checksum; nullable for custom |
| `verified` | bool | checksum verified at install |
| `pythonVersion` | text? | detected, e.g. `3.11` |
| `pythonPath` | text? | interpreter used for pip (`--target`), detected or user-selected |
| `sizeBytes` | int? | installed size |
| `status` | text | `installed` \| `missing` \| `broken` |
| `releaseNotesUrl` | text? | |
| `installedAt`, `updatedAt` | text | |

Indexes: unique `(platform, arch, channel, version, assetName)`.

### `profiles`

Profile directories are created atomically: the layout is staged in `profiles/<id>.part`,
populated, then renamed to `profiles/<id>`; the DB row is inserted only after the rename and
removed on failure (D-028).

| Column | Type | Notes |
|---|---|---|
| `id` | text (uuid) | PK; directory name `profiles/<id>/` |
| `name` | text | unique case-insensitive |
| `description` | text? | |
| `buildId` | text | FK → `builds.id` |
| `pythonVersion` | text | copied from the build at creation; the build must be installed with a detected Python (D-027); drives pip target dir |
| `iconColor` | int? | UI accent, v0.2 |
| `createdAt`, `updatedAt`, `lastUsedAt` | text | |

### `installed_addons`

| Column | Type | Notes |
|---|---|---|
| `id` | text (uuid) | PK |
| `profileId` | text | FK → `profiles.id`, cascade delete |
| `addonId` | text | catalog id, e.g. `A2plus` |
| `displayName` | text | |
| `gitRef` | text? | chosen branch/tag |
| `version` | text? | from package.xml |
| `installedAt`, `updatedAt` | text | |
| `catalogLastUpdate` | text? | catalog `last_update_time` at install time (update detection) |
| `sourceUrl` | text? | zip URL used |
| `hasRequirements` | bool | |
| `pinnedAt` | text? | frozen version: non-null = pinned (checked per profile+addon row; each profile pins independently) |

Index: unique `(profileId, addonId)`.

### `python_packages`

| Column | Type | Notes |
|---|---|---|
| `id` | text (uuid) | PK |
| `profileId` | text | FK, cascade delete |
| `name` | text | normalized package name |
| `version` | text? | resolved version when known |
| `targetDir` | text | actual `--target` dir used |
| `source` | text | `manual` \| `requirements` \| `addon:<addonId>` |
| `installedAt` | text | |

Index: unique `(profileId, name)`.

### `bundles`

| Column | Type |
|---|---|
| `id` | text (uuid) PK |
| `name` | text unique |
| `description` | text? |
| `createdAt`, `updatedAt` | text |

### `bundle_items`

| Column | Type | Notes |
|---|---|---|
| `bundleId` | text | FK, cascade delete |
| `addonId` | text | catalog id |
| `gitRef` | text? | preferred branch |

PK: `(bundleId, addonId)`.

### `macros` (index of discovered files, optional but enables search/updates)

| Column | Type | Notes |
|---|---|---|
| `id` | text (uuid) PK |
| `profileId` | text | FK, cascade delete |
| `name` | text | file stem |
| `fileName` | text | |
| `source` | text | `catalog` \| `local` |
| `installedAt`, `updatedAt` | text | |
| `catalogCommit` | text? | upstream revision for update checks (v0.2) |

Index: unique `(profileId, fileName)`.

### `catalog_cache`

| Column | Type | Notes |
|---|---|---|
| `key` | text PK | e.g. `github:releases:stable`, `addons:catalog`, `addons:stats` |
| `etag` | text? | conditional GET |
| `lastModified` | text? | |
| `payloadPath` | text | file under `cache/` |
| `fetchedAt` | text | TTL base |
| `status` | text | `ok` \| `stale` \| `error` |

### `settings`

| Column | Type |
|---|---|
| `key` | text PK |
| `value` | text (JSON-encoded) |

Known keys: `theme_mode`, `update_check_interval`, `last_update_check`, `data_dir`,
`github_token_ref` (v0.2; token itself in secure storage, OQ-3), `log_level`,
`cache_retention_days`, `confirm_pip_installs` (default true), `cli_wrapper_path`.

## 3. Filesystem layout

App data root (from `path_provider` `getApplicationSupportDirectory()`):

```
<appSupport>/
  config.db                  # drift
  builds/
    <buildId>/               # extracted archive / dmg app / appimage file
  profiles/
    <profileId>/             # FREECAD_USER_HOME
      user.cfg               # created by FreeCAD on first run
      system.cfg
      Mod/                   # addons
      AdditionalPythonPackages/
        py311/               # 1.0+ target
      home/                  # HOME override
      xdg/{config,data,cache}/
      temp/
      backups/
        config-<ts>/         # config snapshots
        addon-<addonId>-<ts>/# pre-update addon backups
  cache/
    addons/ addon_catalog_cache.zip, stats.json
    github/ releases-*.json
    downloads/ <sha256>
  logs/
    app-<date>.log
    launch-<profile>-<ts>.log
  exports/                   # default export dir (user can pick elsewhere)
```

Rules:

- `builds/<buildId>` and `profiles/<profileId>` are renamed into place atomically from
  `<name>.part` after successful creation.
- A profile directory is fully relocatable only via export/import; absolute paths inside
  `user.cfg` (external tools, macro paths) are detected and reported on import (FR-9.4).
- Data directory is configurable (Settings) but moving an existing root is v0.2.

## 4. Export formats

### 4.1 Bundle JSON

```json
{
  "schema": 1,
  "name": "Mechanical",
  "description": "CAD + FEM essentials",
  "addons": [
    { "id": "A2plus", "git_ref": "master" },
    { "id": "Fasteners", "git_ref": null }
  ]
}
```

Validation on import: `schema == 1`, non-empty name, each `id` exists in the catalog
(warn and keep unresolved entries, marked `unresolved`).

### 4.2 Profile manifest (JSON, portable)

```json
{
  "schema": 1,
  "exported_at": "2026-09-18T10:00:00Z",
  "source": { "os": "linux", "arch": "x86_64" },
  "profile": { "name": "My Profile", "build": "1.1.3", "channel": "stable", "python": "3.11" },
  "addons": [{ "id": "A2plus", "git_ref": "master", "version": "0.4.60", "pinned": true }],
  "python_packages": [{ "name": "numpy", "version": "1.26.4", "source": "requirements" }],
  "bundles": ["Mechanical"],
  "config_files": ["user.cfg", "system.cfg"],
  "config": { "user.cfg": "<?xml …?>", "system.cfg": "<?xml …?>" },
  "macros": ["MyMacro.FCMacro"]
}
```

Notes:

- `build` is a version, not an id; import matches version and channel among installed builds with
  a detected Python, and otherwise lists every usable build in the preview with a warning.
- `python_packages` are reinstalled from the manifest (source recorded; `addon:<id>` rows are
  covered by the addon install), not copied.
- `addons[].pinned` (optional, default false) freezes that addon in the imported profile after
  reinstall; pinning is per profile, so manifests from different profiles may disagree.
- `config` is the optional embedded text of `user.cfg`/`system.cfg` (only these keys, ≤ 4 MiB),
  which makes "config intent" portable without addon payloads. Import writes it, rewrites
  `MacroPath` to the new profile's `Macros/` (D-053), and reports absolute paths found in the
  embedded config (FR-9.4).
- `bundles` lists collections fully contained in the profile's installed addons; import matches
  them by name and reports the missing ones (no bundle creation).
- Import never overwrites: a name clash becomes `<name> (imported)`, then numeric suffixes.
- Full export (`*.zip`) adds `files/` with the listed config/macro/addon payloads by toggle
  (v0.2, B-03).

## 5. Consistency and lifecycle rules

| Event | Rules |
|---|---|
| Delete build | Blocked if any profile references it. Else delete dir + row. |
| Delete profile | Confirm; optionally export; delete dir + cascade addons/packages/macros; launcher wrappers referencing it are flagged and removed on confirmation. |
| Delete addon | Delete `Mod/<id>` + row; never touches catalog cache. |
| Update addon | Back up old dir to `profile/backups/addon-...`; extract new; keep last 3 backups. |
| Build missing on startup | `status = missing`, profiles show warning, launch disabled with "Reinstall build" action. |
| Profile dir missing | Profile marked `missing`; options: recreate empty or delete entry. |
| DB/disk drift | Reconciler runs on startup (cheap directory scans) and after every job. |
| Schema upgrade | drift `MigrationStrategy` with explicit steps; `schemaVersion` bumped and tested. |
