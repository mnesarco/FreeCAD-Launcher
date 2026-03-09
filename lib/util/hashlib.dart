import 'dart:convert';
import 'package:crypto/crypto.dart';

String sha1Hash(String data) {
  final bytes = utf8.encode(data);
  final digest = sha1.convert(bytes);
  return digest.toString();
}
