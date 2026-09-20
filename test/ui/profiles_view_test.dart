import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/addons/addon_icon.dart';
import 'package:freecad_launcher/ui/profiles/profiles_view.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';

void main() {
  late Directory tempDirectory;
  late AppServices services;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_profiles_ui');
    final paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    services = AppServices(paths: paths, database: AppDatabase.inMemory());
  });

  tearDown(() async {
    await services.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> pumpProfiles(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppScope(
          services: services,
          child: const Scaffold(body: ProfilesView()),
        ),
      ),
    );
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('shows the empty state without profiles', (tester) async {
    await pumpProfiles(tester);

    expect(find.text('No profiles yet'), findsOneWidget);
    expect(find.text('New profile'), findsWidgets);
  });

  group('with a profile', () {
    setUp(() async {
      await services.database.buildsDao.save(sampleBuild());
      await services.profilesRepository.create(name: 'Dev', buildId: 'build-1');
      final profile = await services.profilesRepository.getByName('Dev');
      await services.database.installedAddonsDao.save(
        sampleAddon(
          profileId: profile!.id,
          addonId: 'A2plus',
          displayName: 'A2plus',
          version: '0.4.68',
        ),
      );
      await services.database.pythonPackagesDao.save(
        samplePackage(profileId: profile.id, name: 'numpy', version: '1.26.4'),
      );
    });

    testWidgets('renders the card with real data', (tester) async {
      await pumpProfiles(tester);

      expect(find.text('Dev'), findsOneWidget);
      expect(find.text('Launch'), findsOneWidget);
      expect(find.textContaining('Python 3.11'), findsOneWidget);
      expect(find.textContaining('Addons: 1'), findsOneWidget);
    });

    testWidgets('opens the detail tabs skeleton', (tester) async {
      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Backups'), findsOneWidget);
      expect(find.text('Addons'), findsWidgets);
      expect(find.textContaining('1.1.3'), findsWidgets);
    });

    testWidgets('lists installed macros in the profile detail', (tester) async {
      final profile = await services.profilesRepository.getByName('Dev');
      File(
        p.join(services.paths.profilePaths(profile!.id).macros, 'MyMacro.FCMacro'),
      ).createSync(recursive: true);
      await services.database.macrosDao.save(
        sampleMacro(
          profileId: profile.id,
          name: 'MyMacro',
          fileName: 'MyMacro.FCMacro',
        ),
      );
      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('Macros'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('MyMacro'), findsOneWidget);
    });

    testWidgets('shows the launch command dialog', (tester) async {
      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byTooltip('Show launch command'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Launch command'), findsOneWidget);
      expect(find.textContaining('user.cfg'), findsWidgets);
      expect(find.textContaining('FREECAD_USER_HOME'), findsWidgets);
      expect(find.text('Environment overrides'), findsOneWidget);
    });
    testWidgets('lists Python packages in the profile detail', (tester) async {
      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(
        find.descendant(of: find.byType(TabBar), matching: find.text('Python')),
      );
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('numpy'), findsOneWidget);
      expect(find.textContaining('v1.26.4'), findsOneWidget);
    });

    testWidgets('shows installed addons in the profile detail', (tester) async {
      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('Addons'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('A2plus'), findsOneWidget);
      expect(find.textContaining('v0.4.68'), findsOneWidget);
    });

    testWidgets('shows the catalog icon for installed addons', (tester) async {
      const iconBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
      services.addons.addons.value = [
        Addon(
          id: 'A2plus',
          branches: [
            AddonBranch(
              gitRef: 'master',
              displayName: 'master',
              repositoryUrl: 'https://example.invalid/A2plus',
              zipUrl: 'https://example.invalid/A2plus.zip',
              curated: true,
              sparseCache: false,
              metadata: AddonMetadata(
                name: 'A2plus',
                description: '',
                version: '0.4.68',
                license: 'MIT',
                minPython: '3.10',
                tags: const [],
                people: const [],
                content: const {AddonContentType.workbench},
                requirements: '',
                iconBase64: iconBase64,
              ),
            ),
          ],
        ),
      ];
      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('Addons'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final icon = tester.widget<AddonIcon>(
        find.descendant(
          of: find.widgetWithText(ListTile, 'A2plus'),
          matching: find.byType(AddonIcon),
        ),
      );
      expect(icon.base64Data, iconBase64);
    });
  });
}
