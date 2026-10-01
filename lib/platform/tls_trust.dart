// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

class TlsTrustResult {
  const TlsTrustResult({
    this.systemCertificates = 0,
    this.extraCertificates = 0,
    this.error,
  });

  final int systemCertificates;
  final int extraCertificates;
  final Object? error;

  bool get hasCertificates => systemCertificates > 0 || extraCertificates > 0;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('$systemCertificates system + $extraCertificates extra certificates');
    if (error != null) {
      buffer.write(' (error: $error)');
    }
    return buffer.toString();
  }
}

int countPemCertificates(String pem) =>
    '-----BEGIN CERTIFICATE-----'.allMatches(pem).length;

/// Extends Dart's built-in Mozilla root list (used on Windows) with the
/// Windows system stores and, optionally, a user-supplied PEM bundle
/// (`ca-bundle.pem`), so TLS-inspection and private CAs work.
TlsTrustResult installAdditionalTrust({String? extraBundlePath}) {
  var system = 0;
  var extra = 0;
  Object? error;
  if (Platform.isWindows) {
    try {
      final pem = loadWindowsSystemRootsPem();
      system = countPemCertificates(pem);
      if (pem.isNotEmpty) {
        SecurityContext.defaultContext.setTrustedCertificatesBytes(utf8.encode(pem));
      }
    } on Object catch (failure) {
      error = failure;
    }
  }
  if (extraBundlePath != null) {
    try {
      final file = File(extraBundlePath);
      if (file.existsSync()) {
        final pem = file.readAsStringSync();
        extra = countPemCertificates(pem);
        if (pem.trim().isNotEmpty) {
          SecurityContext.defaultContext.setTrustedCertificatesBytes(utf8.encode(pem));
        }
      }
    } on Object catch (failure) {
      error ??= failure;
    }
  }
  return TlsTrustResult(
    systemCertificates: system,
    extraCertificates: extra,
    error: error,
  );
}

/// Concatenates every certificate from the Windows `ROOT` and `CA` stores as
/// PEM, for both the machine and the current user. Returns an empty string
/// outside Windows.
String loadWindowsSystemRootsPem() {
  if (!Platform.isWindows) {
    return '';
  }
  final crypt32 = DynamicLibrary.open('crypt32.dll');
  final openStore = crypt32.lookupFunction<
      IntPtr Function(Pointer<Utf8>, Uint32, IntPtr, Uint32, Pointer<Utf16>),
      int Function(Pointer<Utf8>, int, int, int, Pointer<Utf16>)>('CertOpenStore');
  final enumCertificates = crypt32.lookupFunction<
      Pointer<_CertContext> Function(IntPtr, Pointer<_CertContext>),
      Pointer<_CertContext> Function(int, Pointer<_CertContext>)>(
    'CertEnumCertificatesInStore',
  );
  final closeStore = crypt32.lookupFunction<
      Int32 Function(IntPtr, Uint32),
      int Function(int, int)>('CertCloseStore');

  const certStoreProvSystemW = 10;
  const currentUser = 0x00010000;
  const localMachine = 0x00020000;
  final provider = Pointer<Utf8>.fromAddress(certStoreProvSystemW);

  final buffer = StringBuffer();
  final seen = <String>{};
  for (final location in const [localMachine, currentUser]) {
    for (final storeName in const ['ROOT', 'CA']) {
      final namePointer = storeName.toNativeUtf16();
      final store = openStore(provider, 0, 0, location, namePointer);
      calloc.free(namePointer);
      if (store == 0) {
        continue;
      }
      try {
        var context = enumCertificates(store, nullptr);
        while (context != nullptr) {
          final certificate = context.ref;
          final length = certificate.cbCertEncoded;
          if (certificate.pbCertEncoded != nullptr && length > 0) {
            final encoded = base64.encode(
              certificate.pbCertEncoded.asTypedList(length),
            );
            if (seen.add(encoded)) {
              buffer
                ..writeln('-----BEGIN CERTIFICATE-----')
                ..writeln(_wrapBase64(encoded))
                ..writeln('-----END CERTIFICATE-----');
            }
          }
          context = enumCertificates(store, context);
        }
      } finally {
        closeStore(store, 0);
      }
    }
  }
  return buffer.toString();
}

String _wrapBase64(String value) {
  const width = 64;
  final buffer = StringBuffer();
  for (var index = 0; index < value.length; index += width) {
    final end = index + width < value.length ? index + width : value.length;
    buffer.writeln(value.substring(index, end));
  }
  return buffer.toString().trimRight();
}

final class _CertContext extends Struct {
  @Uint32()
  external int dwCertEncodingType;

  external Pointer<Uint8> pbCertEncoded;

  @Uint32()
  external int cbCertEncoded;

  external Pointer<Void> pCertInfo;

  external Pointer<Void> hCertStore;
}
