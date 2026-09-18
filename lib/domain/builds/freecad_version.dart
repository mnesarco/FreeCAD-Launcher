import 'package:freecad_launcher/domain/builds/build_types.dart';

final RegExp _stableTag = RegExp(r'^(\d+)\.(\d+)(?:\.(\d+))?$');
final RegExp _weeklyTag = RegExp(r'^weekly-(\d{4})\.(\d{2})\.(\d{2})$');

class FreeCadVersion implements Comparable<FreeCadVersion> {
  const FreeCadVersion(this.major, this.minor, [this.patch = 0]);

  final int major;
  final int minor;
  final int patch;

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
    );
  }

  bool get isLegacy => compareTo(stableLine) < 0;

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
    return patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) =>
      other is FreeCadVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
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
    if (version != null) {
      return ReleaseTag(
        raw: tag,
        channel: version.isLegacy ? BuildChannel.legacy : BuildChannel.stable,
        version: version,
      );
    }
    return null;
  }
}
