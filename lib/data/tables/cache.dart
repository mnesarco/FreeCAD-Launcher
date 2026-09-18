import 'package:drift/drift.dart';
import 'package:freecad_launcher/domain/cache/cache_types.dart';

@DataClassName('CatalogCacheEntry')
class CatalogCache extends Table {
  TextColumn get key => text()();

  TextColumn get etag => text().nullable()();

  TextColumn get lastModified => text().nullable()();

  TextColumn get payloadPath => text()();

  DateTimeColumn get fetchedAt => dateTime()();

  TextColumn get status => textEnum<CacheStatus>()();

  @override
  Set<Column> get primaryKey => {key};
}
