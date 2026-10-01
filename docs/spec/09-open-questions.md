# 09 — Open Questions

Blocking = must be answered before the affected milestone starts.

| ID | Question | Why it matters | Options / recommendation | Blocking | Status |
|---|---|---|---|---|---|
| OQ-1 | How are the launcher binaries distributed for Windows and macOS? The locked answer was AppImage only, but the app must run on all three OSes. | Packaging/CI effort and release docs | (a) source build instructions only for v0.1; (b) portable `.zip` (Windows) + `.dmg`/unsigned `.app` (macOS); (c) installer `.exe` + notarized `.dmg`. Recommendation: (b) for v0.2 | v0.2 distribution | Windows resolved by D-091 (unsigned portable `.zip`); macOS remains M8-04 |
| OQ-2 | What application id / reverse-DNS identity to use? ("FreeCAD Launcher" name kept, but `.desktop`, AppImage, app-support dirs need an id.) | Paths (`getApplicationSupportDirectory`), desktop integration, data dir | Resolved: `org.freecad.ext.launcher` (D-016) | M1 (data paths) | Resolved by D-016 |
| OQ-3 | Store the optional GitHub token at all in v0.1, and how? | Rate limits vs security effort | (a) v0.2 only, with `flutter_secure_storage` (Keychain/DPAPI/libsecret); (b) v0.1 plain DB with warning; (c) never. Recommendation: (a) | v0.2 | Open |
| OQ-4 | Exact macro catalog source and license handling | FR-7.2, spike S4 | Verify `FreeCAD/FreeCAD-macros` repo structure and license; alternatives: wiki macro pages | M5 | Open |
| OQ-5 | Full export contents and default toggles (addon payloads, Python packages, macros) | FR-9.2 size/portability trade-off | Recommendation: full export includes config + macros by default, addon payloads opt-in | v0.2 | Open |
| OQ-6 | Localization in scope, and when? | Public OSS audience; ARB scaffolding cost | Resolved: ARB scaffolding from day one, English template only (D-017) | M1 (string handling) | Resolved by D-017 |
| OQ-7 | Repository hosting and release repo slug for self-update/update checks (`gh-releases-zsync` needs owner/repo) | Distribution and self-update | Owner/repo confirmed once the public repo exists; can be parameterized in constants | M8 | Open |
| OQ-8 | Should profiles support a "fully isolated" private build copy (hybrid model) later? | Disk vs isolation; currently locked to shared builds | Recommendation: defer to post-v1.0; keep the env/launch layer able to support it | post-v1.0 | Deferred |

## Resolved by this spec (for the record)

- Shared build + isolated profiles — locked.
- Application identity is `org.freecad.ext.launcher` (D-016).
- i18n uses ARB scaffolding from day one; v0.1 ships English (D-017).
- Fresh DB, no migration — locked; prototype data must be copied manually if needed.
- Flatpak/Snap support — dropped; do not reintroduce without a new spec decision.
- Python packages via bundled interpreter + `--target` — locked (verified mechanism).
- Weekly builds live on `FreeCAD/FreeCAD` as `weekly-YYYY.MM.DD` and `weeklies` — verified.
