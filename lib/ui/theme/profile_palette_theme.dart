// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// Material scheme derived from a profile palette seed. `on*` roles stay
/// contrast-correct for every component that consumes them.
ColorScheme profileColorScheme(int seed, Brightness brightness) {
  return ColorScheme.fromSeed(
    seedColor: Color(seed),
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
}

/// Tint strength of the profile color over the card surface. Kept low so the global
/// (non-palette) text colors keep their WCAG contrast on every palette (see
/// `test/ui/profile_palette_theme_test.dart`).
double profileCardTint(Brightness brightness) =>
    brightness == Brightness.dark ? 0.14 : 0.08;

/// The profile card background: a subtle palette tint over the base card surface.
Color profileCardColor(ColorScheme scheme, Brightness brightness) {
  return Color.alphaBlend(
    scheme.primary.withValues(alpha: profileCardTint(brightness)),
    scheme.surfaceContainerLow,
  );
}
