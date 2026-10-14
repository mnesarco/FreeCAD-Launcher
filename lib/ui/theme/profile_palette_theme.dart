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
