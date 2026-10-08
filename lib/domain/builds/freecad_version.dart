// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/domain/builds/build_types.dart';

final RegExp _stableTag = RegExp(r'^(\d+)\.(\d+)(?:\.(\d+))?(?:rc(\d+))?$');
final RegExp _weeklyTag = RegExp(r'^weekly-(\d{4})\.(\d{2})\.(\d{2})$');

class FreeCadVersion implements Comparable<FreeCadVersion> {
  const FreeCadVersion(this.major, this.minor, [this.patch = 0, this.rc = 0]);

  final int major;
  final int minor;
  final int patch;
  final int rc;

  static const FreeCadVersion minSupported = FreeCadVersion(1, 0);

  static const FreeCadVersion stableLine = FreeCadVersion(1, 1);

  static FreeCadVersion? tryParse(String text) {
    final match = _stableTag.firstMatch(text.trim());
    if (match == null) {
      return null;
    }
    return FreeCadVersion(
      int.parse(match[1]!),
      int.parse(match[2]!),
      match[3] == null ? 0 : int.parse(match[3]!),
      match[4] == null ? 0 : int.parse(match[4]!),
    );
  }

  bool get isPrerelease => rc > 0;

  bool get isSupported => compareTo(minSupported) >= 0;

  bool get isLegacy => isSupported && !isPrerelease && compareTo(stableLine) < 0;

  bool operator <(FreeCadVersion other) => compareTo(other) < 0;

  bool operator >=(FreeCadVersion other) => compareTo(other) >= 0;

  @override
  int compareTo(FreeCadVersion other) {
    if (major != other.major) {
      return major.compareTo(other.major);
    }
    if (minor != other.minor) {
      return minor.compareTo(other.minor);
    }
    if (patch != other.patch) {
      return patch.compareTo(other.patch);
    }
    if (rc == other.rc) {
      return 0;
    }
    if (rc == 0) {
      return 1;
    }
    if (other.rc == 0) {
      return -1;
    }
    return rc.compareTo(other.rc);
  }

  @override
  bool operator ==(Object other) =>
      other is FreeCadVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch &&
      rc == other.rc;

  @override
  int get hashCode => Object.hash(major, minor, patch, rc);

  @override
  String toString() => '$major.$minor.$patch${rc == 0 ? '' : 'rc$rc'}';
}

class WeeklyVersion implements Comparable<WeeklyVersion> {
  const WeeklyVersion(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static WeeklyVersion? tryParse(String text) {
    final match = _weeklyTag.firstMatch(text.trim());
    if (match == null) {
      return null;
    }
    return WeeklyVersion(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  DateTime get date => DateTime.utc(year, month, day);

  @override
  int compareTo(WeeklyVersion other) => date.compareTo(other.date);

  @override
  bool operator ==(Object other) =>
      other is WeeklyVersion && year == other.year && month == other.month && day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'weekly-$year.${month.toString().padLeft(2, '0')}.'
      '${day.toString().padLeft(2, '0')}';
}

class ReleaseTag {
  const ReleaseTag({required this.raw, required this.channel, this.version, this.weekly});

  final String raw;
  final BuildChannel channel;
  final FreeCadVersion? version;
  final WeeklyVersion? weekly;

  static ReleaseTag? parse(String tag) {
    if (tag == 'weeklies') {
      return ReleaseTag(raw: tag, channel: BuildChannel.weekly);
    }
    final weekly = WeeklyVersion.tryParse(tag);
    if (weekly != null) {
      return ReleaseTag(raw: tag, channel: BuildChannel.weekly, weekly: weekly);
    }
    final version = FreeCadVersion.tryParse(tag);
    if (version != null && version.isSupported) {
      final channel = version.isPrerelease
          ? BuildChannel.rc
          : (version.isLegacy ? BuildChannel.legacy : BuildChannel.stable);
      return ReleaseTag(raw: tag, channel: channel, version: version);
    }
    return null;
  }
}
