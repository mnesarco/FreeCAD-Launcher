// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/github_releases_client.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/domain/builds/release_info.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/platform/python_probe.dart';
import 'package:freecad_launcher/state/builds_controller.dart';
import 'package:http/http.dart' as http;

import '../data/test_fixtures.dart';
import '../helpers/test_database.dart';

ReleaseInfo versionRelease(String tag, List<String> assetNames) {
  return ReleaseInfo(
    tagName: tag,
    prerelease: false,
    htmlUrl: 'https://example.invalid/$tag',
    assets: [
      for (final name in assetNames)
        ReleaseAsset(name: name, downloadUrl: 'https://example.invalid/$name'),
    ],
  );
}

class _StaticCatalog implements ReleasesCatalog {
  _StaticCatalog(this._result, {List<ReleaseInfo> extra = const []}) : _extra = extra;

  final ReleasesCatalogResult _result;
  final List<ReleaseInfo> _extra;

  @override
  Duration get ttl => const Duration(hours: 6);

  @override
  int get maxPages => 5;

  @override
  Future<ReleasesCatalogResult> load({bool forceRefresh = false}) async {
    return ReleasesCatalogResult(
      releases: [..._result.releases, ..._extra],
      freshness: CatalogFreshness.refreshed,
      fetchedAt: _result.fetchedAt,
      rateLimit: _result.rateLimit,
      error: _result.error,
    );
  }
}

