import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/builds/asset_classifier.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/build_installer.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/builds_controller.dart';
import 'package:freecad_launcher/ui/builds/builds_view.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_download.dart';

class FakeReleasesCatalog implements ReleasesCatalog {
  int loadCount = 0;

  @override
  Duration get ttl => const Duration(hours: 6);

  @override
  int get maxPages => 5;

  @override
  Future<ReleasesCatalogResult> load({bool forceRefresh = false}) async {
    loadCount++;
    return const ReleasesCatalogResult(releases: [], freshness: CatalogFreshness.fresh);
  }
}

class FakeInstaller implements BuildInstaller {
  @override
  Future<InstalledBuild> install(InstallRequest request) async {
    return const InstalledBuild(
      directory: '/data/builds/x',
      executablePath: '/data/builds/x/FreeCAD',
      sizeBytes: 100,
      pythonVersion: '3.11',
      pythonPath: '/data/builds/x/bin/python3.11',
    );
  }
}

BuildCandidate sampleCandidate() {
  return BuildCandidate(
    versionLabel: '1.1.3',
    channel: BuildChannel.stable,
    platform: BuildPlatform.linux,
    arch: BuildArch.x86_64,
    kind: BuildKind.appimage,
    assetName: 'FreeCAD_1.1.3-Linux-x86_64-py311.AppImage',
    downloadUrl: 'https://example.invalid/1.1.3.AppImage',
    sizeBytes: 820 * 1024 * 1024,
    pythonVersion: '3.11',
    version: FreeCadVersion.tryParse('1.1.3'),
  );
}

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late AppDatabase database;
  late BuildsController controller;
  late AppServices services;
  late FakeReleasesCatalog catalog;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_builds_ui');
    paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    database = AppDatabase.inMemory();
    catalog = FakeReleasesCatalog();
    controller = BuildsController(
      database: database,
      catalog: catalog,
      downloader: Downloader(
        source: FakeDownloadSource(),
        cacheDirectory: paths.downloadsCacheDir,
      ),
      installer: FakeInstaller(),
      paths: paths,
      platform: BuildPlatform.linux,
      arch: BuildArch.x86_64,
    );
    services = AppServices(
      paths: paths,
      database: database,
      buildsController: controller,
    );
  });

  tearDown(() async {
    await services.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> pumpBuilds(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: BuildsView()),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Available'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders an active install without overflowing the tile', (tester) async {
    final candidate = sampleCandidate();
    controller.availableBuilds.value = [candidate];
    controller.installProgress.value = {
      candidate.id: const InstallProgress(
        stage: InstallStage.downloading,
        fraction: 0.42,
        receivedBytes: 345 * 1024 * 1024,
        totalBytes: 820 * 1024 * 1024,
        bytesPerSecond: 512 * 1024,
      ),
    };

    await pumpBuilds(tester);

    expect(find.textContaining('Downloading…'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.textContaining('/ 820.0 MiB'), findsOneWidget);
    expect(find.textContaining('512 KiB/s'), findsOneWidget);
  });

  testWidgets('keeps the progress detail on one line for long byte counts', (tester) async {
    final candidate = sampleCandidate();
    controller.availableBuilds.value = [candidate];
    controller.installProgress.value = {
      candidate.id: const InstallProgress(
        stage: InstallStage.hashing,
        fraction: 0.1,
        receivedBytes: 12 * 1024 * 1024 * 1024,
        totalBytes: 120 * 1024 * 1024 * 1024,
        bytesPerSecond: 1024 * 1024,
      ),
    };

    await pumpBuilds(tester);

    final detail = tester.widget<Text>(find.textContaining('12.00 GiB'));
    expect(detail.maxLines, 1);
    expect(detail.overflow, TextOverflow.ellipsis);
  });

  testWidgets('flags a newer stable release on installed builds', (tester) async {
    await tester.runAsync(() async {
      final buildDirectory = Directory(paths.buildDir('build-1'));
      buildDirectory.createSync(recursive: true);
      final executable = File(p.join(buildDirectory.path, 'FreeCAD'))..writeAsStringSync('');
      await database.buildsDao.save(
        sampleBuild(version: '1.1.3').copyWith(localPath: executable.path),
      );
    });
    controller.availableBuilds.value = [
      BuildCandidate(
        versionLabel: '2.0.0',
        channel: BuildChannel.stable,
        platform: BuildPlatform.linux,
        arch: BuildArch.x86_64,
        kind: BuildKind.appimage,
        assetName: 'FreeCAD_2.0.0-Linux-x86_64-py311.AppImage',
        downloadUrl: 'https://example.invalid/2.0.0.AppImage',
        sizeBytes: 820 * 1024 * 1024,
        pythonVersion: '3.11',
        version: FreeCadVersion.tryParse('2.0.0'),
      ),
    ];

    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: BuildsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.1.3 → 2.0.0'), findsOneWidget);
  });

  testWidgets('renames an installed build and resets it to its version', (tester) async {
    await tester.runAsync(() async {
      final buildDirectory = Directory(paths.buildDir('build-1'));
      buildDirectory.createSync(recursive: true);
      final executable = File(p.join(buildDirectory.path, 'FreeCAD'))..writeAsStringSync('');
      await database.buildsDao.save(
        sampleBuild(version: '1.1.3', label: 'Stable dev')
            .copyWith(localPath: executable.path),
      );
    });

    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: BuildsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stable dev'), findsOneWidget);

    await tester.tap(find.byTooltip('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My build');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('My build'), findsOneWidget);
    expect(find.text('Stable dev'), findsNothing);

    await tester.tap(find.byTooltip('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('1.1.3'), findsOneWidget);
    expect(find.text('My build'), findsNothing);
  });

  testWidgets('loads the catalog on the first Available visit and not again', (tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: BuildsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(catalog.loadCount, 0);

    await tester.tap(find.text('Available'));
    await tester.pumpAndSettle();
    expect(catalog.loadCount, 1);

    await tester.tap(find.text('Installed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Available'));
    await tester.pumpAndSettle();
    expect(catalog.loadCount, 1);
  });

  testWidgets('remove dialog uses in-place wording for referenced builds', (tester) async {
    await tester.runAsync(() async {
      final buildDirectory = Directory(paths.buildDir('managed-1'));
      buildDirectory.createSync(recursive: true);
      final executable = File(p.join(buildDirectory.path, 'FreeCAD'))..writeAsStringSync('');
      await database.buildsDao.save(
        sampleBuild(id: 'managed-1').copyWith(localPath: executable.path),
      );
      await database.buildsDao.save(
        sampleBuild(
          id: 'custom-1',
          version: 'my-freecad',
          kind: BuildKind.custom,
          channel: BuildChannel.custom,
          assetName: 'my-freecad',
          pythonVersion: null,
        ),
      );
    });

    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: BuildsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> openRemoveDialog(String label) async {
      final tile = find.ancestor(of: find.text(label), matching: find.byType(ListTile));
      await tester.tap(find.descendant(of: tile, matching: find.byTooltip('Remove')));
      await tester.pumpAndSettle();
    }

    await openRemoveDialog('my-freecad');
    expect(find.textContaining('stays where it is'), findsOneWidget);
    expect(find.textContaining('will be deleted from disk'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await openRemoveDialog('1.1.3');
    expect(find.textContaining('will be deleted from disk'), findsOneWidget);
  });

  testWidgets('keeps the custom import form across tab switches', (tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: BuildsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '/tmp/open/my-build.AppImage');

    await tester.tap(find.text('Installed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    expect(find.text('/tmp/open/my-build.AppImage'), findsOneWidget);
  });
}
