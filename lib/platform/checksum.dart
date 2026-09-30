// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<String> sha256File(String path, {void Function(double fraction)? onProgress}) async {
  final file = File(path);
  final length = await file.length();
  final output = _DigestSink();
  final input = sha256.startChunkedConversion(output);

  var read = 0;
  await for (final chunk in file.openRead()) {
    input.add(chunk);
    read += chunk.length;
    if (length > 0) {
      onProgress?.call(read / length);
    }
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
