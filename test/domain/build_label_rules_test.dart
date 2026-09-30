// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_label_rules.dart';

void main() {
  group('normalizeBuildLabel', () {
    test('trims labels and maps empty or null values to null', () {
      expect(normalizeBuildLabel('  My nightly  '), 'My nightly');
      expect(normalizeBuildLabel(''), isNull);
      expect(normalizeBuildLabel('   '), isNull);
      expect(normalizeBuildLabel(null), isNull);
    });
  });

  group('validateBuildLabel', () {
    test('accepts labels up to the limit and empty values', () {
      expect(validateBuildLabel(null), isNull);
      expect(validateBuildLabel('  '), isNull);
      expect(validateBuildLabel('a' * maxBuildLabelLength), isNull);
    });

    test('rejects labels over the limit', () {
      expect(
        validateBuildLabel('a' * (maxBuildLabelLength + 1)),
        BuildLabelIssue.tooLong,
      );
    });

    test('rejects control characters', () {
      expect(validateBuildLabel('bad\u0000name'), BuildLabelIssue.controlCharacters);
      expect(validateBuildLabel('bad\u007fname'), BuildLabelIssue.controlCharacters);
    });
  });
}
