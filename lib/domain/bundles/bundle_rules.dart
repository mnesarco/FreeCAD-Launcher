// SPDX-License-Identifier: GPL-3.0-or-later
const int maxBundleNameLength = 64;

enum BundleNameIssue { empty, tooLong, controlCharacters, duplicate }

String normalizeBundleName(String name) => name.trim();

BundleNameIssue? validateBundleName(
  String name, {
  required Iterable<String> existingNames,
  String? currentName,
}) {
  final normalized = normalizeBundleName(name);
  if (normalized.isEmpty) {
    return BundleNameIssue.empty;
  }
  if (normalized.length > maxBundleNameLength) {
    return BundleNameIssue.tooLong;
  }
  if (normalized.codeUnits.any((unit) => unit < 32 || unit == 127)) {
    return BundleNameIssue.controlCharacters;
  }
  final current = currentName == null ? null : normalizeBundleName(currentName).toLowerCase();
  final lower = normalized.toLowerCase();
  if (lower == current) {
    return null;
  }
  if (existingNames.any((name) => normalizeBundleName(name).toLowerCase() == lower)) {
    return BundleNameIssue.duplicate;
  }
  return null;
}
