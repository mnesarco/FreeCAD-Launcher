enum BuildKind { appimage, archive, dmg, custom }

enum BuildChannel { stable, weekly, legacy, custom }

enum BuildPlatform { linux, windows, macos }

enum BuildStatus { installed, missing, broken }

abstract final class BuildArch {
  static const String x86_64 = 'x86_64';
  static const String arm64 = 'arm64';
}
