// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/repositories/profiles_repository.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_manifest.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/state/profile_manifest_controller.dart';
import 'package:freecad_launcher/ui/profiles/profile_manifest_dialogs.dart';

import '../data/test_fixtures.dart';

void main() {
  late Directory tempDirectory;
  late AppPaths paths;
  late AppDatabase db;
  late AppServices services;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_manifest_ui');
    paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    db = AppDatabase.inMemory();
    final repository = ProfilesRepository(
      database: db,
      paths: paths,
      platform: BuildPlatform.linux,
    );
    services = AppServices(
      paths: paths,
      database: db,
      manifestsController: ProfileManifestController(
        database: db,
        repository: repository,
        paths: paths,
        platform: BuildPlatform.linux,
        arch: 'x86_64',
        installAddon:
            ({
              required String addonId,
              required String? branchRef,
              required String profileId,
              required bool installRequirements,
            }) async => const Ok(null),
        installPackages:
            ({required String profileId, required String specText, required String source}) async =>
                const Ok(null),
      ),
    );
    await db.buildsDao.save(sampleBuild());
    await repository.create(name: 'Dev', buildId: 'build-1');
  });

  tearDown(() async {
    await services.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  String manifestJson() {
    return encodeProfileManifest(
      ProfileManifest(
        exportedAt: DateTime.utc(2026, 9, 20, 10),
        source: const ManifestSource(os: 'linux', arch: 'x86_64'),
        profile: const ManifestProfileInfo(
          name: 'Dev',
          build: '1.1.3',
          channel: 'stable',
          python: '3.11',
        ),
        addons: const [ManifestAddon(id: 'A2plus', gitRef: 'master')],
        pythonPackages: const [ManifestPackage(name: 'numpy', version: '1.26.4', source: 'manual')],
        config: const {
          'user.cfg':
              '<FCParameters><FCText Name="ToolDir">/home/ana/tools</FCText></FCParameters>',
        },
        configFiles: const ['user.cfg'],
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showDialog<ManifestImportOutcome>(
                    context: context,
                    builder: (_) => ManifestImportDialog(jsonText: manifestJson()),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('previews the manifest with a clash-free name and path warnings', (tester) async {
    await openDialog(tester);

    expect(find.text('Import profile manifest'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Dev (imported)'), findsOneWidget);
    expect(find.text('1 addons'), findsOneWidget);
    expect(find.textContaining('/home/ana/tools'), findsWidgets);
    expect(find.text('Reinstall addons and Python packages'), findsOneWidget);
  });

  testWidgets('imports the profile and writes the config', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Import'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(ManifestImportDialog), findsNothing);
    final profile = await db.profilesDao.getByName('Dev (imported)');
    expect(profile, isNotNull);
    final config = File(paths.profilePaths(profile!.id).userCfg);
    expect(config.existsSync(), isTrue);
    expect(config.readAsStringSync(), contains('/home/ana/tools'));
  });
}
