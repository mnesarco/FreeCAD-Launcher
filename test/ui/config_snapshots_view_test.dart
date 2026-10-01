// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/profiles/profile_detail_view.dart';
import 'package:path/path.dart' as p;

import '../data/test_fixtures.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase db;
  late AppServices services;
  late File userCfg;

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_config_ui');
    final paths = AppPaths(dataRoot: tempDirectory.path);
    db = AppDatabase.inMemory();
    services = AppServices(paths: paths, database: db);
    await db.buildsDao.save(sampleBuild());
    await db.profilesDao.save(sampleProfile());
    userCfg = File(p.join(paths.profilePaths('profile-1').root, 'user.cfg'))
      ..createSync(recursive: true)
      ..writeAsStringSync('<user/>');
  });

  tearDown(() async {
    await services.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('shows config paths and backs up then restores the config', (tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileDetailView(profileId: 'profile-1', onBack: () {}),
          ),
        ),
      ),
    );
    services.profiles.start();
    await settle(tester);

    await tester.tap(find.text('Config'));
    await settle(tester);

    expect(find.textContaining('user.cfg'), findsWidgets);
    expect(find.text('No config snapshots yet.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Back up config'));
    await settle(tester);

    expect(find.text('Config backed up'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
    expect(
      Directory(p.join(tempDirectory.path, 'profiles', 'profile-1', 'backups')).existsSync(),
      isTrue,
    );

    userCfg.writeAsStringSync('<changed/>');
    await tester.tap(find.text('Restore'));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Restore'),
      ),
    );
    await settle(tester);

    await tester.pump(const Duration(seconds: 5));
    await settle(tester);
    expect(find.text('Config restored'), findsOneWidget);
    expect(userCfg.readAsStringSync(), '<user/>');
  });
}
