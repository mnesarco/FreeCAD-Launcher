// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/state/app_services.dart';

class MacroIcon extends StatefulWidget {
  const MacroIcon({super.key, this.macro, this.size = 40});

  final MacroCatalogEntry? macro;
  final double size;

  @override
  State<MacroIcon> createState() => _MacroIconState();
}

class _MacroIconState extends State<MacroIcon> {
  Uint8List? _bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bytes ??= _resolve();
  }

  @override
  void didUpdateWidget(MacroIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.macro, widget.macro)) {
      _bytes = _resolve();
    }
  }

  Uint8List? _resolve() {
    final macro = widget.macro;
    if (macro == null) {
      return null;
    }
    return AppScope.of(context).macroIcons.resolve(macro);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      return _fallback();
    }
    if (_looksLikeSvg(bytes)) {
      return SvgPicture.memory(bytes, width: widget.size, height: widget.size);
    }
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return Image.memory(
      bytes,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      cacheWidth: (widget.size * ratio).round(),
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() => Icon(Icons.auto_fix_high_outlined, size: widget.size);

  static bool _looksLikeSvg(Uint8List bytes) {
    final head = utf8.decode(bytes.take(64).toList(), allowMalformed: true).trimLeft();
    return head.startsWith('<?xml') || head.startsWith('<svg') || head.startsWith('<!');
  }
}
