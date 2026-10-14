// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/profiles/profile_palette.dart';

void main() {
  test('palette has unique ids and seeds and includes the default', () {
    final ids = profilePalettes.map((entry) => entry.id).toSet();
    final seeds = profilePalettes.map((entry) => entry.seed).toSet();

    expect(ids, hasLength(profilePalettes.length));
    expect(seeds, hasLength(profilePalettes.length));
    expect(seeds, contains(defaultProfileColor));
    expect(profilePalettes, hasLength(10));
  });

  test('profileColorOf keeps stored values and defaults null', () {
    expect(profileColorOf(null), defaultProfileColor);
    expect(profileColorOf(0xFF00796B), 0xFF00796B);
  });

  test('profilePaletteByColor finds known seeds only', () {
    expect(profilePaletteByColor(defaultProfileColor)?.id, 'blue');
    expect(profilePaletteByColor(0xFF123456), isNull);
  });

  test('nextProfileColor picks the first unused seed', () {
    expect(nextProfileColor(const []), profilePalettes[0].seed);
    expect(nextProfileColor([profilePalettes[0].seed]), profilePalettes[1].seed);
    expect(
      nextProfileColor([profilePalettes[0].seed, null, profilePalettes[1].seed]),
      profilePalettes[2].seed,
    );
  });

  test('nextProfileColor cycles deterministically once all seeds are used', () {
    final all = profilePalettes.map((entry) => entry.seed).toList();

    expect(nextProfileColor(all), profilePalettes[0].seed);
    expect(nextProfileColor([...all, all.first]), profilePalettes[1].seed);
  });
}
