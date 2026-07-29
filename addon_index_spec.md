# Addon Catalog Cache File Format

**Source**: `https://addons.freecad.org/addon_catalog_cache.zip` — a ZIP containing a single `addon_catalog_cache.json` file.

**Role**: The catalog of all installable FreeCAD addons (workbenches, macros, preference packs, bundles). Parsed by `lib/model/addons.dart`.

---

## Top-level Structure

A JSON object mapping **addon IDs** (strings) to **arrays of branch entries**. Meta/schema keys starting with `_` or `$` are ignored by the parser.

```json
{
  "<addon_id>": [{ ...branch_entry... }, ...],
  ...
}
```

- 168 addons, 176 total entries (8 addons have 2 branches each).
- Addon IDs are unique, human-readable slugs (e.g. `"A2plus"`, `"AddonManager"`, `"animation"`).

---

## Branch Entry Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `repository` | string | yes | Full URL to the repo (GitHub, Codeberg, etc.) |
| `git_ref` | string | yes | Branch or tag name (e.g. `"master"`, `"main"`, `"v3.3.0"`) |
| `branch_display_name` | string | yes | Human-readable label for the branch (e.g. `"master"`, `"development"`, `"Pre-1.0 Compatible"`) |
| `zip_url` | string | yes | Download URL for the archive (e.g. `https://github.com/.../archive/refs/heads/master.zip`) |
| `curated` | boolean | yes | Whether the addon is officially curated (`true` for all current entries) |
| `sparse_cache` | boolean | yes | Whether the cached file is a sparse download (`false` for most) |
| `relative_cache_path` | string | no | Path relative to the CDN base (e.g. `"./CatalogCache/A2plus/0-master.zip"`). Combined with `mainConfig.addonsDownloadBaseUrl` to form the download URL. |
| `freecad_min` | string\|object\|null | no | Minimum FreeCAD version required. See [Version Encoding](#version-encoding). |
| `freecad_max` | string\|object\|null | no | Maximum FreeCAD version supported. Same encoding as `freecad_min`. |
| `last_update_time` | ISO 8601 string\|null | no | Last commit/update timestamp (e.g. `"2026-02-15T17:12:54+01:00"`). |
| `note` | string\|null | no | Optional human-readable note (e.g. `"Community-friendly fork of the original..."`). |
| `metadata` | object\|null | no | Embedded package metadata (see below). Present on 133/176 entries. |

---

## Version Encoding

The `freecad_min` / `freecad_max` fields can be:

1. **`null`** — no version constraint.
2. **A string** — e.g. `"0.19"`.
3. **An object** with a `version_as_list` key:
   ```json
   { "version_as_list": [0, 20, 1, ""] }
   ```
   Parsed by joining non-empty elements with `"."` → `"0.20.1"`.

---

## Metadata Object

Embedded inside each branch entry when available (133 of 176 entries). Contains parsed package metadata and raw auxiliary files.

| Field | Type | Description |
|-------|------|-------------|
| `package_xml` | string | The full `package.xml` content as an XML string. Follows the FreeCAD Package Metadata format (`https://wiki.freecad.org/Package_Metadata`). Contains `<name>`, `<description>`, `<version>`, `<date>`, `<license>`, `<maintainer>`, `<author>`, `<url>`, `<icon>`, `<content>`, `<depend>`, `<tag>`, `<pythonmin>`, `<freecadmin>` elements. |
| `icon_data` | string\|null | Base64-encoded icon bytes (SVG or PNG). Guessed as SVG if decoded bytes start with `<?xml`, `<svg`, or `<!`. |
| `metadata_txt` | string | Legacy `metadata.txt` content (INI-like format). Empty string if absent. Only 18 entries have non-empty content. |
| `requirements_txt` | string | `requirements.txt` content for Python dependencies. Empty string if absent. Only 7 entries have non-empty content. |

### Fields extracted from `package_xml` by the parser

The following are not stored directly in JSON but derived from `package_xml` during parsing:

- **`displayName`** — `<name>` tag value; falls back to addon ID if absent.
- **`description`** — `<description>` tag value.
- **`version`** — `<version>` tag value.
- **`license`** — `<license>` tag value (e.g. `"LGPL-2.1-or-later"`).
- **`minPython`** — `<pythonmin>` tag value; defaults to `"3.10"`.
- **`tags`** — all `<tag>` values within `<content>`, lowercased, sanitized, deduplicated.
- **`people`** — list of `{name, contact, roles}` from `<author>`, `<maintainer>`, `<contributor>` elements.
- **`declaredContent`** — list of content types detected by element presence: `workbench`, `macro`, `preferencePack`, `bundle`, `other`.

---

## How the Catalog is Loaded

1. **Download**: `AddonCatalog.download()` fetches `addon_catalog_cache.zip` via `DownloadManager`, caches it with a 6-hour TTL.
2. **Extract**: Opens the ZIP, finds `addon_catalog_cache.json`, reads it as UTF-8.
3. **Parse**: Iterates JSON entries, skipping keys starting with `_` or `$` or non-array values.
4. **Wrap**: Each branch entry becomes an `AddonEntry`, each addon ID becomes an `Addon` (with one or more entries). Addons sorted case-insensitively by `displayName`.
5. **Search**: Supports `#tag` filtering and text search against name, description, author.

---

## Consumption

The catalog is used by:

- **`AddonCatalogView`** — searchable grid UI in the Addons tab.
- **`AddonUpdateCheckController`** — checks downloaded addons against catalog to find outdated entries.
- **Addon detail views** — displays metadata, tags, versions, stats.
