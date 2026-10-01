// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';

void main() {
  group('Result', () {
    test('Ok exposes its value and no error', () {
      const Result<int> result = Ok(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.errorOrNull, isNull);
    });

    test('Err exposes its error and no value', () {
      const error = AppError(message: 'boom');
      const Result<int> result = Err(error);

      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, same(error));
    });

    test('fold dispatches to the matching branch', () {
      const Result<int> ok = Ok(1);
      const Result<int> err = Err(AppError(message: 'nope'));

      expect(ok.fold((value) => 'ok:$value', (error) => 'err'), 'ok:1');
      expect(err.fold((value) => 'ok:$value', (error) => 'err:${error.message}'), 'err:nope');
    });
  });

  group('AppError', () {
    test('from() captures the cause and is not retryable by default', () {
      final cause = StateError('broken');
      final error = AppError.from(cause, stackTrace: StackTrace.current);

      expect(error.cause, same(cause));
      expect(error.retryable, isFalse);
      expect(error.message, contains('broken'));
    });

    test('toString() includes the detail when present', () {
      const error = AppError(message: 'Download failed', detail: 'checksum mismatch');

      expect(error.toString(), 'Download failed (checksum mismatch)');
    });
  });
}
