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
      test('base card text meets WCAG (${brightness.name})', () {
        final scheme = buildAppTheme(brightness).colorScheme;

        expect(
          contrast(scheme.onSurface, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(textMinimum),
        );
        expect(
          contrast(scheme.onSurfaceVariant, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(textMinimum),
        );
      });

      for (final entry in profilePalettes) {
        test('${entry.id} (${brightness.name}) meets WCAG on every used pair', () {
          final baseScheme = buildAppTheme(brightness).colorScheme;
          final scheme = profileColorScheme(entry.seed, brightness);
          final seed = Color(entry.seed);
          final checkColor = seed.computeLuminance() > 0.179 ? Colors.black : Colors.white;
          final failures = <String>[];

          void check(String label, Color foreground, Color background, [double? minimum]) {
            final ratio = contrast(foreground, background);
            if (ratio < (minimum ?? textMinimum)) {
              failures.add(
                '$label ${ratio.toStringAsFixed(2)}:1 < ${minimum ?? textMinimum}:1',
              );
            }
          }

          check('profile name', scheme.primary, baseScheme.surfaceContainerLow);
          check('detail title', scheme.primary, baseScheme.surface);
          check('Launch button label', scheme.onSecondaryContainer, scheme.secondaryContainer);
          check('neutral badge text', scheme.onSurfaceVariant, scheme.surfaceContainerHighest);
          check('accent container pair', scheme.onPrimaryContainer, scheme.primaryContainer);
          check('swatch check on seed', checkColor, seed);

          expect(failures, isEmpty, reason: failures.join('; '));
        });
      }
    }
  });
}
