// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/ui/addons/addon_icon.dart';
import 'package:freecad_launcher/ui/widgets/raster_icon.dart';

const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

const _svg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1">'
    '<rect width="1" height="1"/></svg>';

String _svgBase64({bool bom = false}) => base64Encode(utf8.encode('${bom ? '\uFEFF' : ''}$_svg'));

void main() {
  test('svg detection tolerates a BOM and rejects bitmaps', () {
    expect(looksLikeSvg(Uint8List.fromList(utf8.encode(_svg))), isTrue);
    expect(looksLikeSvg(Uint8List.fromList(utf8.encode('\uFEFF$_svg'))), isTrue);
    expect(looksLikeSvg(base64Decode(_pngBase64)), isFalse);
  });

  testWidgets('raster icons render with high filtering and anti-aliasing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RasterIcon(
          bytes: base64Decode(_pngBase64),
          size: 40,
          fallback: const SizedBox.shrink(),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.filterQuality, FilterQuality.high);
    expect(image.isAntiAlias, isTrue);
  });

  testWidgets('addon icons dispatch svg and bitmap payloads', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AddonIcon(base64Data: _svgBase64(bom: true))));
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(RasterIcon), findsNothing);

    await tester.pumpWidget(MaterialApp(home: AddonIcon(base64Data: _pngBase64)));
    expect(find.byType(RasterIcon), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });
}
