// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/asset_classifier.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/domain/builds/release_info.dart';

import '../helpers/fixtures.dart';

void main() {
  List<BuildCandidate> classifyFixture(String fixture, {FreeCadVersion? stableLine}) {
    final releases = parseReleasesJson(loadFixture(fixture));
    return AssetClassifier.classify(releases.single, stableLine: stableLine);
  }

  BuildCandidate? select(
    List<BuildCandidate> candidates, {
    required BuildPlatform platform,
    required String arch,
  }) {
    return AssetClassifier.selectFor(candidates, platform: platform, arch: arch);
  }

  group('1.1.3 stable', () {
    test('classifies installable assets and skips installers and checksums', () {
      final candidates = classifyFixture('github_releases_1.1.3.json');

      expect(candidates, hasLength(5));
      expect(candidates.every((candidate) => candidate.channel == BuildChannel.stable), isTrue);
      expect(
        candidates.where((candidate) => candidate.platform == BuildPlatform.windows),
        hasLength(1),
      );
    });

    test('selects the right asset per platform and arch', () {
      final candidates = classifyFixture('github_releases_1.1.3.json');

      final linux = select(candidates, platform: BuildPlatform.linux, arch: BuildArch.x86_64)!;
      expect(linux.assetName, 'FreeCAD_1.1.3-Linux-x86_64-py311.AppImage');
      expect(linux.kind, BuildKind.appimage);
      expect(linux.pythonVersion, '3.11');
      expect(linux.checksumUrl, contains('SHA256'));

      final windows = select(candidates, platform: BuildPlatform.windows, arch: BuildArch.x86_64)!;
      expect(windows.assetName, 'FreeCAD_1.1.3-Windows-x86_64-py311.7z');
      expect(windows.checksumUrl, isNull);

      final macArm = select(candidates, platform: BuildPlatform.macos, arch: BuildArch.arm64)!;
      expect(macArm.assetName, 'FreeCAD_1.1.3-macOS-arm64-py311.dmg');
      expect(macArm.kind, BuildKind.dmg);

      expect(select(candidates, platform: BuildPlatform.windows, arch: BuildArch.arm64), isNull);
    });
  });

  group('release candidates', () {
    test('classifies the 26.3rc1 assets into the rc channel', () {
      final candidates = classifyFixture('github_releases_26.3rc1.json');

      expect(candidates, hasLength(6));
      expect(candidates.every((candidate) => candidate.channel == BuildChannel.rc), isTrue);
      expect(
        candidates.every(
          (candidate) =>
              candidate.versionLabel == '26.3rc1' && candidate.version?.isPrerelease == true,
        ),
        isTrue,
      );

      final linux = select(candidates, platform: BuildPlatform.linux, arch: BuildArch.x86_64)!;
      expect(linux.assetName, 'FreeCAD_26.3rc1-Linux-x86_64.AppImage');
      expect(linux.kind, BuildKind.appimage);
      expect(linux.pythonVersion, isNull);
      expect(linux.checksumUrl, contains('SHA256'));

      final windows = select(candidates, platform: BuildPlatform.windows, arch: BuildArch.x86_64)!;
      expect(windows.assetName, 'FreeCAD_26.3rc1-Windows-x86_64.7z');

      final macArm = select(candidates, platform: BuildPlatform.macos, arch: BuildArch.arm64)!;
      expect(macArm.assetName, 'FreeCAD_26.3rc1-macOS15-arm64.dmg');
      expect(macArm.kind, BuildKind.dmg);
    });
  });

  group('legacy naming era', () {
    test('1.0.2 conda names are legacy under a 1.1 line and installers are skipped', () {
      final candidates = classifyFixture(
        'github_releases_1.0.2.json',
        stableLine: const FreeCadVersion(1, 1),
      );

      expect(candidates, hasLength(5));
      expect(candidates.every((candidate) => candidate.channel == BuildChannel.legacy), isTrue);
      final linux = select(candidates, platform: BuildPlatform.linux, arch: BuildArch.x86_64)!;
      expect(linux.assetName, 'FreeCAD_1.0.2-conda-Linux-x86_64-py311.AppImage');
      expect(linux.pythonVersion, '3.11');
    });
  });

  group('catalog-derived channel transitions', () {
    test('1.1.3 flips from stable to legacy once 26.3 defines the line', () {
      final stable = classifyFixture(
        'github_releases_1.1.3.json',
        stableLine: const FreeCadVersion(1, 1),
      );
      expect(stable.every((candidate) => candidate.channel == BuildChannel.stable), isTrue);

      final legacy = classifyFixture(
        'github_releases_1.1.3.json',
        stableLine: const FreeCadVersion(26, 3),
      );
      expect(legacy.every((candidate) => candidate.channel == BuildChannel.legacy), isTrue);
      expect(
        legacy.every((candidate) => candidate.id.startsWith('legacy:1.1.3')),
        isTrue,
      );
    });

    test('release candidates stay rc under any derived line', () {
      final candidates = classifyFixture(
        'github_releases_26.3rc1.json',
        stableLine: const FreeCadVersion(26, 3),
      );
      expect(candidates.every((candidate) => candidate.channel == BuildChannel.rc), isTrue);
    });

    test('a newer line never reclassifies the line itself or newer versions', () {
      final candidates = classifyFixture(
        'github_releases_1.1.3.json',
        stableLine: const FreeCadVersion(1, 0),
      );
      expect(candidates.every((candidate) => candidate.channel == BuildChannel.stable), isTrue);
    });
  });

  group('pre-1.0 releases', () {
    test('are ignored by the classifier', () {
      for (final fixture in const [
        'github_releases_0.19.4.json',
        'github_releases_0.20.0.json',
        'github_releases_0.21.2.json',
      ]) {
        expect(classifyFixture(fixture), isEmpty, reason: fixture);
      }
    });
  });

  group('weekly channel', () {
    test('classifies dated weeklies and skips experimental and installers', () {
      final candidates = classifyFixture('github_releases_weekly.json');

      expect(candidates, hasLength(6));
      expect(candidates.every((candidate) => candidate.channel == BuildChannel.weekly), isTrue);
      expect(candidates.every((candidate) => candidate.weekly != null), isTrue);
    });

    test('prefers the highest macOS deployment target', () {
      final candidates = classifyFixture('github_releases_weekly.json');

      final macArm = select(candidates, platform: BuildPlatform.macos, arch: BuildArch.arm64)!;
      expect(macArm.assetName, 'FreeCAD_weekly-2026.09.16-macOS15-arm64.dmg');
      expect(macArm.macosMinVersion, 15);
    });

    test('parses the rolling weeklies tag', () {
      final candidates = classifyFixture('github_releases_weeklies.json');

      expect(candidates, hasLength(2));
      expect(candidates.first.versionLabel, 'weeklies');
      expect(candidates.first.weekly, isNull);
      final linux = select(candidates, platform: BuildPlatform.linux, arch: BuildArch.x86_64)!;
      expect(linux.assetName, 'FreeCAD_weekly-Linux-x86_64.AppImage');
    });
  });
}
