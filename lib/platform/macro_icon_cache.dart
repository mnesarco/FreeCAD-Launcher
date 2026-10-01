// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';

const Set<String> renderableMacroIconExtensions = {
  'svg',
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'bmp',
};

class MacroIconCache {
  MacroIconCache({required this.directory, this.maxBytes = 16 * 1024 * 1024});

  final String directory;
  final int maxBytes;

  final Map<String, Uint8List> _memory = <String, Uint8List>{};
  final Set<String> _failed = <String>{};
  int _memoryBytes = 0;

  static String? keyFor(String? base64) {
    final data = base64?.trim() ?? '';
    if (data.isEmpty) {
      return null;
    }
    return sha256.convert(utf8.encode(data)).toString();
  }

  static bool hasRenderableExtension(String extension) {
    final ext = extension.trim().toLowerCase();
    return ext.isEmpty || renderableMacroIconExtensions.contains(ext);
  }

  static String formatFor(String extension) {
    final ext = extension.trim().toLowerCase();
    if (ext == 'jpeg') {
      return 'jpg';
    }
    return renderableMacroIconExtensions.contains(ext) ? ext : 'bin';
  }

  Uint8List? resolve(MacroCatalogEntry macro) {
    final data = macro.iconBase64?.trim() ?? '';
    if (data.isEmpty || !hasRenderableExtension(macro.iconExtension)) {
      return null;
    }
    final key = keyFor(data)!;
    final cached = _memory.remove(key);
    if (cached != null) {
      _memory[key] = cached;
      return cached;
    }
    if (_failed.contains(key)) {
      return null;
    }

    final file = File(p.join(directory, '$key.${formatFor(macro.iconExtension)}'));
    try {
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        if (bytes.isNotEmpty) {
          _remember(key, bytes);
          return bytes;
        }
      }
    } on FileSystemException {
      // Fall through to decoding; the disk cache is best-effort.
    }

    final Uint8List bytes;
    try {
      bytes = base64Decode(data);
    } on FormatException {
      _failed.add(key);
      return null;
    }
    if (bytes.isEmpty) {
      _failed.add(key);
      return null;
    }
    _remember(key, bytes);
    _write(file, bytes);
    return bytes;
  }

  void _write(File file, Uint8List bytes) {
    try {
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes, flush: false);
    } on FileSystemException {
      // A failed write only costs a re-decode on the next run.
    }
  }

  void _remember(String key, Uint8List bytes) {
    final existing = _memory.remove(key);
    if (existing != null) {
      _memoryBytes -= existing.length;
    }
    _memory[key] = bytes;
    _memoryBytes += bytes.length;
    while (_memoryBytes > maxBytes && _memory.isNotEmpty) {
      final oldest = _memory.keys.first;
      _memoryBytes -= _memory.remove(oldest)!.length;
    }
  }

  void prune(Iterable<String> keepKeys) {
    final keep = keepKeys.toSet();
    final evicted = [
      for (final key in _memory.keys)
        if (!keep.contains(key)) key,
    ];
    for (final key in evicted) {
      _memoryBytes -= _memory.remove(key)!.length;
    }
    _failed.removeWhere((key) => !keep.contains(key));

    final dir = Directory(directory);
    if (!dir.existsSync()) {
      return;
    }
    for (final entity in dir.listSync()) {
      if (entity is! File) {
        continue;
      }
      if (keep.contains(p.basenameWithoutExtension(entity.path))) {
        continue;
      }
      try {
        entity.deleteSync();
      } on FileSystemException {
        continue;
      }
    }
  }
}
