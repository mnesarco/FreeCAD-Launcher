// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    final head = utf8.decode(bytes.take(64).toList(), allowMalformed: true).trimLeft();
    if (head.startsWith('<?xml') || head.startsWith('<svg') || head.startsWith('<!')) {
      return SvgPicture.memory(bytes, width: size, height: size);
    }
    return Image.memory(
      bytes,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
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
