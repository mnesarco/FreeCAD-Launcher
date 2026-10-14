// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_palette.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/addons/addon_icon.dart';
import 'package:freecad_launcher/ui/profiles/profiles_view.dart';
import 'package:freecad_launcher/ui/theme/profile_palette_theme.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';
import '../helpers/fake_process.dart';

void main() {
  late Directory tempDirectory;
  late AppServices services;
  late FakeProcessLauncher launcher;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_profiles_ui');
    final paths = AppPaths(dataRoot: tempDirectory.path);
    await paths.ensureBaseDirectories();
    launcher = FakeProcessLauncher();
    services = AppServices(
      paths: paths,
      database: AppDatabase.inMemory(),
      processRunner: ProcessRunner(launcher: launcher),
    );
  });

  tearDown(() async {
    await services.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> pumpProfiles(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ProfilesView()),
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
    expect(find.text('Search profiles'), findsNothing);
  });

  testWidgets('creating a profile opens its detail view', (tester) async {
    await services.database.buildsDao.save(sampleBuild());
    await pumpProfiles(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'New profile').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Fresh');
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('1.1.3').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Backups'), findsOneWidget);
    expect(find.text('Fresh'), findsWidgets);
  });

  testWidgets('create dialog persists the selected profile color', (tester) async {
    await services.database.buildsDao.save(sampleBuild());
    await pumpProfiles(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'New profile').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Colored');
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('1.1.3').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Purple'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final created = await tester.runAsync(
      () => services.profilesRepository.getByName('Colored'),
    );
    final purple = profilePalettes.firstWhere((entry) => entry.id == 'purple');
    expect(created!.iconColor, purple.seed);
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
      expect(find.byTooltip('Launch'), findsOneWidget);
      expect(find.textContaining('Python 3.11'), findsOneWidget);
      expect(find.textContaining('Addons: 1'), findsOneWidget);
    });

    testWidgets('renders the profiles as a grid of cards', (tester) async {
      await pumpProfiles(tester);

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('tints the card and icon with the profile palette color', (tester) async {
      final profile = await services.profilesRepository.getByName('Dev');
      await services.profilesRepository.setColor(profileId: profile!.id, color: 0xFF6A1B9A);
      await pumpProfiles(tester);

      final scheme = profileColorScheme(0xFF6A1B9A, Brightness.light);
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, profileCardColor(scheme, Brightness.light));
      final icon = tester.widget<Icon>(find.byIcon(Icons.workspaces).first);
      expect(icon.color, scheme.primary);
    });

    testWidgets('edit dialog changes the profile color', (tester) async {
      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Teal'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final saved = await tester.runAsync(() => services.profilesRepository.getByName('Dev'));
      final teal = profilePalettes.firstWhere((entry) => entry.id == 'teal');
      expect(saved!.iconColor, teal.seed);
    });

    testWidgets('summarizes extra badges with an overflow chip in a narrow grid cell', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(340, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final profile = await services.profilesRepository.getByName('Dev');
      await services.database.buildsDao.save(sampleBuild(status: BuildStatus.missing));
      services.profiles.runningProfiles.value = {profile!.id};
      services.addons.installedAddons.value = [
        sampleAddon(profileId: profile.id, addonId: 'A2plus', version: '0.4.68'),
      ];
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
                version: '0.5.0',
                license: 'MIT',
                minPython: '3.10',
                tags: const [],
                people: const [],
                content: const {AddonContentType.workbench},
                requirements: '',
              ),
            ),
          ],
        ),
      ];

      await pumpProfiles(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('Build missing'), findsNothing);
      expect(find.byTooltip('Launch'), findsOneWidget);
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

    testWidgets('openProfile opens the detail view programmatically', (tester) async {
      final profile = await services.profilesRepository.getByName('Dev');
      await pumpProfiles(tester);

      tester.state<ProfilesViewState>(find.byType(ProfilesView)).openProfile(profile!.id);
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Backups'), findsOneWidget);
    });

    testWidgets('opens the profile folder from the detail header', (tester) async {
      final profile = await services.profilesRepository.getByName('Dev');
      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byTooltip('Open profile folder'));
      await tester.pump();
      launcher.handles.single.exit(0);
      await tester.pump();

      final expectedOpener = Platform.isWindows
          ? 'explorer.exe'
          : (Platform.isMacOS ? 'open' : 'xdg-open');
      expect(launcher.specs.single.executable, expectedOpener);
      expect(launcher.specs.single.arguments, [services.paths.profilePaths(profile!.id).root]);
    });

    testWidgets('opens the launch log from the profile overview', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final profile = await services.profilesRepository.getByName('Dev');
      final logPath = p.join(tempDirectory.path, 'logs', 'launch-Dev.log');
      File(logPath).createSync(recursive: true);
      services.profiles.launchLogs.value = {profile!.id: logPath};

      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final logFinder = find.textContaining('launch-Dev.log');
      await tester.ensureVisible(logFinder);
      await tester.pump();
      await tester.tap(logFinder);
      await tester.pump();
      launcher.handles.single.exit(0);
      await tester.pump();

      final expectedOpener = Platform.isWindows ? 'cmd' : (Platform.isMacOS ? 'open' : 'xdg-open');
      expect(launcher.specs.single.executable, expectedOpener);
      expect(
        launcher.specs.single.arguments,
        Platform.isWindows ? ['/c', 'start', '', logPath] : [logPath],
      );
    });

    testWidgets('lists installed macros in the profile detail', (tester) async {
      final profile = await services.profilesRepository.getByName('Dev');
      File(
        p.join(services.paths.profilePaths(profile!.id).macros, 'MyMacro.FCMacro'),
      ).createSync(recursive: true);
      await services.database.macrosDao.save(
        sampleMacro(profileId: profile.id, name: 'MyMacro', fileName: 'MyMacro.FCMacro'),
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

      await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('Python')));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('numpy'), findsOneWidget);
      expect(find.textContaining('v1.26.4'), findsOneWidget);
    });

    testWidgets('closing the Python install dialog does not reuse a disposed controller', (
      tester,
    ) async {
      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('Python')));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('Install packages'));
      await tester.pumpAndSettle();
      expect(find.text('Install Python packages'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'six');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
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

    testWidgets('toggles an installed addon with the ADDON_DISABLED marker', (tester) async {
      final profile = await services.profilesRepository.getByName('Dev');
      final marker = File(
        p.join(
          AppPaths(dataRoot: tempDirectory.path).profilePaths(profile!.id).mod,
          'A2plus',
          'ADDON_DISABLED',
        ),
      );
      marker.parent.createSync(recursive: true);

      await pumpProfiles(tester);
      await tester.tap(find.text('Dev'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.text('Addons'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final switchFinder = find.descendant(
        of: find.widgetWithText(ListTile, 'A2plus'),
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);
      expect(marker.existsSync(), isFalse);

      await tester.tap(switchFinder);
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(marker.existsSync(), isTrue);
      expect(services.addons.isAddonDisabled(profile.id, 'A2plus'), isTrue);
      expect(find.text('Disabled'), findsOneWidget);

      await tester.tap(switchFinder);
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(marker.existsSync(), isFalse);
      expect(find.text('Disabled'), findsNothing);
    });
  });

  group('search', () {
    setUp(() async {
      await services.database.buildsDao.save(sampleBuild());
      await services.profilesRepository.create(name: 'Dev', buildId: 'build-1');
      await services.profilesRepository.create(name: 'Prod', buildId: 'build-1');
    });

    testWidgets('filters profiles by name and clears with the suffix action', (tester) async {
      await pumpProfiles(tester);

      expect(find.text('Dev'), findsOneWidget);
      expect(find.text('Prod'), findsOneWidget);
      expect(find.byTooltip('Clear search'), findsNothing);

      await tester.enterText(find.byType(TextField), 'prod');
      await tester.pump();

      expect(find.text('Prod'), findsOneWidget);
      expect(find.text('Dev'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(find.text('Dev'), findsOneWidget);
      expect(find.text('Prod'), findsOneWidget);
    });

    testWidgets('shows the filtered-empty state', (tester) async {
      await pumpProfiles(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.text('No profiles match the current search.'), findsOneWidget);
      expect(find.text('Dev'), findsNothing);
      expect(find.text('Prod'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(find.text('Dev'), findsOneWidget);
      expect(find.text('Prod'), findsOneWidget);
    });

    testWidgets('focusSearch focuses the search field', (tester) async {
      await pumpProfiles(tester);

      tester.state<ProfilesViewState>(find.byType(ProfilesView)).focusSearch();
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.focusNode?.hasFocus, isTrue);
    });

    testWidgets('keeps the query when visiting a profile detail', (tester) async {
      await pumpProfiles(tester);
      await tester.enterText(find.byType(TextField), 'prod');
      await tester.pump();

      await tester.tap(find.text('Prod'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Overview'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Prod'), findsOneWidget);
      expect(find.text('Dev'), findsNothing);
    });
  });

  group('reordering', () {
    setUp(() async {
      await services.database.buildsDao.save(sampleBuild());
      await services.profilesRepository.create(name: 'First', buildId: 'build-1');
      await services.profilesRepository.create(name: 'Second', buildId: 'build-1');
    });

    Future<void> dragCard(WidgetTester tester, int from, int to) async {
      final cards = find.byType(Card);
      final start = tester.getCenter(cards.at(from));
      final end = tester.getCenter(cards.at(to));
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 600));
      for (var step = 1; step <= 10; step++) {
        await gesture.moveTo(Offset.lerp(start, end, step / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('reorders profiles with a long-press drag', (tester) async {
      await pumpProfiles(tester);

      await dragCard(tester, 0, 1);

      expect(
        [for (final profile in services.profiles.profiles.value) profile.name],
        ['Second', 'First'],
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(
        [for (final profile in await services.profilesRepository.getAll()) profile.name],
        ['Second', 'First'],
      );
    });

    testWidgets('does not reorder while the search filter is active', (tester) async {
      await pumpProfiles(tester);
      await tester.enterText(find.byType(TextField), 's');
      await tester.pump();

      await dragCard(tester, 0, 1);

      expect(
        [for (final profile in services.profiles.profiles.value) profile.name],
        ['First', 'Second'],
      );
    });
  });

  group('responsive header', () {
    setUp(() async {
      await services.database.buildsDao.save(sampleBuild());
      await services.profilesRepository.create(name: 'Dev', buildId: 'build-1');
    });

    testWidgets('falls back to icon-only actions on narrow windows', (tester) async {
      await tester.binding.setSurfaceSize(const Size(340, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpProfiles(tester);

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Import manifest'), findsOneWidget);
      expect(find.byTooltip('New profile'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Dev'), findsOneWidget);
    });

    testWidgets('keeps the labelled actions at normal widths', (tester) async {
      await pumpProfiles(tester);

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(OutlinedButton, 'Import manifest'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'New profile'), findsOneWidget);
      expect(find.byTooltip('Import manifest'), findsNothing);
    });

    testWidgets('compact header survives a running badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(340, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final profile = await services.profilesRepository.getByName('Dev');
      services.profiles.runningProfiles.value = {profile!.id};

      await pumpProfiles(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Running'), findsOneWidget);
    });
  });
}
