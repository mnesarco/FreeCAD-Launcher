import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/app.dart';

void main() {
  test('inputs use compact rounded outline borders', () {
    final theme = buildAppTheme(Brightness.dark);
    final input = theme.inputDecorationTheme;

    expect(input.isDense, isTrue);
    expect(input.contentPadding, const EdgeInsets.symmetric(horizontal: 10, vertical: 10));

    final border = input.border;
    expect(border, isA<OutlineInputBorder>());
    expect(
      (border! as OutlineInputBorder).borderRadius,
      const BorderRadius.all(Radius.circular(8)),
    );
    expect(input.enabledBorder, isA<OutlineInputBorder>());
    expect(input.focusedBorder, isA<OutlineInputBorder>());
    expect(input.errorBorder, isA<OutlineInputBorder>());
  });
}
