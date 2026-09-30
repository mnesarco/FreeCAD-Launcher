// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/domain/builds/build_types.dart';

const int maxProfileNameLength = 64;

enum ProfileNameIssue { empty, tooLong, controlCharacters }

enum ProfileBindingIssue { buildNotInstalled, pythonNotDetected }

String normalizeProfileName(String name) => name.trim();

ProfileNameIssue? validateProfileName(String name) {
  final normalized = normalizeProfileName(name);
  if (normalized.isEmpty) {
    return ProfileNameIssue.empty;
  }
  if (normalized.length > maxProfileNameLength) {
    return ProfileNameIssue.tooLong;
  }
  if (normalized.codeUnits.any((unit) => unit < 32 || unit == 127)) {
    return ProfileNameIssue.controlCharacters;
  }
  return null;
}

ProfileBindingIssue? validateProfileBinding({
  required BuildStatus status,
  required String? pythonVersion,
}) {
  if (status != BuildStatus.installed) {
    return ProfileBindingIssue.buildNotInstalled;
  }
  if (pythonVersion == null || pythonVersion.trim().isEmpty) {
    return ProfileBindingIssue.pythonNotDetected;
  }
  return null;
}
