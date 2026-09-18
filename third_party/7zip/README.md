# 7-Zip standalone (`7zr.exe`)

- **Source**: https://www.7-zip.org/a/7zr.exe
- **Downloaded**: 2026-09-18
- **SHA-256**: `ad4c82fadcbdf93c03b4fc440f300509c7d60c5c2f4d183e35d9d70d6957037d`
- **Size**: 602,624 bytes
- **License**: LGPL-2.1-or-later (see `license.txt`; the unRAR restriction does not
  apply because 7zr does not contain RAR code)
- **Architecture**: PE32 x86 console executable; runs on x86_64 Windows via WoW64

## Role

Windows-only extraction helper for official FreeCAD `.7z` portable archives
(LZMA2 + LZMA + BCJ2, solid). The app invokes it with `ProcessRunner` and
argument arrays (`x -y -o<dest> <archive>`); it is never called through a shell.

## Updating

Replace the binary only together with its SHA-256 above and re-run the Windows
extraction smoke test (`M2-05`). `THIRD_PARTY_NOTICES.md` must include 7-Zip
before release (`M7-03`).
