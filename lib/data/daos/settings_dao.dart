import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/data/tables/settings.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) =>
      into(settings).insertOnConflictUpdate(Setting(key: key, value: value));

  Future<int> remove(String key) => (delete(settings)..where((t) => t.key.equals(key))).go();

  Future<Map<String, String>> getAll() async {
    final rows = await select(settings).get();
    return {for (final row in rows) row.key: row.value};
  }

  Stream<Map<String, String>> watchAll() => select(settings).watch().map(
    (rows) => {for (final row in rows) row.key: row.value},
  );

  Future<Object?> getJson(String key) async {
    final raw = await getValue(key);
    return raw == null ? null : jsonDecode(raw);
  }

  Future<void> setJson(String key, Object? value) => setValue(key, jsonEncode(value));
}
