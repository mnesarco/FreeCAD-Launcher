// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

Future<int> directorySize(String root) async {
  var total = 0;
  final pending = <Directory>[Directory(root)];
  while (pending.isNotEmpty) {
    final directory = pending.removeLast();
    late final List<FileSystemEntity> entries;
    try {
      entries = await directory.list(followLinks: false).toList();
    } on FileSystemException {
      // Long paths or directories deleted mid-walk: skip the subtree.
      continue;
    }
    for (final entity in entries) {
      if (entity is File) {
        try {
          total += await entity.length();
        } on FileSystemException {
          // Files can disappear while walking; skip them.
        }
      } else if (entity is Directory) {
        pending.add(entity);
      }
    }
  }
  return total;
}
