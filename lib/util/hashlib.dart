import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

String sha1Hash(String data) {
  final bytes = utf8.encode(data);
  final digest = sha1.convert(bytes);
  return digest.toString();
}

String generateRandomHex([int length = 32]) {
  final random = Random.secure();
  final values = List<int>.generate(length, (_) => random.nextInt(256));
  return values.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
