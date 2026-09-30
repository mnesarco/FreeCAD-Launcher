// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/domain/profiles/profile_rules.dart';

void main() {
  group('validateProfileName', () {
    test('accepts trimmed names, unicode and the length limit', () {
      expect(validateProfileName('  Dev  '), isNull);
      expect(normalizeProfileName('  Dev  '), 'Dev');
      expect(validateProfileName('Büro CAD'), isNull);
      expect(validateProfileName('a' * maxProfileNameLength), isNull);
    });

    test('rejects empty names', () {
      expect(validateProfileName(''), ProfileNameIssue.empty);
      expect(validateProfileName('   '), ProfileNameIssue.empty);
    });

    test('rejects names over the limit', () {
      expect(
        validateProfileName('a' * (maxProfileNameLength + 1)),
        ProfileNameIssue.tooLong,
      );
    });

    test('rejects control characters', () {
      expect(validateProfileName('bad\u0000name'), ProfileNameIssue.controlCharacters);
      expect(validateProfileName('bad\u007fname'), ProfileNameIssue.controlCharacters);
    });
  });

  group('validateProfileBinding', () {
    test('accepts an installed build with a Python version', () {
      expect(
        validateProfileBinding(status: BuildStatus.installed, pythonVersion: '3.11'),
        isNull,
      );
    });

    test('rejects builds that are not installed', () {
      expect(
        validateProfileBinding(status: BuildStatus.missing, pythonVersion: '3.11'),
        ProfileBindingIssue.buildNotInstalled,
      );
      expect(
        validateProfileBinding(status: BuildStatus.broken, pythonVersion: '3.11'),
        ProfileBindingIssue.buildNotInstalled,
      );
    });

    test('rejects builds without a Python version', () {
      expect(
        validateProfileBinding(status: BuildStatus.installed, pythonVersion: null),
        ProfileBindingIssue.pythonNotDetected,
      );
      expect(
        validateProfileBinding(status: BuildStatus.installed, pythonVersion: '  '),
        ProfileBindingIssue.pythonNotDetected,
      );
    });
  });
}
