// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

bool looksLikeSvg(Uint8List bytes) {
  var head = utf8.decode(bytes.take(64).toList(), allowMalformed: true).trimLeft();
  if (head.startsWith('\uFEFF')) {
    head = head.substring(1).trimLeft();
  }
  return head.startsWith('<?xml') || head.startsWith('<svg') || head.startsWith('<!');
}

class RasterIcon extends StatelessWidget {
  const RasterIcon({super.key, required this.bytes, required this.size, required this.fallback});

  final Uint8List bytes;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
