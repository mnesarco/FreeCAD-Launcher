import 'package:flutter_test/flutter_test.dart';

import 'fake_http.dart';
import 'fixtures.dart';
import 'test_database.dart';

void main() {
  group('createTestDatabase', () {
    test('creates an in-memory database with working DAOs', () async {
      final database = createTestDatabase();

      await database.settingsDao.setValue('answer', '42');

      expect(await database.settingsDao.getValue('answer'), '42');
      await database.close();
    });
  });

  group('FakeHttp', () {
    test('records requests and serves the configured response', () async {
      final fake = FakeHttp.json('{"ok":true}');

      final response = await fake.client.get(Uri.parse('https://example.invalid/api'));

      expect(response.statusCode, 200);
      expect(response.body, '{"ok":true}');
      expect(fake.requestCount, 1);
      expect(fake.requests.single.url.toString(), 'https://example.invalid/api');
    });
  });

  group('fixtures', () {
    test('loads and parses the GitHub releases fixture', () {
      final data = loadJsonFixture('github_releases_1.1.3.json') as List<dynamic>;

      expect(data, hasLength(1));
      final release = data.single as Map<String, dynamic>;
      expect(release['tag_name'], '1.1.3');
      expect(release['prerelease'], isFalse);
      final assetNames = (release['assets'] as List<dynamic>)
          .map((asset) => (asset as Map<String, dynamic>)['name']);
      expect(assetNames, contains('FreeCAD_1.1.3-Linux-x86_64-py311.AppImage'));
      expect(assetNames, contains('FreeCAD_1.1.3-Windows-x86_64-py311.7z'));
      expect(assetNames, contains('FreeCAD_1.1.3-macOS-arm64-py311.dmg'));
    });
  });
}
