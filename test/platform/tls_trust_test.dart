// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/tls_trust.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_tls_trust');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('counts PEM certificates', () {
    const pem = '-----BEGIN CERTIFICATE-----\nAAAA\n-----END CERTIFICATE-----\n'
        '-----BEGIN CERTIFICATE-----\nBBBB\n-----END CERTIFICATE-----\n';

    expect(countPemCertificates(pem), 2);
    expect(countPemCertificates('nothing here'), 0);
  });

  test('a missing bundle path is a no-op', () {
    final result = installAdditionalTrust(
      extraBundlePath: p.join(tempDirectory.path, 'missing.pem'),
    );

    expect(result.extraCertificates, 0);
    expect(result.error, isNull);
  });

  test('adds a user CA bundle to the default context', () {
    final result = installAdditionalTrust(
      extraBundlePath: 'test/fixtures/test_ca.pem',
    );

    expect(result.extraCertificates, 1);
    expect(result.error, isNull);
  });

  test('loads the Windows system root stores', () {
    if (!Platform.isWindows) {
      return;
    }

    final bundle = loadWindowsSystemTrustBundle();

    expect(bundle.pem, contains('-----BEGIN CERTIFICATE-----'));
    expect(
      bundle.totalCertificates,
      greaterThan(40),
      reason: 'the machine-wide ROOT/CA stores must be included, not only the user stores',
    );
    expect(
      bundle.machineCertificates,
      greaterThan(0),
      reason: 'the machine-wide ROOT/CA stores must be opened',
    );
  });

  test('the legacy user-store fallback loads certificates', () {
    if (!Platform.isWindows) {
      return;
    }

    final bundle = loadUserStoresBundle();

    expect(bundle.pem, contains('-----BEGIN CERTIFICATE-----'));
    expect(bundle.userCertificates, greaterThan(0));
  });
}
