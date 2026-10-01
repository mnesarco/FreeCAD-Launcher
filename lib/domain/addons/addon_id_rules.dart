// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:path/path.dart' as p;

const int maxAddonIdLength = 64;

enum AddonIdIssue { empty, tooLong, invalidCharacters, reserved }

AddonIdIssue? validateAddonId(String id) {
  final candidate = id.trim();
  if (candidate.isEmpty) {
    return AddonIdIssue.empty;
  }
  if (candidate.length > maxAddonIdLength) {
    return AddonIdIssue.tooLong;
  }
  if (candidate == '.' || candidate == '..') {
    return AddonIdIssue.reserved;
  }
  for (final unit in candidate.codeUnits) {
    if (unit < 32 || unit == 127) {
      return AddonIdIssue.invalidCharacters;
    }
  }
  if (candidate.contains(RegExp(r'[\\/:*?"<>|]'))) {
    return AddonIdIssue.invalidCharacters;
  }
  if (candidate.endsWith('.') || candidate.endsWith(' ')) {
    return AddonIdIssue.invalidCharacters;
  }
  return null;
}

String? addonIdFromRepositoryUrl(String repositoryUrl) {
  final uri = Uri.tryParse(repositoryUrl.trim());
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  final segments = uri.pathSegments
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) {
    return null;
  }
  var name = segments.last;
  if (name.toLowerCase().endsWith('.git')) {
    name = name.substring(0, name.length - 4);
  }
  final normalized = name.trim();
  return normalized.isEmpty ? null : normalized;
}

String? addonIdFromArchivePath(String archivePath) {
  var name = p.basename(archivePath.trim());
  final lower = name.toLowerCase();
  for (final suffix in const ['.tar.gz', '.tgz', '.zip', '.tar']) {
    if (lower.endsWith(suffix)) {
      name = name.substring(0, name.length - suffix.length);
      break;
    }
  }
  final normalized = name.trim();
  return normalized.isEmpty ? null : normalized;
}

String addonIdFromDirectory(String directoryPath) {
  final normalized = p.normalize(directoryPath.trim());
  return p.basename(normalized);
}
