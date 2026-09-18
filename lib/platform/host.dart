import 'dart:io';

import 'package:freecad_launcher/domain/builds/build_types.dart';

BuildPlatform get hostPlatform {
  if (Platform.isWindows) {
    return BuildPlatform.windows;
  }
  if (Platform.isMacOS) {
    return BuildPlatform.macos;
  }
  return BuildPlatform.linux;
}
