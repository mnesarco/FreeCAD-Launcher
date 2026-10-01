// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/addons/addon_id_rules.dart';

void main() {
  group('validateAddonId', () {
    test('accepts typical addon ids', () {
      expect(validateAddonId('A2plus'), isNull);
      expect(validateAddonId('My_Addon-2.v1'), isNull);
    });

    test('rejects empty ids', () {
      expect(validateAddonId('  '), AddonIdIssue.empty);
    });

    test('rejects ids longer than the cap', () {
      expect(validateAddonId('a' * (maxAddonIdLength + 1)), AddonIdIssue.tooLong);
    });

    test('rejects reserved names', () {
      expect(validateAddonId('.'), AddonIdIssue.reserved);
      expect(validateAddonId('..'), AddonIdIssue.reserved);
    });

    test('rejects path separators and invalid characters', () {
      expect(validateAddonId('a/b'), AddonIdIssue.invalidCharacters);
      expect(validateAddonId(r'a\b'), AddonIdIssue.invalidCharacters);
      expect(validateAddonId('a:b'), AddonIdIssue.invalidCharacters);
      expect(validateAddonId('a*'), AddonIdIssue.invalidCharacters);
    });

    test('rejects trailing dots', () {
      expect(validateAddonId('addon.'), AddonIdIssue.invalidCharacters);
    });

    test('rejects control characters', () {
      expect(validateAddonId('add\u0000on'), AddonIdIssue.invalidCharacters);
      expect(validateAddonId('add\u007fon'), AddonIdIssue.invalidCharacters);
    });
  });

  group('derivation', () {
    test('addonIdFromRepositoryUrl uses the last path segment', () {
      expect(addonIdFromRepositoryUrl('https://github.com/owner/MyAddon'), 'MyAddon');
      expect(addonIdFromRepositoryUrl('https://gitlab.com/group/sub/MyAddon'), 'MyAddon');
    });

    test('addonIdFromRepositoryUrl strips .git', () {
      expect(addonIdFromRepositoryUrl('https://github.com/owner/MyAddon.git'), 'MyAddon');
    });

    test('addonIdFromRepositoryUrl returns null for invalid urls', () {
      expect(addonIdFromRepositoryUrl('not a url'), isNull);
      expect(addonIdFromRepositoryUrl('https://github.com'), isNull);
    });

    test('addonIdFromArchivePath strips known archive extensions', () {
      expect(addonIdFromArchivePath('/tmp/A2plus.zip'), 'A2plus');
      expect(addonIdFromArchivePath('/tmp/My-Addon.tar.gz'), 'My-Addon');
      expect(addonIdFromArchivePath('/tmp/My-Addon.tgz'), 'My-Addon');
      expect(addonIdFromArchivePath('/tmp/My-Addon.tar'), 'My-Addon');
      expect(addonIdFromArchivePath('/tmp/plain'), 'plain');
    });

    test('addonIdFromDirectory uses the directory basename', () {
      expect(addonIdFromDirectory('/home/dev/Addons/DevWorkbench/'), 'DevWorkbench');
    });
  });
}
