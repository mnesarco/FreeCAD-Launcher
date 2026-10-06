# 06 — Integrations

All facts below were verified against live GitHub APIs and the FreeCAD source as of
2026-09-18. The stable release referenced is `1.1.3` (published 2026-07-25).

## 1. GitHub releases (FreeCAD builds)

### 1.1 Endpoints

| Purpose | Endpoint |
|---|---|
| Latest stable | `GET https://api.github.com/repos/FreeCAD/FreeCAD/releases/latest` |
| All releases (paged) | `GET https://api.github.com/repos/FreeCAD/FreeCAD/releases?per_page=100&page=N` |
| Single tag | `GET https://api.github.com/repos/FreeCAD/FreeCAD/releases/tags/<tag>` |
| Asset download | `https://github.com/FreeCAD/FreeCAD/releases/download/<tag>/<asset>` |

Pre-1.0 releases (0.19–0.21) and the archived `FreeCAD/FreeCAD-Bundle` repo are ignored
(D-021).

Implementation uses conditional requests (`If-None-Match`) and caches the payload. Note:
unauthenticated 304 responses still consume a small amount of rate limit; avoid polling.

### 1.2 Rate limits

- Unauthenticated: **60 requests/hour/IP** (verified `x-ratelimit-limit: 60`).
- Authenticated: **5,000 requests/hour**.
- Strategy: 6-hour TTL for catalog refreshes, ETag-aware requests, respect
  `X-RateLimit-Remaining`/`X-RateLimit-Reset`, surface the remaining count in Settings,
  optional PAT (classic, no scopes needed for public repos) to lift the limit (OQ-3).
- Do not call `/rate_limit` in loops (it is free, but pointless); read response headers.

### 1.3 Channel and asset classification

Asset names have evolved. Classification must use regex over exact names, not assumptions.

| Channel | Tag pattern | Pre-release flag | Assets |
|---|---|---|---|
| `stable` | semver `X.Y.Z` >= 1.0 through 1.1.x; CalVer `YY.N` (e.g. `26.3`, three releases/year) and patches `YY.N.P` (e.g. `27.1.1`) from the next stable on (FEP-0003) | false | see below |
| `weekly` | `weekly-YYYY.MM.DD` | true | `FreeCAD_weekly-...` |
| `weekly` rolling | `weeklies` | true | Linux only (skipped by the launcher, D-077) |
| `legacy` | supported stable lines older than the newest stable line in the catalog (currently 1.0.x; 1.1.x joins once 26.3 ships) | false | semver-era and 1.0 conda-era names |

Asset patterns (current era, 1.1.x):

- Linux: `FreeCAD_<ver>-Linux-(x86_64|aarch64)-py<py>.AppImage` (+ `.zsync`, `-SHA256.txt`)
- Windows: `FreeCAD_<ver>-Windows-x86_64-py<py>.7z` (portable) and `...-installer.exe` (ignored)
- macOS: `FreeCAD_<ver>-macOS-(arm64|x86_64)-py<py>.dmg`

Older naming (still parsed for `legacy` = 1.0.x):

- 1.0.x: `FreeCAD_1.0.2-conda-Linux-x86_64-py311.AppImage`, `...-conda-Windows-x86_64-py311.7z`,
  `...-conda-Windows-x86_64-installer-1.exe`, `...-conda-macOS-arm64-py311.dmg`

Pre-1.0 releases (0.19–0.21, e.g. `FreeCAD-0.21.2-Linux-x86_64.AppImage`) are ignored by the
classifier (D-021); their fixtures remain as regression cases. Known gaps no longer apply to
supported lines: assets are hidden rather than linked when a platform/arch combination is
missing.

Weekly notes:

- Weekly builds moved to `FreeCAD/FreeCAD` (tag `weekly-YYYY.MM.DD`, published most
  Wednesdays); `FreeCAD/FreeCAD-Bundle` is archived and only holds old `weekly-builds`.
- The rolling `weeklies` tag provides generic Linux AppImages with zsync updates.
- Weekly builds are development-quality; the UI must label them clearly and never auto-install.

### 1.4 Integrity

- Assets ship a sidecar `<asset>-SHA256.txt`. Download it first when present, parse the hex
  digest, verify after download; block install on mismatch.
- macOS builds are signed by "The FreeCAD project association AISBL" in CI, but notarization
  has been unreliable (open issue FreeCAD/FreeCAD#30621: `spctl` can reject with unnotarized
  or invalid-signature errors). Strategy: install `.app` to a user-writable directory, offer
  quarantine removal with explanation, and surface the right-click→Open fallback in diagnostics.
- FreeCAD Windows builds bundle MSVC/UCRT DLLs; no separate redistributable requirement was found
  for current conda bundles.
- The launcher's own Windows portable zip bundles the Microsoft Visual C++ runtime app-local next
  to `freecad_launcher.exe` (D-114), so the launcher runs without a system-wide Visual C++
  Redistributable install; the UCRT is in-box on Windows 10+ and is not shipped.
- Linux AppImages are type-2 (FUSE 2). When FUSE is unavailable, use
  `APPIMAGE_EXTRACT_AND_RUN=1`; diagnostics check `/dev/fuse` and `fusermount` and explain
  `libfuse2`/`libfuse2t64` alternatives.

