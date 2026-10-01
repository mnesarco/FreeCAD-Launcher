// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/domain/builds/freecad_version.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';

String buildVersionLabel(String version, AppLocalizations l10n) {
  final weekly = WeeklyVersion.tryParse(version);
  if (weekly == null) {
    return version;
  }
  final date = weekly.date;
  String two(int part) => part.toString().padLeft(2, '0');
  return l10n.versionsWeeklyBuild('${date.year}-${two(date.month)}-${two(date.day)}');
}
