import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/bundles/bundle_json.dart';

void main() {
  test('round-trips a bundle through JSON', () {
    const bundle = BundleJson(
      name: 'Mechanical',
      description: 'CAD + FEM essentials',
      items: [
        BundleJsonItem(addonId: 'A2plus', gitRef: 'master'),
        BundleJsonItem(addonId: 'Fasteners'),
      ],
    );

    final encoded = encodeBundleJson(bundle);
    final decoded = decodeBundleJson(encoded);

    expect(decoded.isOk, isTrue);
    final parsed = decoded.valueOrNull!;
    expect(parsed.name, 'Mechanical');
    expect(parsed.description, 'CAD + FEM essentials');
    expect(parsed.items, hasLength(2));
    expect(parsed.items[0].addonId, 'A2plus');
    expect(parsed.items[0].gitRef, 'master');
    expect(parsed.items[1].addonId, 'Fasteners');
    expect(parsed.items[1].gitRef, isNull);
    expect(encoded, contains('"schema": 1'));
  });

  test('rejects unsupported schemas and missing names', () {
    expect(
      decodeBundleJson('{"schema": 2, "name": "X", "addons": []}').isErr,
      isTrue,
    );
    expect(
      decodeBundleJson('{"schema": 1, "name": "  ", "addons": []}').isErr,
      isTrue,
    );
    expect(decodeBundleJson('{"schema": 1, "addons": []}').isErr, isTrue);
  });

  test('rejects invalid JSON and non-object payloads', () {
    expect(decodeBundleJson('not json').isErr, isTrue);
    expect(decodeBundleJson('[1, 2]').isErr, isTrue);
  });

  test('skips malformed addon entries and normalizes values', () {
    final decoded = decodeBundleJson('''
{
  "schema": 1,
  "name": " Mixed ",
  "description": "  ",
  "addons": [
    {"id": " A2plus ", "git_ref": " master "},
    {"id": ""},
    {"git_ref": "master"},
    "nope",
    {"id": "Fasteners", "git_ref": 42}
  ]
}
''');

    expect(decoded.isOk, isTrue);
    final parsed = decoded.valueOrNull!;
    expect(parsed.name, 'Mixed');
    expect(parsed.description, isNull);
    expect(parsed.items, hasLength(2));
    expect(parsed.items[0].addonId, 'A2plus');
    expect(parsed.items[0].gitRef, 'master');
    expect(parsed.items[1].addonId, 'Fasteners');
    expect(parsed.items[1].gitRef, isNull);
  });

  test('requires an addons list', () {
    expect(decodeBundleJson('{"schema": 1, "name": "X"}').isErr, isTrue);
  });
}
