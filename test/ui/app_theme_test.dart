// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/app.dart';

void main() {
  test('inputs use compact outline borders with 4 px corners', () {
    final theme = buildAppTheme(Brightness.dark);
    final input = theme.inputDecorationTheme;

    expect(input.isDense, isTrue);
    expect(input.contentPadding, isNull);

    final border = input.border;
    expect(border, isA<OutlineInputBorder>());
    expect(
      (border! as OutlineInputBorder).borderRadius,
      const BorderRadius.all(Radius.circular(4)),
    );
    expect(input.enabledBorder, isA<OutlineInputBorder>());
    expect(input.focusedBorder, isA<OutlineInputBorder>());
    expect(input.errorBorder, isA<OutlineInputBorder>());
  });
}