void main() {
  final skip = Platform.environment['FCL_REAL_STABLE_LINE'] != '1'
      ? 'Manual test: set FCL_REAL_STABLE_LINE=1 to fetch the real catalog'
      : null;

  test(
    'real catalog derives the stable line and fills the legacy and rc channels',
    () async {
      final root = Directory('/tmp/opencode/fcl_manual_stable_line_check');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      final paths = AppPaths(dataRoot: root.path);
      await paths.ensureBaseDirectories();
      final db = createTestDatabase();
      addTearDown(() async {
        await db.close();
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });

      final result = await ReleasesCatalog(
        client: GitHubReleasesClient(client: http.Client()),
        dao: db.catalogCacheDao,
        cacheDirectory: paths.githubCacheDir,
      ).load(forceRefresh: true);
      expect(result.releases, isNotEmpty);

      final runner = ProcessRunner();
      final controller = BuildsController(
        database: db,
        catalog: _StaticCatalog(result),
        downloader: Downloader(
          source: HttpDownloadSource(http.Client()),
          cacheDirectory: paths.downloadsCacheDir,
        ),
        installer: BuildInstaller(
          paths: paths,
          processRunner: runner,
          pythonProbe: ProcessPythonProbe(processRunner: runner),
        ),
        paths: paths,
        platform: BuildPlatform.linux,
        arch: BuildArch.x86_64,
      );

      await controller.loadCatalog();

      final line = controller.derivedStableLine.value;
      expect(line, isNotNull);
      final recomputed = FreeCadVersion.deriveStableLine(
        result.releases.map((release) => ReleaseTag.parse(release.tagName)?.version).nonNulls,
      );
      expect(line, recomputed);

      final stable = controller.availableBuilds.value;
      expect(stable, isNotEmpty);
      expect(
        stable.every(
          (candidate) =>
              candidate.channel == BuildChannel.stable &&
              candidate.version != null &&
              candidate.version!.compareTo(line!) >= 0,
        ),
        isTrue,
      );

      final legacy = controller.legacyBuilds.value;
      expect(legacy, isNotEmpty);
      expect(
        legacy.every(
          (candidate) =>
              candidate.channel == BuildChannel.legacy &&
              candidate.version != null &&
              candidate.version!.compareTo(line!) < 0,
        ),
        isTrue,
      );
      expect(
        legacy.map((candidate) => '${candidate.version!.major}.${candidate.version!.minor}'),
        contains('1.0'),
      );

      final rc = controller.rcBuilds.value;
      expect(
        rc.every(
          (candidate) => candidate.channel == BuildChannel.rc && candidate.version!.isPrerelease,
        ),
        isTrue,
      );
      expect(
        controller.weeklyBuilds.value.every(
          (candidate) => candidate.channel == BuildChannel.weekly,
        ),
        isTrue,
      );

      final identities = <String>{};
      for (final candidate in [...stable, ...legacy, ...rc]) {
        final key = [
          candidate.channel.name,
          candidate.version,
          candidate.platform.name,
          candidate.arch,
          candidate.kind.name,
        ].join('|');
        expect(identities.add(key), isTrue, reason: 'duplicate candidate $key');
      }

      // ignore: avoid_print
      print(
        'line=$line stable=${stable.length} newest=${stable.first.versionLabel} '
        'legacy=${legacy.length} newest=${legacy.first.versionLabel} '
        'oldest=${legacy.last.versionLabel} rc=${rc.length} '
        'weekly=${controller.weeklyBuilds.value.length}',
      );
      if (rc.isNotEmpty) {
        // ignore: avoid_print
        print('rc newest=${rc.first.versionLabel}');
      }
      controller.dispose();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'transition dry-run: a synthetic 26.3 flips the real 1.1.x line to legacy',
    () async {
      final root = Directory('/tmp/opencode/fcl_manual_stable_line_flip');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      final paths = AppPaths(dataRoot: root.path);
      await paths.ensureBaseDirectories();
      final db = createTestDatabase();
      addTearDown(() async {
        await db.close();
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });

      final result = await ReleasesCatalog(
        client: GitHubReleasesClient(client: http.Client()),
        dao: db.catalogCacheDao,
        cacheDirectory: paths.githubCacheDir,
      ).load(forceRefresh: true);

      String? newest11;
      FreeCadVersion? newest11Version;
      for (final release in result.releases) {
        final version = FreeCadVersion.tryParse(release.tagName);
        if (version == null || version.isPrerelease || !version.isSupported) {
          continue;
        }
        if (version.major != 1 || version.minor != 1) {
          continue;
        }
        if (newest11Version == null || version.compareTo(newest11Version) > 0) {
          newest11 = release.tagName;
          newest11Version = version;
        }
      }
      expect(newest11, isNotNull, reason: 'the real catalog must still list 1.1.x releases');

      final runner = ProcessRunner();
      final controller = BuildsController(
        database: db,
        catalog: _StaticCatalog(
          result,
          extra: [
            versionRelease('26.3', ['FreeCAD_26.3-Linux-x86_64-py311.AppImage']),
          ],
        ),
        downloader: Downloader(
          source: HttpDownloadSource(http.Client()),
          cacheDirectory: paths.downloadsCacheDir,
        ),
        installer: BuildInstaller(
          paths: paths,
          processRunner: runner,
          pythonProbe: ProcessPythonProbe(processRunner: runner),
        ),
        paths: paths,
        platform: BuildPlatform.linux,
        arch: BuildArch.x86_64,
      );
      controller.start();

      final buildId = 'stable:$newest11:linux:x86_64';
      await db.buildsDao.save(
        sampleBuild(id: buildId, version: newest11!, channel: BuildChannel.stable),
      );
      await Future<void>.delayed(Duration.zero);

      await controller.loadCatalog();

      expect(controller.derivedStableLine.value, const FreeCadVersion(26, 3));
      expect(controller.availableBuilds.value.map((candidate) => candidate.versionLabel), ['26.3']);
      expect(
        controller.legacyBuilds.value.map((candidate) => candidate.versionLabel),
        contains(newest11),
      );

      final stored = (await db.buildsDao.getById(buildId))!;
      expect(stored.channel, BuildChannel.legacy);
      expect(stored.id, buildId, reason: 'the row id and on-disk paths never change');

      final flipped = controller.legacyBuilds.value.firstWhere(
        (candidate) => candidate.versionLabel == newest11,
      );
      expect(
        controller.isInstalled(flipped),
        isTrue,
        reason: 'the reclassified release keeps its identity across the flip',
      );

      // ignore: avoid_print
      print(
        'flip: $newest11 stable→legacy, id=$buildId, '
        'legacy=${controller.legacyBuilds.value.length}, isInstalled=true',
      );
      controller.dispose();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
