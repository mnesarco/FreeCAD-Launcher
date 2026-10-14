// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/profiles/profile_palette.dart';
import 'package:freecad_launcher/ui/theme/app_theme.dart';
import 'package:freecad_launcher/ui/theme/profile_palette_theme.dart';

double contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final hi = math.max(a, b);
  final lo = math.min(a, b);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const textMinimum = 4.5;

  group('profile palette contrast', () {
    for (final brightness in Brightness.values) {
      for (final entry in profilePalettes) {
        test('${entry.id} (${brightness.name}) meets WCAG on every used pair', () {
          final base = buildAppTheme(brightness);
          final scheme = profileColorScheme(entry.seed, brightness);
          final card = profileCardColor(scheme, brightness);
          final failures = <String>[];

          void check(String label, Color foreground, Color background, double minimum) {
            final ratio = contrast(foreground, background);
            if (ratio < minimum) {
              failures.add('$label ${ratio.toStringAsFixed(2)}:1 < $minimum:1');
            }
          }

          check('onSurface on card', base.colorScheme.onSurface, card, textMinimum);
          check('onSurfaceVariant on card', base.colorScheme.onSurfaceVariant, card, textMinimum);
          check(
            'onSecondaryContainer on secondaryContainer',
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
            textMinimum,
          );
          check(
            'onPrimaryContainer on primaryContainer',
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
            textMinimum,
          );
          check(
            'neutral badge text on surfaceContainerHighest',
            scheme.onSurfaceVariant,
            scheme.surfaceContainerHighest,
            textMinimum,
          );
          check(
            'onSurface on surfaceContainerLow',
            scheme.onSurface,
            scheme.surfaceContainerLow,
            textMinimum,
          );

          expect(failures, isEmpty, reason: failures.join('; '));
        });
      }
    }
  });
}