### 1.5 Version ordering

- CalVer (FEP-0003, active 2026-05-15): stable tags are `YY.N` (three releases per year; `N` =
  1..3; `YY` = year of the cycle's `.1` release) with monthly patches `YY.N.P`. The first
  CalVer release is `26.3` (branched 2026-09-30, expected ~2026-11-18). RCs (`26.3rc1`) are
  ignored until the final tag; `26.3` and `26.3.0` denote the same release.
- Stable/legacy: numeric compare across schemas (`26.3 > 1.1.4 > 1.0.2`); CalVer sorts above any
  semver line; RC suffixes (`1.1rc3`, `26.3rc1`) are ignored until the final tag.
- The stable/legacy split is catalog-derived (D-078): the highest supported stable version
  (`major.minor`) present defines the current line; supported versions below it are `legacy`
  (1.0.x today; 1.1.x joins once 26.3 ships, 26.3 once 27.1 branches).
- Weekly: compare tag dates (`weekly-2026.09.16`), all weeklies sort above any stable only
  within the weekly channel; channels are never mixed in one update suggestion.
- Build identity = `(channel, version, platform, arch)`; two builds of the same version from
  different channels are distinct.

## 2. Addon catalog

The existing [`addon_index_spec.md`](../../addon_index_spec.md) remains authoritative for the
cache format. Integration rules for v2:

- **Source**: `https://addons.freecad.org/addon_catalog_cache.zip` (single JSON inside),
  cached with a 6-hour TTL and offline fallback.
- **Stats** (optional): `addon_stats.json` for download counts/stars; failure is non-fatal.
- **Install**: use the entry's `zip_url` (repo archive). If absent, combine the configured
  `mainConfig.addonsDownloadBaseUrl` with `relative_cache_path`.
- **Branch choice**: entries are per-branch; prefer the user's explicit `git_ref`, else the
  first entry whose `freecad_min`/`freecad_max` brackets the profile's version, else the first.
- **Placement**: extract to `<profile>/Mod/<AddonId>` (matches FreeCAD's AddonManager).
- **Update detection**: compare installed `catalogLastUpdate`/package version against the
  catalog entry; show update, never auto-apply.
- **Dependencies**: `package.xml` `<depend>` tags (root and nested `<content>` items) and
  `requirements.txt` are resolved on install into dependent addons (catalog match by id/display
  name), internal workbenches (informational, provided by FreeCAD) and Python packages.
  `automatic` entries resolve addons first, then internal workbenches, then Python (AddonManager
  parity); version attributes are parsed but ignored; optional addons/packages are opt-in in one
  consent dialog per install (D-109). Already importable Python packages and installed addons
  are skipped (D-110); dependent addons and pip packages install before the addon with lenient
  failure handling (D-111). The same flow applies to custom sources, updates (missing deps only),
  bundle apply and manifest import.
- **Safety**: safe-extract with zip-slip guards; reject entries with absolute/escaping paths;
  symlink entries are **never created** — they are skipped and reported to the user (D-113);
  cap uncompressed size and file count to avoid zip bombs. Installs are atomic: extract into
  `<Mod>/<id>.part`, then rename into place with a `.old` backup when replacing (D-039).
- **Custom sources** (v0.2, D-085..D-088): repository URL + ref resolves to the host archive
  URL (GitHub `…/archive/<ref>.zip`, GitLab `…/-/archive/<ref>/…`, Gitea/Codeberg
  `…/archive/<ref>.zip`) or a direct archive URL; local archives (`.zip`/`.tar.gz`) and dev
  directories (symlinked in place, hard-fail without symlink support) are also supported. All
  custom installs require `package.xml` at the content root, are blocked while the id exists in
  the profile, store `source`/`sourcePath`, are excluded from catalog update checks, and keep
  requirements consent before placement. Removing a symlinked addon deletes only the link.

## 3. Macro catalog

- Primary source: the official prebuilt macro cache `https://addons.freecad.org/macro_cache.zip`
  (plus `.sha256`), generated server-side by FreeCAD's AddonManager from the official
  `FreeCAD/FreeCAD-macros` repository merged with wiki macros (`wiki.freecad.org/Macros_recipes`,
  git copies win). The zip holds `macro_cache.json` with full macro code, metadata, SPDX
  `license` and base64 icons. Verified in spike S4 (decision D-044).
- v0.1 capabilities: list/search macros in the repo, download a single `.FCMacro` into the
  profile, delete, reveal, open externally.
- Update checks are file-hash based, deferred to v0.2 (needs a cached index).
- Macro placement: `<profile>/Macros/` (created with the profile layout); the scanner lists
  `.FCMacro` files only from that directory and the launcher forces
  `BaseApp/Preferences/Macro/MacroPath` to it in `<profile>/user.cfg` on every launch.

## 4. Bundled Python and pip

### 4.1 Interpreter discovery per build kind

| Kind | Interpreter |
|---|---|
| Linux AppImage (FUSE) | no extraction: pip and availability checks run **inside the mounted image** through generated headless `.FCMacro`s (`<appimage> -c -M <dir> <macro>`), D-112 |
| Linux AppImage (no FUSE) | fallback: extract once to `builds/<id>/extracted/squashfs-root/usr/bin/python` and use it as an interpreter |
| Windows archive | `<build>\bin\python.exe` (always invoke via `-m pip`, never `Scripts\pip.exe`) |
| macOS dmg | `<build>/FreeCAD.app/Contents/Resources/bin/python` |
| Custom | probe `<exeDir>/bin/python*`, `Contents/Resources/bin/python`; pip UI disabled with explanation if absent |

The asset-name `pyXY` hint (e.g. `…-Windows-x86_64-py311.7z`) is **metadata only**: it may fill
the displayed Python version when no interpreter can be probed, but the interpreter path is always
discovered and probed on disk (D-115). FreeCAD executables (`FreeCAD`, `FreeCADCmd`, `AppRun`)
are never invoked as Python — `-m pip` is invalid for them; they are only ever spawned with `-c`
(console) through the headless macro runner.

Bash/zsh must never be involved: run the interpreter directly with an argument array and the
profile env (plus `PYTHONHOME`/`PREFIX` only if the platform shim needs it; prefer the shim
launcher when one exists, e.g. macOS `Contents/MacOS/FreeCAD` sets its own env).

### 4.2 Pip invocation

Interpreter-based pip runs through a small launcher-generated bootstrap script (D-118) that writes
the interpreter/target/packages header to the pip log, repairs a stale bundled `ssl.py` by aliasing
`_ssl.RAND_pseudo_bytes` to `RAND_bytes` when the interpreter no longer exports it (the 1.1 Windows
bundles ship a Python 3.11-era `ssl.py`, and Python 3.13 removed that symbol), registers the
interpreter's own directory and its `DLLs` subdirectory with `os.add_dll_directory()` (Windows
only; a no-op elsewhere, the returned handles stay alive), reports the `ssl` module availability
with the full traceback when it is missing, and then executes the equivalent of `-m pip` in-process
(`runpy.run_module("pip", run_name="__main__")`). The effective pip arguments are:

```
<python> -c/runpy: pip install --upgrade --target <targetDir> <spec...>
    --disable-pip-version-check --no-warn-script-location
```

AppImages use the same arguments, but executed in-process inside the image:

```python
from pip._internal.cli.main import main as pip_main   # runpy fallback
pip_main(['install', '--upgrade', '--target', target, *packages, …])
```

The macro writes pip's output to the job log and prints a tagged JSON result; wheel downloads
use a persistent `<data>/cache/pip` (`PIP_CACHE_DIR`) despite the isolated macro home.

- `targetDir`: `<profile>/AdditionalPythonPackages/py<major><minor>` (FreeCAD 1.0+ always uses
  the versioned dir; pre-1.0 is unsupported, D-021). The Python version is reported by the
  interpreter (`sys.version_info`), never guessed.
- FreeCAD appends `AdditionalPythonPackages/pyXY` to `sys.path` at startup (last), so bundled
  modules win name clashes — warn users in that case.
- `PYTHONPATH`/`PYTHONHOME` are ignored by FreeCAD 1.0+ (isolated `PyConfig`), which is why
  the `--target` + `AdditionalPythonPackages` mechanism is used instead of env manipulation.
- Pip output is streamed to a job log; a spinner plus "resolving…" state is shown because pip
  can be silent for a while. Network failures report the raw pip tail.
- `--upgrade` is mandatory: without it pip warns and skips when the target directory already
  contains the package (verified pip 24.0).
- Uninstall (v0.1): RECORD-based removal (S3/D-036) — parse every `<name>-*.dist-info/RECORD`,
  delete files that stay inside the target, prune empty dirs, then delete the dist-info.
  Updates uninstall first, then install with `--upgrade` (pip leaves the old dist-info behind).
- Concurrency: never allow two pip jobs in the same profile; packaging installs are serialized
  globally as well (package DB locks).

### 4.3 Addon dependencies

- Parse `requirements.txt` (comments, extras, markers) and `package.xml` `<depend>` tags with a
  small parser; show one preview grouped by required/optional addons and Python packages.
- Install after explicit consent, then record each package with
  `source = addon:<declaringAddonId>`.
- Packages already importable (bundled with FreeCAD, installed in the profile target, or
  standard library) are detected with one batched probe (`importlib.util.find_spec` +
  `importlib.metadata`) — inside the AppImage for AppImage builds (D-112); a failed probe falls
  back to recorded
  packages plus a stdlib-name guard so stdlib names are never handed to pip (D-110).
- Dependent addons install recursively inside the same job before the addon; a failed dependency
  is reported without aborting the main install (D-111).
- Do not vendor wheels; use the bundled pip's default index (PyPI) and respect system proxy.

## 5. Network and privacy

- Only three hosts by default: `api.github.com`/`github.com`, `addons.freecad.org`, `pypi.org`
  (pip, user-triggered).
- User-supplied URLs are fetched only on explicit action, with the host shown in the confirm dialog.
- No telemetry. Logs may contain URLs; tokens are redacted.
