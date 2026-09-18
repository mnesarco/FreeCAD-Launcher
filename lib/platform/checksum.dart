import 'dart:io';

import 'package:crypto/crypto.dart';

Future<String> sha256File(String path) async {
  final digest = await sha256.bind(File(path).openRead()).first;
  return digest.toString();
}

String sha256OfBytes(List<int> bytes) => sha256.convert(bytes).toString();

final RegExp _sha256Pattern = RegExp(r'\b([0-9a-fA-F]{64})\b');

String? parseSha256Text(String text) {
  final match = _sha256Pattern.firstMatch(text);
  return match?.group(1)?.toLowerCase();
}
