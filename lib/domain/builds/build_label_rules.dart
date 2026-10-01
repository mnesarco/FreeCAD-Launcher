// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
const int maxBuildLabelLength = 64;

enum BuildLabelIssue { tooLong, controlCharacters }

String? normalizeBuildLabel(String? label) {
  final trimmed = label?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

BuildLabelIssue? validateBuildLabel(String? label) {
  final normalized = normalizeBuildLabel(label);
  if (normalized == null) {
    return null;
  }
  if (normalized.length > maxBuildLabelLength) {
    return BuildLabelIssue.tooLong;
  }
  if (normalized.codeUnits.any((unit) => unit < 32 || unit == 127)) {
    return BuildLabelIssue.controlCharacters;
  }
  return null;
}
