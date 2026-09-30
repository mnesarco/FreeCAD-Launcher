// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/bundles/bundle_rules.dart';

void main() {
  test('accepts valid names and normalizes whitespace', () {
    expect(normalizeBundleName('  Essentials  '), 'Essentials');
    expect(validateBundleName('Essentials', existingNames: const []), isNull);
  });

  test('rejects empty, long and control-character names', () {
    expect(validateBundleName('   ', existingNames: const []), BundleNameIssue.empty);
    expect(
      validateBundleName('x' * 65, existingNames: const []),
      BundleNameIssue.tooLong,
    );
    expect(
      validateBundleName('bad\u0001name', existingNames: const []),
      BundleNameIssue.controlCharacters,
    );
  });

  test('rejects duplicates case-insensitively but allows the current name', () {
    expect(
      validateBundleName('essentials', existingNames: const ['Essentials']),
      BundleNameIssue.duplicate,
    );
    expect(
      validateBundleName(
        'Essentials',
        existingNames: const ['Essentials'],
        currentName: 'Essentials',
      ),
      isNull,
    );
  });
}
