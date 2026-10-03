// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:freecad_launcher/ui/widgets/raster_icon.dart';

class AddonIcon extends StatelessWidget {
  const AddonIcon({super.key, this.base64Data, this.size = 40});

  final String? base64Data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.extension_outlined, size: size);
    final bytes = _decode(base64Data);
    if (bytes == null) {
      return fallback;
    }
    if (looksLikeSvg(bytes)) {
      return SizedBox(
        width: size,
        height: size,
        child: SvgPicture.memory(bytes, fit: BoxFit.contain),
      );
    }
    return RasterIcon(bytes: bytes, size: size, fallback: fallback);
  }

  static Uint8List? _decode(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      final bytes = base64Decode(value);
      return bytes.isEmpty ? null : Uint8List.fromList(bytes);
    } on FormatException {
      return null;
    }
  }
}
