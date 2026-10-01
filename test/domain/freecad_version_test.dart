// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/builds/freecad_version.dart';

void main() {
  group('FreeCadVersion', () {
    test('parses two and three part versions', () {
      expect(FreeCadVersion.tryParse('1.1.3'), const FreeCadVersion(1, 1, 3));
      expect(FreeCadVersion.tryParse('0.21.2'), const FreeCadVersion(0, 21, 2));
      expect(FreeCadVersion.tryParse('1.0'), const FreeCadVersion(1, 0, 0));
      expect(FreeCadVersion.tryParse('weekly-2026.09.16'), isNull);
      expect(FreeCadVersion.tryParse('1.1.3-rc1'), isNull);
    });

    test('orders versions', () {
      expect(const FreeCadVersion(1, 1, 3).compareTo(const FreeCadVersion(1, 1, 2)), 1);
      expect(const FreeCadVersion(1, 1, 0).compareTo(const FreeCadVersion(1, 0, 2)), 1);
      expect(const FreeCadVersion(1, 0, 2).compareTo(const FreeCadVersion(0, 21, 2)), 1);
      expect(const FreeCadVersion(0, 21, 2) < const FreeCadVersion(1, 0, 0), isTrue);
      expect(const FreeCadVersion(1, 1, 3) >= const FreeCadVersion(1, 1, 3), isTrue);
    });

    test('marks supported pre-1.1 versions as legacy', () {
      expect(const FreeCadVersion(1, 0, 2).isLegacy, isTrue);
      expect(const FreeCadVersion(1, 1, 0).isLegacy, isFalse);
      expect(const FreeCadVersion(0, 21, 2).isLegacy, isFalse);
    });

    test('flags the 1.0 support floor', () {
      expect(const FreeCadVersion(0, 19, 4).isSupported, isFalse);
      expect(const FreeCadVersion(0, 21, 2).isSupported, isFalse);
      expect(const FreeCadVersion(1, 0, 0).isSupported, isTrue);
      expect(const FreeCadVersion(1, 1, 3).isSupported, isTrue);
    });
  });

  group('WeeklyVersion', () {
    test('parses dated weekly tags', () {
      final weekly = WeeklyVersion.tryParse('weekly-2026.09.16');

      expect(weekly, isNotNull);
      expect(weekly!.date, DateTime.utc(2026, 9, 16));
      expect(WeeklyVersion.tryParse('weeklies'), isNull);
    });

    test('orders by date', () {
      expect(
        WeeklyVersion.tryParse('weekly-2026.09.16')!.compareTo(
          WeeklyVersion.tryParse('weekly-2026.09.09')!,
        ),
        1,
      );
    });
  });

  group('ReleaseTag', () {
    test('classifies stable, legacy and weekly tags', () {
      expect(ReleaseTag.parse('1.1.3')!.channel, BuildChannel.stable);
      expect(ReleaseTag.parse('1.0.2')!.channel, BuildChannel.legacy);
      expect(ReleaseTag.parse('weekly-2026.09.16')!.channel, BuildChannel.weekly);
      expect(ReleaseTag.parse('weekly-2026.09.16')!.weekly, isNotNull);
      expect(ReleaseTag.parse('weeklies')!.channel, BuildChannel.weekly);
      expect(ReleaseTag.parse('weeklies')!.weekly, isNull);
    });

    test('ignores pre-1.0 releases', () {
      expect(ReleaseTag.parse('0.21.2'), isNull);
      expect(ReleaseTag.parse('0.20.0'), isNull);
      expect(ReleaseTag.parse('0.19.4'), isNull);
      expect(ReleaseTag.parse('0.19'), isNull);
    });

    test('rejects unknown tags', () {
      expect(ReleaseTag.parse('some-branch-2026.09.16'), isNull);
    });
  });
}
