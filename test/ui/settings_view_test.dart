// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/log.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/domain/settings/app_settings.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/settings/settings_view.dart';
import 'package:freecad_launcher/ui/widgets/form_row.dart';

void main() {
  late Directory tempDirectory;
  late AppServices services;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_settings_ui');
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

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppScope(
          services: services,
          child: const Scaffold(body: SettingsView()),
        ),
      ),
    );
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> selectOption(WidgetTester tester, Type dropdown, String option) async {
    final finder = find.byType(dropdown);
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('renders the settings sections', (tester) async {
    await pumpSettings(tester);

    expect(find.text('General'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Command-line launcher'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Command-line launcher'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Diagnostics'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('GPL-3.0-or-later'), findsOneWidget);
  });

  testWidgets('persists the theme, cadence and log level', (tester) async {
    await pumpSettings(tester);

    await selectOption(tester, FormDropdown<AppThemeMode>, 'Light');
    expect(services.settings.themeMode.value, AppThemeMode.light);
    expect(
      await services.database.settingsDao.getValue(SettingsKeys.themeMode),
      'light',
    );

    await selectOption(tester, FormDropdown<UpdateCadence>, 'Weekly');
    expect(services.settings.updateCadence.value, UpdateCadence.weekly);
    expect(
      await services.database.settingsDao.getValue(SettingsKeys.updateCadence),
      'weekly',
    );

    await selectOption(tester, FormDropdown<LogLevel>, 'Debug');
    expect(services.settings.logLevel.value, LogLevel.debug);
    expect(
      await services.database.settingsDao.getValue(SettingsKeys.logLevel),
      'debug',
    );

    await selectOption(tester, FormDropdown<CacheRetention>, '7 days');
    expect(services.settings.cacheRetention.value, CacheRetention.days7);
    expect(
      await services.database.settingsDao.getValue(SettingsKeys.cacheRetention),
      '7',
    );
  });

  testWidgets('clears build downloads after confirmation', (tester) async {
    final archive = File('${services.paths.downloadsCacheDir}/build.zip')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1024, 0));
    await services.cache.refresh();
    await pumpSettings(tester);

    await tester.scrollUntilVisible(
      find.text('1 KiB'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 KiB'), findsOneWidget);

    final clear = find.widgetWithText(TextButton, 'Clear').first;
    await Scrollable.ensureVisible(tester.element(clear), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();

    expect(find.text('Clear build downloads?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Clear'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 KiB'), findsNothing);
    expect(archive.existsSync(), isFalse);
  });

  testWidgets('cancelling the build downloads clear keeps the cache', (tester) async {
    final archive = File('${services.paths.downloadsCacheDir}/build.zip')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1024, 0));
    await services.cache.refresh();
    await pumpSettings(tester);

    await tester.scrollUntilVisible(
      find.text('Cache'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final clear = find.widgetWithText(TextButton, 'Clear').first;
    await Scrollable.ensureVisible(tester.element(clear), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(archive.existsSync(), isTrue);
  });

  testWidgets('clean up now asks for confirmation and cancels safely', (tester) async {
    final archive = File('${services.paths.downloadsCacheDir}/build.zip')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1024, 0))
      ..setLastModifiedSync(DateTime.now().subtract(const Duration(days: 60)));
    await services.cache.refresh();
    await pumpSettings(tester);

    await tester.scrollUntilVisible(
      find.text('Cache'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final cleanUp = find.widgetWithText(TextButton, 'Clean up now');
    await Scrollable.ensureVisible(tester.element(cleanUp), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(cleanUp);
    await tester.pumpAndSettle();

    expect(find.text('Clean up downloads?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(archive.existsSync(), isTrue);
  });

  testWidgets('clean up now deletes only downloads older than the retention', (tester) async {
    final oldArchive = File('${services.paths.downloadsCacheDir}/old.zip')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1024, 0))
      ..setLastModifiedSync(DateTime.now().subtract(const Duration(days: 60)));
    final freshArchive = File('${services.paths.downloadsCacheDir}/fresh.zip')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1024, 0));
    await services.cache.refresh();
    await pumpSettings(tester);

    await tester.scrollUntilVisible(
      find.text('Cache'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final cleanUp = find.widgetWithText(TextButton, 'Clean up now');
    await Scrollable.ensureVisible(tester.element(cleanUp), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(cleanUp);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Clean up now'),
      ),
    );
    await tester.pumpAndSettle();

    expect(oldArchive.existsSync(), isFalse);
    expect(freshArchive.existsSync(), isTrue);
  });

  testWidgets('opens the About dialog with the FreeCAD logo and notices', (tester) async {
    await pumpSettings(tester);

    await tester.scrollUntilVisible(
      find.text('About FreeCAD Launcher'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('About FreeCAD Launcher'));
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(
      find.textContaining('trademarks of the FreeCAD Project Association AISBL'),
      findsOneWidget,
    );
    expect(
      find.textContaining('independent, community driven, open source project'),
      findsOneWidget,
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsNothing);
  });
}
