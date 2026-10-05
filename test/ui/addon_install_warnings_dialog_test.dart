// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/ui/addons/addon_install_warnings_dialog.dart';

void main() {
  testWidgets('lists the skipped entries and closes', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              await showAddonInstallWarningsDialog(
                context,
                addonName: 'History Workbench',
                warnings: const [
                  'docs-static-site/public/favicon.svg -> ../../freecad/history_wb/Logo.svg',
                  'docs-static-site/public/icons -> /home/flyer/Repositories/icons',
                ],
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Some files were skipped'), findsOneWidget);
    expect(
      find.text('docs-static-site/public/favicon.svg -> ../../freecad/history_wb/Logo.svg'),
      findsOneWidget,
    );
    expect(
      find.text('docs-static-site/public/icons -> /home/flyer/Repositories/icons'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });
}
