// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

class NetworkProbeException implements Exception {
  const NetworkProbeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Performs one HTTPS request and completes when a response is received; any
/// HTTP status counts as reachable. On a TLS failure the exception includes
/// the presented certificate subject/issuer, so TLS inspection can be
/// identified from Settings → Diagnostics → Network.
Future<void> probeUri(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  X509Certificate? presented;
  client.badCertificateCallback = (certificate, host, port) {
    presented = certificate;
    return false;
  };
  try {
    final request = await client.headUrl(uri);
    final response = await request.close();
    await response.drain<void>();
  } on HandshakeException catch (error) {
    final certificate = presented;
    if (certificate != null) {
      throw NetworkProbeException(
        '${error.message}; presented certificate subject='
        '"${certificate.subject}" issuer="${certificate.issuer}"',
      );
    }
    rethrow;
  } finally {
    client.close(force: true);
  }
}
