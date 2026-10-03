// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/ui/theme/app_colors.dart';
import 'package:freecad_launcher/ui/theme/app_theme.dart';

void main() {
  test('inputs use compact outline borders with 4 px corners', () {
    final theme = buildAppTheme(Brightness.dark);
    final input = theme.inputDecorationTheme;

    expect(input.isDense, isTrue);
    expect(input.contentPadding, isNull);

    final border = input.border;
    expect(border, isA<OutlineInputBorder>());
    expect(
      (border! as OutlineInputBorder).borderRadius,
      const BorderRadius.all(Radius.circular(4)),
    );
    expect(input.enabledBorder, isA<OutlineInputBorder>());
    expect(input.focusedBorder, isA<OutlineInputBorder>());
    expect(input.errorBorder, isA<OutlineInputBorder>());
  });

  test('uses the launcher brand seed for both brightnesses', () {
    for (final brightness in Brightness.values) {
      final theme = buildAppTheme(brightness);
      final expected = ColorScheme.fromSeed(
        seedColor: AppBrandColors.tuftsBlue,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      );
      expect(theme.brightness, brightness);
      expect(theme.colorScheme.primary, expected.primary);
    }
  });

  test('provides semantic status colors per brightness', () {
    expect(
      buildAppTheme(Brightness.light).extension<AppStatusColors>(),
      AppStatusColors.light,
    );
    expect(
      buildAppTheme(Brightness.dark).extension<AppStatusColors>(),
      AppStatusColors.dark,
    );
  });

  test('desktop surfaces are toned with rounded cards and branded rail', () {
    final theme = buildAppTheme(Brightness.dark);

    expect(theme.cardTheme.elevation, 0);
    expect(theme.cardTheme.color, theme.colorScheme.surfaceContainerLow);
    expect(
      (theme.cardTheme.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(12),
    );
    expect(
      theme.navigationRailTheme.indicatorColor,
      theme.colorScheme.primaryContainer,
    );
    expect(
      theme.filledButtonTheme.style?.shape?.resolve({}),
      isA<RoundedRectangleBorder>(),
    );
  });
}
