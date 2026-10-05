# PLAN B-19 — FreeCAD `package.xml` `<depend>` support during addon install

> **Status**: Implemented + live-verified (2026-10-04, branch `b19-addon-dependencies`). Target:
> backlog `B-19`. The choices below were confirmed by the owner and recorded as decisions
> D-108..D-111. Verification: 675 unit/widget tests green, analyze clean, real Ondsel-Lens E2E
> passed (`test/manual/real_addon_dependencies_test.dart`), the real catalog dependency check
> passed, and a **live desktop pass** on an isolated data root completed the profile-addons flow
> (dialog in ~1 s with no extraction, consent, extraction with job progress, probe filter, pip,
> addon listed). The live pass caught B19-2: the consent preview used to trigger a silent
> AppImage extraction — the preview now never extracts and the full probe runs after consent.
> Remaining live checks: optional checkbox install, a dependent addon loaded inside FreeCAD, and
> the removal warning UI; bundle/batch flows install required dependencies only.

## Goal

Honor the FreeCAD package metadata `<depend>` tags (see
<https://wiki.freecad.org/Package_Metadata>) on every addon install path. The launcher currently
only reads `requirements.txt`; `package.xml` `<depend>` declarations are ignored, so addons that
declare Python packages or other addons there install broken.

Real catalog evidence (cached `addon_catalog_cache.json`, 2026-10-04): 191 branch entries, 167
with embedded `package_xml`, **79 with `<depend>`** and only 8 with `requirements.txt` — **73
entries declare dependencies exclusively through `<depend>`**. Example: `Ondsel-Lens` declares
`pyjwt`, `requests`, `tzlocal` (all `automatic`, required) and has no `requirements.txt`.

## Confirmed choices (owner answers, 2026-10-04)

| Topic | Choice |
|---|---|
| Consent UX | One unified dependency dialog: required addons, required Python, optional addons/Python (checkboxes, unchecked), internal workbenches as “provided by FreeCAD”; buttons Install dependencies / Addon only / Cancel |
| Optional deps | Checkbox for both addons and Python packages |
| Version attributes | Parsed and kept in the model, **ignored** for install and matching (FreeCAD AddonManager parity) |
| Already-available Python | Batched interpreter probe (`importlib.util.find_spec` + `importlib.metadata`); fallback to `python_packages` rows + generated stdlib-name guard |
| Dependency failure | Lenient: the addon still installs; failures surface through the existing `requirementsErrors`/`installErrors` signals (D-041 behavior) |
| Paths | Catalog install, custom repo/archive/directory install, updates (install only missing deps, prompt when new), bundle apply (one-shot union consent), manifest import |
| Removal of a dependency | Warn (“Required by: …”) but still allow removal |
| Updating dependencies | Never auto-update already-installed dependencies; install only when missing |

## Baseline (what exists today)

- `parsePackageXml` (`lib/domain/addons/package_xml.dart:30`) reads name/description/version/
  license/pythonmin/tags/people/content and ignores `<depend>`; `AddonMetadata`
  (`lib/domain/addons/addon.dart:13`) carries only the catalog `requirements_txt` string.
- Catalog parsing (`lib/data/catalog/addon_catalog_parser.dart:99`) parses the embedded
  `package_xml`; the full XML is not retained.
- Catalog install: `AddonsController.install` → `_installInternal`
  (`lib/state/addons_controller.dart:553`) uses the atomic `AddonInstaller.install`, writes the
  DB row, then optionally runs `_installRequirements` (pip) with `installRequirements` bool.
- Custom installs (`_installCustomInternal`, `:1057`) stage the archive, read `package.xml` via
  `readPackageXmlInfo` and `requirements.txt` via `readRequirementsFromDirectory`, ask through
  `CustomRequirementsHandler`, commit, then pip.
- UI consent: `lib/ui/addons/requirements_dialog.dart` (3 choices: packages / addon only /
  cancel) used by `addon_install_flow.dart`, `custom_addons_view.dart`; bundle apply uses a single
  checkbox in `collections_view.dart`.
- `python_packages` rows record `source = addon:<id>`; `installed_addons.hasRequirements` records
  whether requirements.txt existed.

## Scope

### In

- Domain: `AddonDependency` model + parser (root and nested `<content>` items), resolver with
  automatic resolution, recursion, dedupe and topological ordering.
- Platform: batched Python availability probe; stdlib-name fallback data.
- State: unified install pipeline for catalog + custom (staged metadata union), selection API,
  ordered dependent-addon installs, provenance records, lenient failure handling, reverse-dep
  lookup.
- UI: unified dependency dialog; wiring for catalog/custom/profile pickers; detail dependencies
  row; removal warning; bundle/updates/manifest consent.
- Tests (unit/platform/controller/widget), live verification with `Ondsel-Lens`, `Beltrami` and
  `FreeCAD-Ribbon`, docs.

### Out (documented limitations)

- Honoring version attributes for install/update (kept in the model for future work).
- Checking internal workbenches against the target build (assumed provided by standard FreeCAD;
  informational only).
- Auto-updating dependencies (updates remain notify-only, D-008).
- Schema changes: dependent addons are ordinary installed rows; reverse deps are derived from
  catalog metadata at runtime.
- Pinning/protecting a dependency from removal beyond the warning.

## Design

### 1. Domain model and parsing (B-19a)

`lib/domain/addons/package_xml.dart`

```dart
enum AddonDependencyType { automatic, addon, internal, python }

class AddonDependency {
  const AddonDependency({
    required this.name,
    required this.type,
    required this.optional,
    this.versionLt = '', this.versionLte = '', this.versionEq = '',
    this.versionGte = '', this.versionGt = '',
  });
  ...
}

class PackageXmlInfo { ... final List<AddonDependency> dependencies; }
```

- `root.findAllElements('depend')` (matches any namespace and nested `<content>` items, mirroring
  the AddonManager recursion).
- `optional` is case-insensitive (`True`/`true`); unknown `type` values fall back to `automatic`.
- Version attributes are parsed verbatim and unused (documented in D-108).

`lib/domain/addons/addon.dart`

- `AddonMetadata.dependencies` + `hasDependencies`; `AddonBranch.hasDependencies`;
  `Addon.hasDependencies`; `hasRequirements` keeps meaning “requirements.txt present”.

`lib/domain/addons/addon_dependencies.dart` (new, pure)

- `enum ResolvedDependencyKind { addon, python, internal }`
- `class ResolvedAddonDependency { AddonDependency source; kind; Addon? addon;
  PythonRequirement? python; String? internalName; String declaredByAddonId; }`
- `class AddonDependencyPlan { requiredAddons; optionalAddons; requiredPython; optionalPython;
  internalWorkbenches; invalidRequirements; orderedAddons; bool get hasInstallable;
  bool get isEmpty; }`
- `AddonDependencyPlan resolveAddonDependencies({required List<AddonDependency> dependencies,
  required List<Addon> catalog, Set<String> installedAddonIds, String? requirementsText,
  AddonBranch Function(Addon) branchOf, String declaringAddonId})`:
  - Catalog index by `id` and `displayName` (exact; case-insensitive fallback).
  - Resolution order per entry: explicit `addon` → catalog match, else fall through to the
    automatic rules (AddonManager parity); explicit `internal` → known internal workbench list,
    else unresolved; explicit `python` → Python requirement; `automatic` → catalog match, else
    internal workbench (`name`, `nameWB`, `nameWorkbench` normalization), else Python.
  - Recursion into dependent addons (including already-installed ones — their missing transitive
    deps must still install) with a visited set for cycles; installed addons are excluded from
    the install list but still walked.
  - `requirements.txt` entries are merged first (their specifiers win) and `<depend>` Python
    entries fill the gaps; dedupe by PEP 503 name with required beating optional; first
    declaration wins `declaredByAddonId`.
  - `orderedAddons` is a post-order DFS (deepest dependency first) so execution can install them
    sequentially without nested resolution.
- `internalWorkbenches` constant: assembly, bim, cam, draft, fem, import, material, mesh,
  openscad, part, partdesign, plot, points, reverseengineering, robot, sketcher, spreadsheet,
  techdraw, tux, web.

`lib/data/catalog/addon_catalog_parser.dart` passes `info.dependencies` to `AddonMetadata`.

### 2. Python availability probe (B-19b)

`lib/platform/python_package_probe.dart` (new)

- `Future<Set<String>?> availablePackages({required String pythonPath,
  required String targetDirectory, required Iterable<String> names,
  Duration timeout = const Duration(seconds: 60)})`
- One interpreter run: `-c <script> <name…>`; for each name
  `importlib.util.find_spec(name) is not None or importlib.metadata.distribution(name)` inside
  try/except; PEP 503-normalized JSON on stdout. Environment inherits the parent, removes
  `sanitizedEnvironmentKeys`, sets `PYTHONPATH=<targetDirectory>` (when it exists),
  `PYTHONNOUSERSITE=1`; stdin closed by `ProcessRunner`.
- Returns `null` on execution failure (distinct from an empty set).

`lib/domain/python/python_names.dart` (new): shared `normalizePythonPackageName` (PEP 503).

`lib/domain/python/python_stdlib_names.dart` (new): generated union of `sys.stdlib_module_names`
for 3.10–3.13; used only when the probe fails, together with `python_packages` rows, so a failed
probe never pip-installs `math`/`inspect`/`tkinter`.

### 3. Install execution (B-19c)

`lib/state/addons_controller.dart`

```dart
class AddonDependencySelection {
  final bool installRequired;
  final Set<String> optionalAddonIds;
  final Set<String> optionalPackageNames; // PEP 503
  static const none = ...;
  static const requiredOnly = ...;
}

typedef AddonDependencyHandler =
    Future<AddonDependencySelection?> Function(AddonDependencyPlan plan);
```

- `prepareDependencies({addonId, branchRef, profileId, requirementsText})` → resolve + drop
  already-installed addons + probe-filter Python; used by the UI before install.
- `install(..., AddonDependencySelection selection = none, AddonDependencyHandler? onDependencies)`
  replacing the `installRequirements` bool; `update(...)` gains the same parameters.
- Unified pipeline (catalog and custom):
  1. download + `prepareFromArchive` (staging, uncommitted);
  2. read the staged `package.xml` + `requirements.txt`; merge with the catalog-based plan
     (union). If required entries appear that the pre-download consent could not know about
     (catalog entry without metadata) and a handler exists, ask then;
  3. probe-filter Python; install required Python in one pip run; on batch failure retry each
     package individually to isolate bad names; record each success in `python_packages` with
     `source = addon:<declaringAddonId>`;
  4. install dependent addons in `orderedAddons` order, recursively through the internal method
     with resolution disabled (the closure is already flattened), one job, visited guard,
     `detail: 'Installing dependency …'`;
  5. commit/place the main addon, write the `installed_addons` row with `hasRequirements` = any
     declared Python deps;
  6. failures are lenient: Python → `requirementsErrors[mainAddonId]`, dependent addon →
     `installErrors[dependencyId]`, main addon still installs.
- `dependentsOf(profileId, addonId)` walks installed catalog addons' dependency closures and
  returns the display names for the removal warning.
- Probe results memoized per `(buildId, profileId)` for the session.

### 4. UI (B-19d/B-19e)

- `lib/ui/addons/addon_dependencies_dialog.dart` replacing `requirements_dialog.dart`:
  `showAddonDependenciesDialog(context, addonName, plan)` returns
  `AddonDependencySelection?` (`null` = cancel, `none` = addon only). Sections render only when
  non-empty; optional rows are `CheckboxListTile`s; invalid requirements.txt lines keep the red
  monospace style.
- `addon_install_flow.dart`: `prepareDependencies` → dialog (when `hasInstallable` or invalid
  entries) → `install(selection, onDependencies)`.
- `custom_addons_view.dart`: `_askRequirements` → `_askDependencies` using the resolved plan.
- `addons_view.dart` detail: dependencies row (names, `*` optional marker) replacing the yes/no
  requirements row.
- `addon_remove_flow.dart` + custom/profile remove dialogs: append “Required by: …” when
  `dependentsOf` is non-empty.
- `planBundleApply` aggregates dependency preview fields; `collections_view.dart` apply consent
  uses the unified dialog; `BundleApplyController.apply(..., dependencySelection)`.
- `UpdatesController.applyUpdates(..., selection)` and the summary sheet ask once for the
  aggregated new dependencies before a batch.
- `ProfileManifestController` maps its checkbox to a required-only selection; dialogs/l10n
  wording becomes “dependencies”.
- l10n: ~12 new `addonsDependencies*` keys + renames; `flutter gen-l10n`.
- No schema change (stays v6).

## Testing

- **Unit**: `package_xml` (root/nested deps, types, optional casing, constraints, no namespace);
  resolver (automatic→addon/internal/python, `PartWB`/`PartWorkbench`, display-name match,
  missing addon→python parity, A→B→C ordering, installed-B recursion for C, cycle, dedupe,
  topological order, invalid requirements); stdlib list sanity.
- **Platform**: probe parsing with a fake `ProcessRunner` (available, missing, failure→null).
- **Controller**: catalog install with deps (pip once, ordered addons, sources, `hasRequirements`);
  selection none/optional; probe skip; lenient pip/addon failures; custom staged `package.xml`;
  catalog-metadata-missing post-staging prompt; update missing-only; `dependentsOf`; manifest
  mapping.
- **Widget**: dialog sections/checkboxes/cancel; pre-download prompt passes the selection; detail
  dependencies row; remove warning.
- **Live manual**: `Ondsel-Lens` into a real profile (`pyjwt`/`tzlocal` installed, `requests`
  skipped as bundled, Python tab shows `addon:Ondsel-Lens`, workbench loads); `Beltrami` for
  dependent-addon ordering (`Curves` + scipy/numpy + internals); `FreeCAD-Ribbon` for optional
  addons; removing `Curves` while `Beltrami` is installed shows the warning.
- `flutter analyze` / `flutter test` green.

## Risks / mitigations

| Risk | Mitigation |
|---|---|
| Probe latency | single batched run, only when Python deps exist, session memoization |
| Stale catalog `package_xml` | staged union read plus one late consent when required entries are new |
| Cycles / deep chains | visited set + post-order ordering + progress details |
| One bad package name poisons the pip batch | per-package retry after a batch failure, lenient reporting |
| Stdlib names in `<depend>` (math, inspect, getpass, tkinter) | probe `find_spec` parity; stdlib guard on probe failure |
| AppImage extraction on first pip need | existing `PythonEnvResolver` behavior (extract once) |

## Task breakdown

| ID | Task | Effort | Deps |
|---|---|---|---|
| B-19a | `AddonDependency` parsing + resolver + internal workbench list + unit tests | M | — |
| B-19b | Python availability probe + stdlib fallback + tests | M | — |
| B-19c | Controller pipeline: selection API, staged metadata union, ordered dependency installs, records, lenient failures + tests | L | B-19a, B-19b |
| B-19d | Unified dependencies dialog, catalog/custom/profile flows, detail row, removal warning, l10n + widget tests | L | B-19c |
| B-19e | Bundle apply, update batch and manifest import wiring + tests | M | B-19c |
| B-19f | Ondsel-Lens/Beltrami/FreeCAD-Ribbon live verification, spec/README/user-guide/VERIFICATION updates, decisions, STATUS | M | B-19d, B-19e |

## Decisions to record

- **D-108** — `<depend>` parsing and resolution semantics (automatic order, catalog matching,
  internal list, recursion over installed addons, PEP 503 dedupe, version attributes parsed but
  ignored).
- **D-109** — Unified dependency consent dialog and the pre/post-download consent policy.
- **D-110** — Already-available Python detection: batched interpreter probe with DB-row +
  stdlib-name fallback.
- **D-111** — Dependency execution: pip → dependent addons → main addon, provenance
  `addon:<declaringId>`, lenient failures, missing-only on updates, reverse-dependency removal
  warning, no schema change.
