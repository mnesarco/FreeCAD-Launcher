// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/core/errors.dart';

sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  AppError? get errorOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final error) => error,
  };

  R fold<R>(R Function(T value) onOk, R Function(AppError error) onErr) {
    return switch (this) {
      Ok<T>(:final value) => onOk(value),
      Err<T>(:final error) => onErr(error),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);

  final AppError error;
}
