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

    test('parses release candidate suffixes', () {
      expect(FreeCadVersion.tryParse('26.3rc1'), const FreeCadVersion(26, 3, 0, 1));
      expect(FreeCadVersion.tryParse('26.3.0rc2'), const FreeCadVersion(26, 3, 0, 2));
      expect(FreeCadVersion.tryParse('1.1rc3'), const FreeCadVersion(1, 1, 0, 3));
      expect(FreeCadVersion.tryParse('26.3'), const FreeCadVersion(26, 3, 0, 0));
      expect(FreeCadVersion.tryParse('26.3rc1')!.isPrerelease, isTrue);
      expect(FreeCadVersion.tryParse('26.3')!.isPrerelease, isFalse);
    });

    test('orders versions', () {
      expect(const FreeCadVersion(1, 1, 3).compareTo(const FreeCadVersion(1, 1, 2)), 1);
      expect(const FreeCadVersion(1, 1, 0).compareTo(const FreeCadVersion(1, 0, 2)), 1);
      expect(const FreeCadVersion(1, 0, 2).compareTo(const FreeCadVersion(0, 21, 2)), 1);
      expect(const FreeCadVersion(0, 21, 2) < const FreeCadVersion(1, 0, 0), isTrue);
      expect(const FreeCadVersion(1, 1, 3) >= const FreeCadVersion(1, 1, 3), isTrue);
    });

    test('orders release candidates below the final release', () {
      const rc1 = FreeCadVersion(26, 3, 0, 1);
      const rc2 = FreeCadVersion(26, 3, 0, 2);
      const final26 = FreeCadVersion(26, 3, 0);

      expect(rc1 < rc2, isTrue);
      expect(rc2 < final26, isTrue);
      expect(final26 >= final26, isTrue);
      expect(const FreeCadVersion(1, 1, 4) < rc1, isTrue);
      expect(rc1 == const FreeCadVersion(26, 3, 0, 1), isTrue);
      expect(rc1.hashCode, const FreeCadVersion(26, 3, 0, 1).hashCode);
    });

    test('marks supported pre-1.1 versions as legacy', () {
      expect(const FreeCadVersion(1, 0, 2).isLegacy, isTrue);
      expect(const FreeCadVersion(1, 1, 0).isLegacy, isFalse);
      expect(const FreeCadVersion(1, 1, 0, 3).isLegacy, isFalse);
      expect(const FreeCadVersion(0, 21, 2).isLegacy, isFalse);
    });

    test('flags the 1.0 support floor', () {
      expect(const FreeCadVersion(0, 19, 4).isSupported, isFalse);
      expect(const FreeCadVersion(0, 21, 2).isSupported, isFalse);
      expect(const FreeCadVersion(1, 0, 0, 1).isSupported, isFalse);
      expect(const FreeCadVersion(1, 0, 0).isSupported, isTrue);
      expect(const FreeCadVersion(1, 1, 3).isSupported, isTrue);
      expect(const FreeCadVersion(26, 3, 0, 1).isSupported, isTrue);
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
      expect(ReleaseTag.parse('26.3')!.channel, BuildChannel.stable);
      expect(ReleaseTag.parse('1.0.2')!.channel, BuildChannel.legacy);
      expect(ReleaseTag.parse('weekly-2026.09.16')!.channel, BuildChannel.weekly);
      expect(ReleaseTag.parse('weekly-2026.09.16')!.weekly, isNotNull);
      expect(ReleaseTag.parse('weeklies')!.channel, BuildChannel.weekly);
      expect(ReleaseTag.parse('weeklies')!.weekly, isNull);
    });

    test('classifies release candidates as their own channel', () {
      final rc = ReleaseTag.parse('26.3rc1')!;
      expect(rc.channel, BuildChannel.rc);
      expect(rc.version, isNotNull);
      expect(rc.version!.isPrerelease, isTrue);
      expect(ReleaseTag.parse('26.3rc2')!.channel, BuildChannel.rc);
      expect(ReleaseTag.parse('1.1rc3')!.channel, BuildChannel.rc);
    });

    test('ignores pre-1.0 releases', () {
      expect(ReleaseTag.parse('0.21.2'), isNull);
      expect(ReleaseTag.parse('0.20.0'), isNull);
      expect(ReleaseTag.parse('0.19.4'), isNull);
      expect(ReleaseTag.parse('0.19'), isNull);
      expect(ReleaseTag.parse('0.21rc1'), isNull);
    });

    test('rejects unknown tags', () {
      expect(ReleaseTag.parse('some-branch-2026.09.16'), isNull);
    });
  });
}
