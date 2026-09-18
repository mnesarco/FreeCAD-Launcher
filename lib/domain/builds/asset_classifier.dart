import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/domain/builds/release_info.dart';

class BuildCandidate {
  const BuildCandidate({
    required this.versionLabel,
    required this.channel,
    required this.platform,
    required this.arch,
    required this.kind,
    required this.assetName,
    required this.downloadUrl,
    required this.sizeBytes,
    this.version,
    this.weekly,
    this.pythonVersion,
    this.checksumUrl,
    this.macosMinVersion,
    this.releaseNotesUrl,
  });

  final String versionLabel;
  final BuildChannel channel;
  final BuildPlatform platform;
  final String arch;
  final BuildKind kind;
  final String assetName;
  final String downloadUrl;
  final int sizeBytes;
  final FreeCadVersion? version;
  final WeeklyVersion? weekly;
  final String? pythonVersion;
  final String? checksumUrl;
  final int? macosMinVersion;
  final String? releaseNotesUrl;

  String get id => [channel.name, versionLabel, platform.name, arch].join(':');
}

abstract final class AssetClassifier {
  static List<BuildCandidate> classify(ReleaseInfo release) {
    final tag = ReleaseTag.parse(release.tagName);
    if (tag == null) {
      return const [];
    }

    final candidates = <BuildCandidate>[];
    for (final asset in release.assets) {
      if (!_isInstallableAsset(asset.name)) {
        continue;
      }
      final platformKind = _platformKind(asset.name);
      final arch = _archFromName(asset.name);
      if (platformKind == null || arch == null) {
        continue;
      }

      final sidecarName = '${asset.name}-SHA256.txt';
      final sidecar = release.assets.where((candidate) => candidate.name == sidecarName);

      candidates.add(
        BuildCandidate(
          versionLabel: tag.raw,
          channel: tag.channel,
          platform: platformKind.$1,
          kind: platformKind.$2,
          arch: arch,
          assetName: asset.name,
          downloadUrl: asset.downloadUrl,
          sizeBytes: asset.size,
          version: tag.version,
          weekly: tag.weekly,
          pythonVersion: _pythonFromName(asset.name),
          checksumUrl: sidecar.isEmpty ? null : sidecar.first.downloadUrl,
          macosMinVersion: _macosMinVersion(asset.name),
          releaseNotesUrl: release.htmlUrl,
        ),
      );
    }
    return candidates;
  }

  static BuildCandidate? selectFor(
    List<BuildCandidate> candidates, {
    required BuildPlatform platform,
    required String arch,
  }) {
    final matching = candidates
        .where((candidate) => candidate.platform == platform && candidate.arch == arch)
        .toList();
    if (matching.isEmpty) {
      return null;
    }
    matching.sort((a, b) {
      final target = (b.macosMinVersion ?? 0).compareTo(a.macosMinVersion ?? 0);
      if (target != 0) {
        return target;
      }
      return a.assetName.compareTo(b.assetName);
    });
    return matching.first;
  }

  static bool _isInstallableAsset(String name) {
    if (name.endsWith('-SHA256.txt') || name.endsWith('.sha256')) {
      return false;
    }
    if (name.endsWith('.zsync') || name.endsWith('.tar.gz') || name.contains('source')) {
      return false;
    }
    if (name.contains('-installer') || name.endsWith('.exe')) {
      return false;
    }
    if (name.contains('experimental')) {
      return false;
    }
    return true;
  }

  static (BuildPlatform, BuildKind)? _platformKind(String name) {
    if (name.endsWith('.AppImage')) {
      return (BuildPlatform.linux, BuildKind.appimage);
    }
    if (name.endsWith('.dmg')) {
      return (BuildPlatform.macos, BuildKind.dmg);
    }
    if (name.endsWith('.7z') || name.endsWith('.zip')) {
      return (BuildPlatform.windows, BuildKind.archive);
    }
    return null;
  }

  static String? _archFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('aarch64') || lower.contains('arm64')) {
      return BuildArch.arm64;
    }
    if (lower.contains('x86_64') || lower.contains('x64')) {
      return BuildArch.x86_64;
    }
    return null;
  }

  static String? _pythonFromName(String name) {
    final match = RegExp(r'py(\d)(\d{1,2})').firstMatch(name);
    if (match == null) {
      return null;
    }
    return '${match[1]}.${match[2]}';
  }

  static int? _macosMinVersion(String name) {
    final match = RegExp(r'macOS(\d+)').firstMatch(name);
    return match == null ? null : int.tryParse(match[1]!);
  }
}
