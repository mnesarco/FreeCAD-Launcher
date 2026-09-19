import 'package:drift/drift.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';

@DataClassName('Build')
class Builds extends Table {
  TextColumn get id => text()();

  TextColumn get kind => textEnum<BuildKind>()();

  TextColumn get version => text()();

  TextColumn get channel => textEnum<BuildChannel>()();

  TextColumn get platform => textEnum<BuildPlatform>()();

  TextColumn get arch => text()();

  TextColumn get sourceUrl => text().nullable()();

  TextColumn get assetName => text().nullable()();

  TextColumn get localPath => text()();

  TextColumn get sha256 => text().nullable()();

  BoolColumn get verified => boolean().withDefault(const Constant(false))();

  TextColumn get pythonVersion => text().nullable()();

  TextColumn get pythonPath => text().nullable()();

  IntColumn get sizeBytes => integer().nullable()();

  TextColumn get status => textEnum<BuildStatus>()();

  TextColumn get releaseNotesUrl => text().nullable()();

  DateTimeColumn get installedAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {platform, arch, channel, version, assetName},
  ];
}
