// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/path_segments.dart';

void main() {
  group('safePathSegment', () {
    test('keeps portable values unchanged', () {
      expect(safePathSegment('stable_1.1.3_windows_x86_64'), 'stable_1.1.3_windows_x86_64');
      expect(safePathSegment('weekly-2026.09.30'), 'weekly-2026.09.30');
      expect(safePathSegment('custom-5893cc6a-4462'), 'custom-5893cc6a-4462');
    });

    test('replaces catalog build id separators', () {
      expect(safePathSegment('stable:1.1.3:windows:x86_64'), 'stable_1.1.3_windows_x86_64');
      expect(
        safePathSegment('weekly:weekly-2026.09.30:linux:aarch64'),
        'weekly_weekly-2026.09.30_linux_aarch64',
      );
    });

    test('replaces spaces, punctuation and non-ascii characters', () {
      expect(safePathSegment('My Macro (v2)'), 'My_Macro_v2');
      expect(safePathSegment('café'), 'caf');
      expect(safePathSegment('日本'), 'unnamed');
    });

    test('drops leading and trailing dots and dashes', () {
      expect(safePathSegment('..'), 'unnamed');
      expect(safePathSegment('.hidden'), 'hidden');
      expect(safePathSegment('-foo-'), 'foo');
      expect(safePathSegment('  '), 'unnamed');
    });

    test('prefixes reserved Windows device names', () {
      expect(safePathSegment('CON'), '_CON');
      expect(safePathSegment('com1'), '_com1');
      expect(safePathSegment('Console'), 'Console');
    });

    test('uses the fallback for empty results', () {
      expect(safePathSegment('', fallback: 'build'), 'build');
    });
  });
}
