# 05 — Data Model

## 1. Principles

- **DB is an index, not the source of truth.** Installed builds, profiles, and addons exist on
  disk; the drift DB indexes them. On startup a reconciler marks entries whose files vanished
  as `missing`/`broken` instead of assuming the DB is right.
- **Fresh start.** No migration from the prototype schema. `schemaVersion = 1`.
- All timestamps stored as ISO-8601 strings (`store_date_time_values_as_text: true` in
  `build.yaml`, matching `driftRuntimeOptions.defaultSerializer` in `main.dart`).

## 2. Drift schema (v1)

### `builds`

| Column | Type | Notes |
|---|---|---|
| `id` | text (uuid) | PK |
| `kind` | text | `appimage` \| `archive` \| `dmg` \| `custom` |
| `version` | text | e.g. `1.1.3`, `weekly-2026.09.16`, or user label |
| `channel` | text | `stable` \| `weekly` \| `legacy` \| `custom` |
| `platform` | text | `linux` \| `windows` \| `macos` |
| `arch` | text | `x86_64` \| `aarch64`/`arm64` |
| `sourceUrl` | text? | download URL for catalog builds |
| `assetName` | text? | original asset filename |
| `localPath` | text | absolute path to executable/bundle root |
| `sha256` | text? | expected checksum; nullable for custom |
| `verified` | bool | checksum verified at install |
| `pythonVersion` | text? | detected, e.g. `3.11` |
| `sizeBytes` | int? | installed size |
| `status` | text | `installed` \| `missing` \| `broken` |
| `releaseNotesUrl` | text? | |
| `installedAt`, `updatedAt` | text | |

Indexes: unique `(platform, arch, channel, version, assetName)`.

### `profiles`

| Column | Type | Notes |
|---|---|---|
| `id` | text (uuid) | PK; directory name `profiles/<id>/` |
| `name` | text | unique case-insensitive |
| `description` | text? | |
| `buildId` | text | FK → `builds.id` |
| `pythonVersion` | text | copied from build at creation; drives pip target dir |
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
        py311/               # 0.21+ target
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
  "addons": [{ "id": "A2plus", "git_ref": "master", "version": "0.4.60" }],
  "python_packages": [{ "name": "numpy", "version": "1.26.4", "source": "requirements" }],
  "bundles": ["Mechanical"],
  "config_files": ["user.cfg", "system.cfg"],
  "macros": ["MyMacro.FCMacro"]
}
```

Notes:

- `build` is a version, not an id; import matches or asks the user to install a matching build.
- `python_packages` are reinstalled from the manifest (source recorded), not copied.
- Full export (`*.zip`) adds `files/` with the listed config/macro/addon payloads by toggle.

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
