// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/addons/addon.dart';
import 'package:freecad_launcher/domain/addons/addon_dependencies.dart';
import 'package:freecad_launcher/domain/addons/package_xml.dart';
import 'package:freecad_launcher/domain/python/requirements_parser.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/ui/addons/addon_dependencies_dialog.dart';

void main() {
  Addon addon(String id) => Addon(
    id: id,
    branches: [
      AddonBranch(
        gitRef: 'master',
        displayName: 'master',
        repositoryUrl: 'https://example.invalid/$id',
        zipUrl: 'https://example.invalid/$id.zip',
        curated: true,
        sparseCache: false,
        metadata: AddonMetadata(
          name: id,
          description: '',
          version: '1.0.0',
          license: null,
          minPython: '3.10',
          tags: const [],
          people: const [],
          content: const {AddonContentType.workbench},
          requirements: '',
        ),
      ),
    ],
  );

  AddonDependency addonDep(String name, {bool optional = false}) =>
      AddonDependency(name: name, type: AddonDependencyType.addon, optional: optional);

  ResolvedAddonDependency resolved(Addon target, {bool optional = false}) =>
      ResolvedAddonDependency(
        source: addonDep(target.id, optional: optional),
        kind: ResolvedDependencyKind.addon,
        declaredByAddonId: 'Root',
        addon: target,
        branchRef: 'master',
      );

  Future<void> openDialog(
    WidgetTester tester,
    AddonDependencyPlan plan,
    void Function(AddonDependencySelection?) onResult,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final value = await showAddonDependenciesDialog(
                context,
                addonName: 'Root',
                plan: plan,
              );
              onResult(value);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders every dependency section and selects optional entries', (tester) async {
    final plan = AddonDependencyPlan(
      requiredAddons: [resolved(addon('Curves'))],
      optionalAddons: [resolved(addon('SearchBar'), optional: true)],
      requiredPython: [
        ResolvedPythonRequirement(
          requirement: const PythonRequirement(raw: 'numpy', name: 'numpy'),
          optional: false,
          declaredByAddonId: 'Root',
        ),
      ],
      optionalPython: [
        ResolvedPythonRequirement(
          requirement: const PythonRequirement(raw: 'openpyxl', name: 'openpyxl'),
          optional: true,
          declaredByAddonId: 'Root',
        ),
      ],
      internalWorkbenches: const {'part', 'sketcher'},
    );
    AddonDependencySelection? result;
    await openDialog(tester, plan, (value) => result = value);

    expect(find.text('Required addons'), findsOneWidget);
    expect(find.text('Curves'), findsOneWidget);
    expect(find.text('Optional addons'), findsOneWidget);
    expect(find.text('SearchBar'), findsOneWidget);
    expect(find.text('Required Python packages'), findsOneWidget);
    expect(find.text('numpy'), findsOneWidget);
    expect(find.text('Optional Python packages'), findsOneWidget);
    expect(find.text('openpyxl'), findsOneWidget);
    expect(find.text('Provided by FreeCAD'), findsOneWidget);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'SearchBar'));
    await tester.ensureVisible(find.widgetWithText(CheckboxListTile, 'openpyxl'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'openpyxl'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Install dependencies'));
    await tester.pumpAndSettle();

    expect(result?.installRequired, isTrue);
    expect(result?.optionalAddonIds, {'SearchBar'});
    expect(result?.optionalPackageNames, {'openpyxl'});
  });

  testWidgets('addon only and cancel return the expected decisions', (tester) async {
    final plan = AddonDependencyPlan(requiredAddons: [resolved(addon('Curves'))]);

    AddonDependencySelection? result;
    var called = false;
    await openDialog(tester, plan, (value) {
      called = true;
      result = value;
    });
    await tester.tap(find.text('Addon only'));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(result?.installRequired, isFalse);

    called = false;
    result = null;
    await openDialog(tester, plan, (value) {
      called = true;
      result = value;
    });
    await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(result, isNull);
  });

  testWidgets('shows invalid requirements and unresolved entries', (tester) async {
    final plan = AddonDependencyPlan(
      invalidRequirements: const [
        PythonRequirement(raw: '-e git+https://example.invalid', name: '-e', valid: false),
      ],
      unresolved: const ['not-a-workbench'],
    );

    await openDialog(tester, plan, (_) {});

    expect(find.text('Invalid requirements'), findsOneWidget);
    expect(find.textContaining('Cannot parse'), findsOneWidget);
    expect(find.text('Unresolved dependencies'), findsOneWidget);
    expect(find.text('not-a-workbench'), findsOneWidget);
  });
}
