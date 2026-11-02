// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// Hashes [path] in a worker isolate so the UI isolate keeps pumping frames.
Future<String> sha256File(String path, {void Function(double fraction)? onProgress}) async {
  final progress = ReceivePort();
  final listener = onProgress;
  final SendPort? progressPort = listener == null ? null : progress.sendPort;
  var finished = false;
  if (listener != null && progressPort != null) {
    progress.listen((fraction) {
      if (!finished) {
        listener(fraction as double);
      }
    });
  }
  try {
    final digest = await _runSha256Isolate(path, progressPort);
    finished = true;
    return digest;
  } finally {
    progress.close();
  }
}

/// Kept separate so the spawned closure captures only sendable values.
Future<String> _runSha256Isolate(String path, SendPort? progress) =>
    Isolate.run(() => _sha256FileWorker(path, progress));

String _sha256FileWorker(String path, SendPort? progress) {
  final file = File(path);
  final length = file.lengthSync();
  final output = _DigestSink();
  final input = sha256.startChunkedConversion(output);
  final handle = file.openSync();
  try {
    var read = 0;
    while (true) {
      final chunk = handle.readSync(1 << 20);
      if (chunk.isEmpty) {
        break;
      }
      input.add(chunk);
      read += chunk.length;
      if (length > 0) {
        progress?.send(read / length);
      }
    }
  } finally {
    handle.closeSync();
  }
  input.close();

  return output.value!.toString();
}

class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

String sha256OfBytes(List<int> bytes) => sha256.convert(bytes).toString();

final RegExp _sha256Pattern = RegExp(r'\b([0-9a-fA-F]{64})\b');

String? parseSha256Text(String text) {
  final match = _sha256Pattern.firstMatch(text);
  return match?.group(1)?.toLowerCase();
}
