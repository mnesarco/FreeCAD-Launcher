// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later

/// PEP 503 package-name normalization: lowercase and collapse runs of
/// `-`, `_` and `.` into a single `-`.
String normalizePythonPackageName(String name) {
  return name.trim().toLowerCase().replaceAll(RegExp(r'[-_.]+'), '-');
}
