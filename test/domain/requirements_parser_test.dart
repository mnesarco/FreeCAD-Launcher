// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/python/requirements_parser.dart';

void main() {
  test('parses names, specifiers, extras and markers', () {
    final requirements = parseRequirements('''
# comment line
numpy
requests>=2.0,<3
package[extra1,extra2]==1.0
typing-extensions; python_version < "3.10"
PyYAML >= 6.0 ; python_version >= "3.8"  # inline comment
''');

    expect(requirements, hasLength(5));
    expect(requirements[0].name, 'numpy');
    expect(requirements[0].specifier, isEmpty);
    expect(requirements[0].valid, isTrue);

    expect(requirements[1].name, 'requests');
    expect(requirements[1].specifier, '>=2.0,<3');

    expect(requirements[2].name, 'package');
    expect(requirements[2].extras, ['extra1', 'extra2']);
    expect(requirements[2].specifier, '==1.0');
    expect(requirements[2].display, 'package[extra1,extra2]==1.0');

    expect(requirements[3].name, 'typing-extensions');
    expect(requirements[3].marker, 'python_version < "3.10"');

    expect(requirements[4].name, 'PyYAML');
    expect(requirements[4].specifier, '>= 6.0');
    expect(requirements[4].marker, 'python_version >= "3.8"');
  });

  test('flags unsupported options and malformed lines', () {
    final requirements = parseRequirements('''
-e git+https://example.invalid/repo.git#egg=thing
--index-url https://example.invalid/simple
=broken
''');

    expect(requirements, hasLength(3));
    expect(requirements[0].valid, isFalse);
    expect(requirements[0].error, contains('Unsupported pip option'));
    expect(requirements[1].valid, isFalse);
    expect(requirements[2].valid, isFalse);
  });

  test('ignores blank lines and full-line comments', () {
    final requirements = parseRequirements('\n\n# only a comment\n   \n');

    expect(requirements, isEmpty);
  });
}
