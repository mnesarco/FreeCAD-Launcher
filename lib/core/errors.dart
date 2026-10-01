// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
class AppError {
  const AppError({
    required this.message,
    this.detail,
    this.cause,
    this.stackTrace,
    this.retryable = false,
  });

  factory AppError.from(Object error, {StackTrace? stackTrace, bool retryable = false}) {
    return AppError(
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
      retryable: retryable,
    );
  }

  final String message;
  final String? detail;
  final Object? cause;
  final StackTrace? stackTrace;
  final bool retryable;

  AppError copyWith({String? message, String? detail, bool? retryable}) {
    return AppError(
      message: message ?? this.message,
      detail: detail ?? this.detail,
      cause: cause,
      stackTrace: stackTrace,
      retryable: retryable ?? this.retryable,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (detail != null && detail!.isNotEmpty) {
      buffer.write(' ($detail)');
    }
    return buffer.toString();
  }
}
