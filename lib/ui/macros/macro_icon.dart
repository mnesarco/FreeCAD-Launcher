// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:freecad_launcher/domain/macros/macro_catalog_entry.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/widgets/raster_icon.dart';

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
    if (looksLikeSvg(bytes)) {
      return SvgPicture.memory(bytes, width: widget.size, height: widget.size);
    }
    return RasterIcon(bytes: bytes, size: widget.size, fallback: _fallback());
  }

  Widget _fallback() => Icon(Icons.auto_fix_high_outlined, size: widget.size);
}
