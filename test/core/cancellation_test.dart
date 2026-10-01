// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/cancellation.dart';

void main() {
  test('listeners fire once on cancel', () {
    final token = CancellationToken();
    var calls = 0;
    token.addListener(() => calls++);

    token.cancel();
    token.cancel();

    expect(token.isCancelled, isTrue);
    expect(calls, 1);
  });

  test('adding a listener to a cancelled token fires immediately', () {
    final token = CancellationToken()..cancel();
    var called = false;

    token.addListener(() => called = true);

    expect(called, isTrue);
  });
}
