// Generated with bawr: 2026-02-27 09:41:35.902526

import 'package:flutter/widgets.dart';

class FreeCADIcons {
  static const Font_Family = "freecad-launcher-icons";
  static const Font_StartCode = 0xe000;
  static const Font_EndCode = 0xe006;
  static const IconData addon = IconData(0xe000, fontFamily: Font_Family);
  static const IconData freecad = IconData(0xe001, fontFamily: Font_Family);
  static const IconData pkg_appimage = IconData(0xe002, fontFamily: Font_Family);
  static const IconData pkg_executable = IconData(0xe003, fontFamily: Font_Family);
  static const IconData pkg_flatpak = IconData(0xe004, fontFamily: Font_Family);
  static const IconData pkg_snap = IconData(0xe005, fontFamily: Font_Family);
  static const IconData pkg_system = IconData(0xe006, fontFamily: Font_Family);
}

Map<String, IconData> AppKindIconMap = {
  "AppImage": FreeCADIcons.pkg_appimage,
  "Executable": FreeCADIcons.pkg_executable,
  "Flatpak": FreeCADIcons.pkg_flatpak,
  "Snap": FreeCADIcons.pkg_snap,
  "System": FreeCADIcons.pkg_system,
};

IconData appKindIcon(String kind) {
  return AppKindIconMap[kind] ?? FreeCADIcons.pkg_executable;
}
