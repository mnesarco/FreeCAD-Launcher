// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later

/// One curated profile color. [seed] is the Material seed color (ARGB) stored in
/// `profiles.iconColor`; [id] maps to the localized swatch label.
class ProfilePaletteEntry {
  const ProfilePaletteEntry(this.id, this.seed);

  final String id;
  final int seed;
}

const profilePalettes = <ProfilePaletteEntry>[
  ProfilePaletteEntry('blue', 0xFF418FDE),
  ProfilePaletteEntry('teal', 0xFF00796B),
  ProfilePaletteEntry('green', 0xFF2E7D32),
  ProfilePaletteEntry('lime', 0xFF7CB342),
  ProfilePaletteEntry('amber', 0xFFF9A825),
  ProfilePaletteEntry('orange', 0xFFEF6C00),
  ProfilePaletteEntry('red', 0xFFCB333B),
  ProfilePaletteEntry('pink', 0xFFAD1457),
  ProfilePaletteEntry('purple', 0xFF6A1B9A),
  ProfilePaletteEntry('indigo', 0xFF3949AB),
];

const defaultProfileColor = 0xFF418FDE;

/// Stored values (including `null` from pre-palette rows) resolve to a seed.
int profileColorOf(int? stored) => stored ?? defaultProfileColor;

/// The palette entry whose seed matches [color], or `null` for custom values.
ProfilePaletteEntry? profilePaletteByColor(int color) {
  for (final entry in profilePalettes) {
    if (entry.seed == color) {
      return entry;
    }
  }
  return null;
}

/// First palette seed not present in [usedColors]; once every seed is used, the
/// least-used seed wins (ties keep the palette order), so colors stay balanced.
int nextProfileColor(Iterable<int?> usedColors) {
  final counts = <int, int>{};
  for (final color in usedColors) {
    if (color == null) {
      continue;
    }
    counts[color] = (counts[color] ?? 0) + 1;
  }
  ProfilePaletteEntry? best;
  var bestCount = 0;
  for (final entry in profilePalettes) {
    final count = counts[entry.seed] ?? 0;
    if (best == null || count < bestCount) {
      best = entry;
      bestCount = count;
    }
  }
  return best!.seed;
}
