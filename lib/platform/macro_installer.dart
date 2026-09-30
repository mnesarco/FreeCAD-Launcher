// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';

class MacroInstallResult {
  const MacroInstallResult({required this.fileName, required this.files});

  final String fileName;
  final List<String> files;
}

class MacroInstallException implements Exception {
  const MacroInstallException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'MacroInstallException: $message';
}

class MacroInstaller {
  const MacroInstaller();

  Future<MacroInstallResult> install({
    required MacroCatalogEntry macro,
    required String macroDirectory,
  }) async {
    final directory = Directory(macroDirectory);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    final files = <String>[];
    final target = File(p.join(macroDirectory, macro.fileName));
    final part = File('${target.path}.part');
    try {
      await part.writeAsString(macro.code, flush: true);
      if (target.existsSync()) {
        target.deleteSync();
      }
      await part.rename(target.path);
      files.add(target.path);

      for (final entry in macro.otherFilesData.entries) {
        if (entry.value.isEmpty || entry.value == 'ICON') {
          continue;
        }
        final relative = _safeRelative(entry.key);
        if (relative == null) {
          continue;
        }
        final file = File(p.join(macroDirectory, relative));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(base64Decode(entry.value), flush: true);
        files.add(file.path);
      }

      final iconName = macro.iconFileName;
      if (iconName != null && macro.xpm.trim().isNotEmpty) {
        final file = File(p.join(macroDirectory, iconName));
        await file.writeAsString(macro.xpm, flush: true);
        files.add(file.path);
      } else if (iconName != null && macro.iconBase64 != null) {
        final file = File(p.join(macroDirectory, iconName));
        await file.writeAsBytes(base64Decode(macro.iconBase64!), flush: true);
        files.add(file.path);
      }

      return MacroInstallResult(fileName: macro.fileName, files: files);
    } on Object catch (error) {
      throw MacroInstallException('Could not install macro ${macro.name}', cause: error);
    } finally {
      if (part.existsSync()) {
        try {
          part.deleteSync();
        } on Object {
          // The rename already consumed the part file.
        }
      }
    }
  }

  String? _safeRelative(String path) {
    final normalized = path.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
    final parts = normalized.split('/');
    if (parts.any((part) => part.isEmpty || part == '.' || part == '..')) {
      return null;
    }
    return p.joinAll(parts);
  }
}
