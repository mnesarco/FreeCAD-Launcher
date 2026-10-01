// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

class SystemTrustBundle {
  const SystemTrustBundle({
    this.pem = '',
    this.machineCertificates = 0,
    this.userCertificates = 0,
  });

  final String pem;
  final int machineCertificates;
  final int userCertificates;

  int get totalCertificates => machineCertificates + userCertificates;
}

class TlsTrustResult {
  const TlsTrustResult({
    this.machineCertificates = 0,
    this.userCertificates = 0,
    this.extraCertificates = 0,
    this.error,
  });

  final int machineCertificates;
  final int userCertificates;
  final int extraCertificates;
  final Object? error;

  int get systemCertificates => machineCertificates + userCertificates;

  bool get hasCertificates => systemCertificates > 0 || extraCertificates > 0;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write(
        '$systemCertificates system (machine $machineCertificates, '
        'user $userCertificates) + $extraCertificates extra certificates',
      );
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
  var machine = 0;
  var user = 0;
  var extra = 0;
  Object? error;
  if (Platform.isWindows) {
    try {
      final bundle = loadWindowsSystemTrustBundle();
      machine = bundle.machineCertificates;
      user = bundle.userCertificates;
      if (bundle.pem.isNotEmpty) {
        SecurityContext.defaultContext.setTrustedCertificatesBytes(utf8.encode(bundle.pem));
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
    machineCertificates: machine,
    userCertificates: user,
    extraCertificates: extra,
    error: error,
  );
}

/// Concatenates every certificate from the Windows `ROOT` and `CA` stores as
/// PEM, for both the machine and the current user. Returns an empty bundle
/// outside Windows.
SystemTrustBundle loadWindowsSystemTrustBundle() {
  if (!Platform.isWindows) {
    return const SystemTrustBundle();
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
  const localMachineGroupPolicy = 0x00030000;
  const localMachineEnterprise = 0x00040000;
  const currentUserGroupPolicy = 0x00050000;
  final provider = Pointer<Utf8>.fromAddress(certStoreProvSystemW);

  final buffer = StringBuffer();
  final seen = <String>{};
  var machine = 0;
  var user = 0;
  for (final location in const [
    (flags: localMachine, machine: true),
    (flags: localMachineGroupPolicy, machine: true),
    (flags: localMachineEnterprise, machine: true),
    (flags: currentUser, machine: false),
    (flags: currentUserGroupPolicy, machine: false),
  ]) {
    for (final storeName in const ['ROOT', 'CA']) {
      final namePointer = storeName.toNativeUtf16();
      final store = openStore(provider, 0, 0, location.flags, namePointer);
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
              if (location.machine) {
                machine++;
              } else {
                user++;
              }
            }
          }
          context = enumCertificates(store, context);
        }
      } finally {
        closeStore(store, 0);
      }
    }
  }
  if (machine + user == 0) {
    final fallback = loadUserStoresBundle();
    if (fallback.totalCertificates > 0) {
      return fallback;
    }
  }
  return SystemTrustBundle(
    pem: buffer.toString(),
    machineCertificates: machine,
    userCertificates: user,
  );
}

/// Legacy user-store loader used as a fallback for environments where
/// `CertOpenStore` cannot open the system stores.
SystemTrustBundle loadUserStoresBundle() {
  final crypt32 = DynamicLibrary.open('crypt32.dll');
  final openStore = crypt32.lookupFunction<
      IntPtr Function(IntPtr, Pointer<Utf16>),
      int Function(int, Pointer<Utf16>)>('CertOpenSystemStoreW');
  final enumCertificates = crypt32.lookupFunction<
      Pointer<_CertContext> Function(IntPtr, Pointer<_CertContext>),
      Pointer<_CertContext> Function(int, Pointer<_CertContext>)>(
    'CertEnumCertificatesInStore',
  );
  final closeStore = crypt32.lookupFunction<
      Int32 Function(IntPtr, Uint32),
      int Function(int, int)>('CertCloseStore');

  final buffer = StringBuffer();
  final seen = <String>{};
  var user = 0;
  for (final storeName in const ['ROOT', 'CA']) {
    final namePointer = storeName.toNativeUtf16();
    final store = openStore(0, namePointer);
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
            user++;
          }
        }
        context = enumCertificates(store, context);
      }
    } finally {
      closeStore(store, 0);
    }
  }
  return SystemTrustBundle(pem: buffer.toString(), userCertificates: user);
}

/// Convenience wrapper returning only the PEM contents.
String loadWindowsSystemRootsPem() => loadWindowsSystemTrustBundle().pem;

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
