// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later

final RegExp _unsafeSegmentCharacters = RegExp(r'[^A-Za-z0-9._-]+');
final RegExp _unsafeSegmentEdges = RegExp(r'^[-._]+|[-._]+$');
final RegExp _reservedWindowsNames = RegExp(
  r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$',
  caseSensitive: false,
);

String safePathSegment(String value, {String fallback = 'unnamed'}) {
  final normalized = value
      .trim()
      .replaceAll(_unsafeSegmentCharacters, '_')
      .replaceAll(_unsafeSegmentEdges, '');
  if (normalized.isEmpty) {
    return fallback;
  }
  return _reservedWindowsNames.hasMatch(normalized) ? '_$normalized' : normalized;
}
