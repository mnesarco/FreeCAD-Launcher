import 'dart:ffi';
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

String get hostArch => switch (Abi.current()) {
  Abi.linuxArm64 || Abi.windowsArm64 || Abi.macosArm64 => BuildArch.arm64,
  _ => BuildArch.x86_64,
};
