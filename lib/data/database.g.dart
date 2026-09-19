// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BuildsTable extends Builds with TableInfo<$BuildsTable, Build> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BuildKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BuildKind>($BuildsTable.$converterkind);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BuildChannel, String> channel =
      GeneratedColumn<String>(
        'channel',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BuildChannel>($BuildsTable.$converterchannel);
  @override
  late final GeneratedColumnWithTypeConverter<BuildPlatform, String> platform =
      GeneratedColumn<String>(
        'platform',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BuildPlatform>($BuildsTable.$converterplatform);
  static const VerificationMeta _archMeta = const VerificationMeta('arch');
  @override
  late final GeneratedColumn<String> arch = GeneratedColumn<String>(
    'arch',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetNameMeta = const VerificationMeta(
    'assetName',
  );
  @override
  late final GeneratedColumn<String> assetName = GeneratedColumn<String>(
    'asset_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedMeta = const VerificationMeta(
    'verified',
  );
  @override
  late final GeneratedColumn<bool> verified = GeneratedColumn<bool>(
    'verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pythonVersionMeta = const VerificationMeta(
    'pythonVersion',
  );
  @override
  late final GeneratedColumn<String> pythonVersion = GeneratedColumn<String>(
    'python_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pythonPathMeta = const VerificationMeta(
    'pythonPath',
  );
  @override
  late final GeneratedColumn<String> pythonPath = GeneratedColumn<String>(
    'python_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BuildStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BuildStatus>($BuildsTable.$converterstatus);
  static const VerificationMeta _releaseNotesUrlMeta = const VerificationMeta(
    'releaseNotesUrl',
  );
  @override
  late final GeneratedColumn<String> releaseNotesUrl = GeneratedColumn<String>(
    'release_notes_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    version,
    channel,
    platform,
    arch,
    sourceUrl,
    assetName,
    localPath,
    sha256,
    verified,
    pythonVersion,
    pythonPath,
    sizeBytes,
    status,
    releaseNotesUrl,
    installedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'builds';
  @override
  VerificationContext validateIntegrity(
    Insertable<Build> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('arch')) {
      context.handle(
        _archMeta,
        arch.isAcceptableOrUnknown(data['arch']!, _archMeta),
      );
    } else if (isInserting) {
      context.missing(_archMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('asset_name')) {
      context.handle(
        _assetNameMeta,
        assetName.isAcceptableOrUnknown(data['asset_name']!, _assetNameMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('verified')) {
      context.handle(
        _verifiedMeta,
        verified.isAcceptableOrUnknown(data['verified']!, _verifiedMeta),
      );
    }
    if (data.containsKey('python_version')) {
      context.handle(
        _pythonVersionMeta,
        pythonVersion.isAcceptableOrUnknown(
          data['python_version']!,
          _pythonVersionMeta,
        ),
      );
    }
    if (data.containsKey('python_path')) {
      context.handle(
        _pythonPathMeta,
        pythonPath.isAcceptableOrUnknown(data['python_path']!, _pythonPathMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('release_notes_url')) {
      context.handle(
        _releaseNotesUrlMeta,
        releaseNotesUrl.isAcceptableOrUnknown(
          data['release_notes_url']!,
          _releaseNotesUrlMeta,
        ),
      );
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {platform, arch, channel, version, assetName},
  ];
  @override
  Build map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Build(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: $BuildsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      channel: $BuildsTable.$converterchannel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}channel'],
        )!,
      ),
      platform: $BuildsTable.$converterplatform.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}platform'],
        )!,
      ),
      arch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arch'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      assetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_name'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      verified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}verified'],
      )!,
      pythonVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}python_version'],
      ),
      pythonPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}python_path'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      status: $BuildsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      releaseNotesUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_notes_url'],
      ),
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BuildsTable createAlias(String alias) {
    return $BuildsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BuildKind, String, String> $converterkind =
      const EnumNameConverter<BuildKind>(BuildKind.values);
  static JsonTypeConverter2<BuildChannel, String, String> $converterchannel =
      const EnumNameConverter<BuildChannel>(BuildChannel.values);
  static JsonTypeConverter2<BuildPlatform, String, String> $converterplatform =
      const EnumNameConverter<BuildPlatform>(BuildPlatform.values);
  static JsonTypeConverter2<BuildStatus, String, String> $converterstatus =
      const EnumNameConverter<BuildStatus>(BuildStatus.values);
}

class Build extends DataClass implements Insertable<Build> {
  final String id;
  final BuildKind kind;
  final String version;
  final BuildChannel channel;
  final BuildPlatform platform;
  final String arch;
  final String? sourceUrl;
  final String? assetName;
  final String localPath;
  final String? sha256;
  final bool verified;
  final String? pythonVersion;
  final String? pythonPath;
  final int? sizeBytes;
  final BuildStatus status;
  final String? releaseNotesUrl;
  final DateTime installedAt;
  final DateTime updatedAt;
  const Build({
    required this.id,
    required this.kind,
    required this.version,
    required this.channel,
    required this.platform,
    required this.arch,
    this.sourceUrl,
    this.assetName,
    required this.localPath,
    this.sha256,
    required this.verified,
    this.pythonVersion,
    this.pythonPath,
    this.sizeBytes,
    required this.status,
    this.releaseNotesUrl,
    required this.installedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['kind'] = Variable<String>($BuildsTable.$converterkind.toSql(kind));
    }
    map['version'] = Variable<String>(version);
    {
      map['channel'] = Variable<String>(
        $BuildsTable.$converterchannel.toSql(channel),
      );
    }
    {
      map['platform'] = Variable<String>(
        $BuildsTable.$converterplatform.toSql(platform),
      );
    }
    map['arch'] = Variable<String>(arch);
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || assetName != null) {
      map['asset_name'] = Variable<String>(assetName);
    }
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    map['verified'] = Variable<bool>(verified);
    if (!nullToAbsent || pythonVersion != null) {
      map['python_version'] = Variable<String>(pythonVersion);
    }
    if (!nullToAbsent || pythonPath != null) {
      map['python_path'] = Variable<String>(pythonPath);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    {
      map['status'] = Variable<String>(
        $BuildsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || releaseNotesUrl != null) {
      map['release_notes_url'] = Variable<String>(releaseNotesUrl);
    }
    map['installed_at'] = Variable<DateTime>(installedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BuildsCompanion toCompanion(bool nullToAbsent) {
    return BuildsCompanion(
      id: Value(id),
      kind: Value(kind),
      version: Value(version),
      channel: Value(channel),
      platform: Value(platform),
      arch: Value(arch),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      assetName: assetName == null && nullToAbsent
          ? const Value.absent()
          : Value(assetName),
      localPath: Value(localPath),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      verified: Value(verified),
      pythonVersion: pythonVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(pythonVersion),
      pythonPath: pythonPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pythonPath),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      status: Value(status),
      releaseNotesUrl: releaseNotesUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseNotesUrl),
      installedAt: Value(installedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Build.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Build(
      id: serializer.fromJson<String>(json['id']),
      kind: $BuildsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      version: serializer.fromJson<String>(json['version']),
      channel: $BuildsTable.$converterchannel.fromJson(
        serializer.fromJson<String>(json['channel']),
      ),
      platform: $BuildsTable.$converterplatform.fromJson(
        serializer.fromJson<String>(json['platform']),
      ),
      arch: serializer.fromJson<String>(json['arch']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      assetName: serializer.fromJson<String?>(json['assetName']),
      localPath: serializer.fromJson<String>(json['localPath']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      verified: serializer.fromJson<bool>(json['verified']),
      pythonVersion: serializer.fromJson<String?>(json['pythonVersion']),
      pythonPath: serializer.fromJson<String?>(json['pythonPath']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      status: $BuildsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      releaseNotesUrl: serializer.fromJson<String?>(json['releaseNotesUrl']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(
        $BuildsTable.$converterkind.toJson(kind),
      ),
      'version': serializer.toJson<String>(version),
      'channel': serializer.toJson<String>(
        $BuildsTable.$converterchannel.toJson(channel),
      ),
      'platform': serializer.toJson<String>(
        $BuildsTable.$converterplatform.toJson(platform),
      ),
      'arch': serializer.toJson<String>(arch),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'assetName': serializer.toJson<String?>(assetName),
      'localPath': serializer.toJson<String>(localPath),
      'sha256': serializer.toJson<String?>(sha256),
      'verified': serializer.toJson<bool>(verified),
      'pythonVersion': serializer.toJson<String?>(pythonVersion),
      'pythonPath': serializer.toJson<String?>(pythonPath),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'status': serializer.toJson<String>(
        $BuildsTable.$converterstatus.toJson(status),
      ),
      'releaseNotesUrl': serializer.toJson<String?>(releaseNotesUrl),
      'installedAt': serializer.toJson<DateTime>(installedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Build copyWith({
    String? id,
    BuildKind? kind,
    String? version,
    BuildChannel? channel,
    BuildPlatform? platform,
    String? arch,
    Value<String?> sourceUrl = const Value.absent(),
    Value<String?> assetName = const Value.absent(),
    String? localPath,
    Value<String?> sha256 = const Value.absent(),
    bool? verified,
    Value<String?> pythonVersion = const Value.absent(),
    Value<String?> pythonPath = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    BuildStatus? status,
    Value<String?> releaseNotesUrl = const Value.absent(),
    DateTime? installedAt,
    DateTime? updatedAt,
  }) => Build(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    version: version ?? this.version,
    channel: channel ?? this.channel,
    platform: platform ?? this.platform,
    arch: arch ?? this.arch,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    assetName: assetName.present ? assetName.value : this.assetName,
    localPath: localPath ?? this.localPath,
    sha256: sha256.present ? sha256.value : this.sha256,
    verified: verified ?? this.verified,
    pythonVersion: pythonVersion.present
        ? pythonVersion.value
        : this.pythonVersion,
    pythonPath: pythonPath.present ? pythonPath.value : this.pythonPath,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    status: status ?? this.status,
    releaseNotesUrl: releaseNotesUrl.present
        ? releaseNotesUrl.value
        : this.releaseNotesUrl,
    installedAt: installedAt ?? this.installedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Build copyWithCompanion(BuildsCompanion data) {
    return Build(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      version: data.version.present ? data.version.value : this.version,
      channel: data.channel.present ? data.channel.value : this.channel,
      platform: data.platform.present ? data.platform.value : this.platform,
      arch: data.arch.present ? data.arch.value : this.arch,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      assetName: data.assetName.present ? data.assetName.value : this.assetName,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      verified: data.verified.present ? data.verified.value : this.verified,
      pythonVersion: data.pythonVersion.present
          ? data.pythonVersion.value
          : this.pythonVersion,
      pythonPath: data.pythonPath.present
          ? data.pythonPath.value
          : this.pythonPath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      status: data.status.present ? data.status.value : this.status,
      releaseNotesUrl: data.releaseNotesUrl.present
          ? data.releaseNotesUrl.value
          : this.releaseNotesUrl,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Build(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('version: $version, ')
          ..write('channel: $channel, ')
          ..write('platform: $platform, ')
          ..write('arch: $arch, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('assetName: $assetName, ')
          ..write('localPath: $localPath, ')
          ..write('sha256: $sha256, ')
          ..write('verified: $verified, ')
          ..write('pythonVersion: $pythonVersion, ')
          ..write('pythonPath: $pythonPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('status: $status, ')
          ..write('releaseNotesUrl: $releaseNotesUrl, ')
          ..write('installedAt: $installedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    version,
    channel,
    platform,
    arch,
    sourceUrl,
    assetName,
    localPath,
    sha256,
    verified,
    pythonVersion,
    pythonPath,
    sizeBytes,
    status,
    releaseNotesUrl,
    installedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Build &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.version == this.version &&
          other.channel == this.channel &&
          other.platform == this.platform &&
          other.arch == this.arch &&
          other.sourceUrl == this.sourceUrl &&
          other.assetName == this.assetName &&
          other.localPath == this.localPath &&
          other.sha256 == this.sha256 &&
          other.verified == this.verified &&
          other.pythonVersion == this.pythonVersion &&
          other.pythonPath == this.pythonPath &&
          other.sizeBytes == this.sizeBytes &&
          other.status == this.status &&
          other.releaseNotesUrl == this.releaseNotesUrl &&
          other.installedAt == this.installedAt &&
          other.updatedAt == this.updatedAt);
}

class BuildsCompanion extends UpdateCompanion<Build> {
  final Value<String> id;
  final Value<BuildKind> kind;
  final Value<String> version;
  final Value<BuildChannel> channel;
  final Value<BuildPlatform> platform;
  final Value<String> arch;
  final Value<String?> sourceUrl;
  final Value<String?> assetName;
  final Value<String> localPath;
  final Value<String?> sha256;
  final Value<bool> verified;
  final Value<String?> pythonVersion;
  final Value<String?> pythonPath;
  final Value<int?> sizeBytes;
  final Value<BuildStatus> status;
  final Value<String?> releaseNotesUrl;
  final Value<DateTime> installedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BuildsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.version = const Value.absent(),
    this.channel = const Value.absent(),
    this.platform = const Value.absent(),
    this.arch = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.assetName = const Value.absent(),
    this.localPath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.verified = const Value.absent(),
    this.pythonVersion = const Value.absent(),
    this.pythonPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.releaseNotesUrl = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuildsCompanion.insert({
    required String id,
    required BuildKind kind,
    required String version,
    required BuildChannel channel,
    required BuildPlatform platform,
    required String arch,
    this.sourceUrl = const Value.absent(),
    this.assetName = const Value.absent(),
    required String localPath,
    this.sha256 = const Value.absent(),
    this.verified = const Value.absent(),
    this.pythonVersion = const Value.absent(),
    this.pythonPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    required BuildStatus status,
    this.releaseNotesUrl = const Value.absent(),
    required DateTime installedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       version = Value(version),
       channel = Value(channel),
       platform = Value(platform),
       arch = Value(arch),
       localPath = Value(localPath),
       status = Value(status),
       installedAt = Value(installedAt),
       updatedAt = Value(updatedAt);
  static Insertable<Build> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? version,
    Expression<String>? channel,
    Expression<String>? platform,
    Expression<String>? arch,
    Expression<String>? sourceUrl,
    Expression<String>? assetName,
    Expression<String>? localPath,
    Expression<String>? sha256,
    Expression<bool>? verified,
    Expression<String>? pythonVersion,
    Expression<String>? pythonPath,
    Expression<int>? sizeBytes,
    Expression<String>? status,
    Expression<String>? releaseNotesUrl,
    Expression<DateTime>? installedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (version != null) 'version': version,
      if (channel != null) 'channel': channel,
      if (platform != null) 'platform': platform,
      if (arch != null) 'arch': arch,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (assetName != null) 'asset_name': assetName,
      if (localPath != null) 'local_path': localPath,
      if (sha256 != null) 'sha256': sha256,
      if (verified != null) 'verified': verified,
      if (pythonVersion != null) 'python_version': pythonVersion,
      if (pythonPath != null) 'python_path': pythonPath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (status != null) 'status': status,
      if (releaseNotesUrl != null) 'release_notes_url': releaseNotesUrl,
      if (installedAt != null) 'installed_at': installedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuildsCompanion copyWith({
    Value<String>? id,
    Value<BuildKind>? kind,
    Value<String>? version,
    Value<BuildChannel>? channel,
    Value<BuildPlatform>? platform,
    Value<String>? arch,
    Value<String?>? sourceUrl,
    Value<String?>? assetName,
    Value<String>? localPath,
    Value<String?>? sha256,
    Value<bool>? verified,
    Value<String?>? pythonVersion,
    Value<String?>? pythonPath,
    Value<int?>? sizeBytes,
    Value<BuildStatus>? status,
    Value<String?>? releaseNotesUrl,
    Value<DateTime>? installedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BuildsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      version: version ?? this.version,
      channel: channel ?? this.channel,
      platform: platform ?? this.platform,
      arch: arch ?? this.arch,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      assetName: assetName ?? this.assetName,
      localPath: localPath ?? this.localPath,
      sha256: sha256 ?? this.sha256,
      verified: verified ?? this.verified,
      pythonVersion: pythonVersion ?? this.pythonVersion,
      pythonPath: pythonPath ?? this.pythonPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      releaseNotesUrl: releaseNotesUrl ?? this.releaseNotesUrl,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $BuildsTable.$converterkind.toSql(kind.value),
      );
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(
        $BuildsTable.$converterchannel.toSql(channel.value),
      );
    }
    if (platform.present) {
      map['platform'] = Variable<String>(
        $BuildsTable.$converterplatform.toSql(platform.value),
      );
    }
    if (arch.present) {
      map['arch'] = Variable<String>(arch.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (assetName.present) {
      map['asset_name'] = Variable<String>(assetName.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (verified.present) {
      map['verified'] = Variable<bool>(verified.value);
    }
    if (pythonVersion.present) {
      map['python_version'] = Variable<String>(pythonVersion.value);
    }
    if (pythonPath.present) {
      map['python_path'] = Variable<String>(pythonPath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $BuildsTable.$converterstatus.toSql(status.value),
      );
    }
    if (releaseNotesUrl.present) {
      map['release_notes_url'] = Variable<String>(releaseNotesUrl.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('version: $version, ')
          ..write('channel: $channel, ')
          ..write('platform: $platform, ')
          ..write('arch: $arch, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('assetName: $assetName, ')
          ..write('localPath: $localPath, ')
          ..write('sha256: $sha256, ')
          ..write('verified: $verified, ')
          ..write('pythonVersion: $pythonVersion, ')
          ..write('pythonPath: $pythonPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('status: $status, ')
          ..write('releaseNotesUrl: $releaseNotesUrl, ')
          ..write('installedAt: $installedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buildIdMeta = const VerificationMeta(
    'buildId',
  );
  @override
  late final GeneratedColumn<String> buildId = GeneratedColumn<String>(
    'build_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES builds (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _pythonVersionMeta = const VerificationMeta(
    'pythonVersion',
  );
  @override
  late final GeneratedColumn<String> pythonVersion = GeneratedColumn<String>(
    'python_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconColorMeta = const VerificationMeta(
    'iconColor',
  );
  @override
  late final GeneratedColumn<int> iconColor = GeneratedColumn<int>(
    'icon_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    buildId,
    pythonVersion,
    iconColor,
    createdAt,
    updatedAt,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('build_id')) {
      context.handle(
        _buildIdMeta,
        buildId.isAcceptableOrUnknown(data['build_id']!, _buildIdMeta),
      );
    } else if (isInserting) {
      context.missing(_buildIdMeta);
    }
    if (data.containsKey('python_version')) {
      context.handle(
        _pythonVersionMeta,
        pythonVersion.isAcceptableOrUnknown(
          data['python_version']!,
          _pythonVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pythonVersionMeta);
    }
    if (data.containsKey('icon_color')) {
      context.handle(
        _iconColorMeta,
        iconColor.isAcceptableOrUnknown(data['icon_color']!, _iconColorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      buildId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}build_id'],
      )!,
      pythonVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}python_version'],
      )!,
      iconColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String name;
  final String? description;
  final String buildId;
  final String pythonVersion;
  final int? iconColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  const Profile({
    required this.id,
    required this.name,
    this.description,
    required this.buildId,
    required this.pythonVersion,
    this.iconColor,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['build_id'] = Variable<String>(buildId);
    map['python_version'] = Variable<String>(pythonVersion);
    if (!nullToAbsent || iconColor != null) {
      map['icon_color'] = Variable<int>(iconColor);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      buildId: Value(buildId),
      pythonVersion: Value(pythonVersion),
      iconColor: iconColor == null && nullToAbsent
          ? const Value.absent()
          : Value(iconColor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      buildId: serializer.fromJson<String>(json['buildId']),
      pythonVersion: serializer.fromJson<String>(json['pythonVersion']),
      iconColor: serializer.fromJson<int?>(json['iconColor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'buildId': serializer.toJson<String>(buildId),
      'pythonVersion': serializer.toJson<String>(pythonVersion),
      'iconColor': serializer.toJson<int?>(iconColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
    };
  }

  Profile copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    String? buildId,
    String? pythonVersion,
    Value<int?> iconColor = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastUsedAt = const Value.absent(),
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    buildId: buildId ?? this.buildId,
    pythonVersion: pythonVersion ?? this.pythonVersion,
    iconColor: iconColor.present ? iconColor.value : this.iconColor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      buildId: data.buildId.present ? data.buildId.value : this.buildId,
      pythonVersion: data.pythonVersion.present
          ? data.pythonVersion.value
          : this.pythonVersion,
      iconColor: data.iconColor.present ? data.iconColor.value : this.iconColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('buildId: $buildId, ')
          ..write('pythonVersion: $pythonVersion, ')
          ..write('iconColor: $iconColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    buildId,
    pythonVersion,
    iconColor,
    createdAt,
    updatedAt,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.buildId == this.buildId &&
          other.pythonVersion == this.pythonVersion &&
          other.iconColor == this.iconColor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastUsedAt == this.lastUsedAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> buildId;
  final Value<String> pythonVersion;
  final Value<int?> iconColor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastUsedAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.buildId = const Value.absent(),
    this.pythonVersion = const Value.absent(),
    this.iconColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String buildId,
    required String pythonVersion,
    this.iconColor = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       buildId = Value(buildId),
       pythonVersion = Value(pythonVersion),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? buildId,
    Expression<String>? pythonVersion,
    Expression<int>? iconColor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (buildId != null) 'build_id': buildId,
      if (pythonVersion != null) 'python_version': pythonVersion,
      if (iconColor != null) 'icon_color': iconColor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? buildId,
    Value<String>? pythonVersion,
    Value<int?>? iconColor,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      buildId: buildId ?? this.buildId,
      pythonVersion: pythonVersion ?? this.pythonVersion,
      iconColor: iconColor ?? this.iconColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (buildId.present) {
      map['build_id'] = Variable<String>(buildId.value);
    }
    if (pythonVersion.present) {
      map['python_version'] = Variable<String>(pythonVersion.value);
    }
    if (iconColor.present) {
      map['icon_color'] = Variable<int>(iconColor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('buildId: $buildId, ')
          ..write('pythonVersion: $pythonVersion, ')
          ..write('iconColor: $iconColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstalledAddonsTable extends InstalledAddons
    with TableInfo<$InstalledAddonsTable, InstalledAddon> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstalledAddonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _addonIdMeta = const VerificationMeta(
    'addonId',
  );
  @override
  late final GeneratedColumn<String> addonId = GeneratedColumn<String>(
    'addon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gitRefMeta = const VerificationMeta('gitRef');
  @override
  late final GeneratedColumn<String> gitRef = GeneratedColumn<String>(
    'git_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogLastUpdateMeta = const VerificationMeta(
    'catalogLastUpdate',
  );
  @override
  late final GeneratedColumn<DateTime> catalogLastUpdate =
      GeneratedColumn<DateTime>(
        'catalog_last_update',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasRequirementsMeta = const VerificationMeta(
    'hasRequirements',
  );
  @override
  late final GeneratedColumn<bool> hasRequirements = GeneratedColumn<bool>(
    'has_requirements',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_requirements" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    addonId,
    displayName,
    gitRef,
    version,
    installedAt,
    updatedAt,
    catalogLastUpdate,
    sourceUrl,
    hasRequirements,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installed_addons';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstalledAddon> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('addon_id')) {
      context.handle(
        _addonIdMeta,
        addonId.isAcceptableOrUnknown(data['addon_id']!, _addonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_addonIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('git_ref')) {
      context.handle(
        _gitRefMeta,
        gitRef.isAcceptableOrUnknown(data['git_ref']!, _gitRefMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('catalog_last_update')) {
      context.handle(
        _catalogLastUpdateMeta,
        catalogLastUpdate.isAcceptableOrUnknown(
          data['catalog_last_update']!,
          _catalogLastUpdateMeta,
        ),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('has_requirements')) {
      context.handle(
        _hasRequirementsMeta,
        hasRequirements.isAcceptableOrUnknown(
          data['has_requirements']!,
          _hasRequirementsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, addonId},
  ];
  @override
  InstalledAddon map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstalledAddon(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      addonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}addon_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      gitRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}git_ref'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      catalogLastUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}catalog_last_update'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      hasRequirements: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_requirements'],
      )!,
    );
  }

  @override
  $InstalledAddonsTable createAlias(String alias) {
    return $InstalledAddonsTable(attachedDatabase, alias);
  }
}

class InstalledAddon extends DataClass implements Insertable<InstalledAddon> {
  final String id;
  final String profileId;
  final String addonId;
  final String displayName;
  final String? gitRef;
  final String? version;
  final DateTime installedAt;
  final DateTime updatedAt;
  final DateTime? catalogLastUpdate;
  final String? sourceUrl;
  final bool hasRequirements;
  const InstalledAddon({
    required this.id,
    required this.profileId,
    required this.addonId,
    required this.displayName,
    this.gitRef,
    this.version,
    required this.installedAt,
    required this.updatedAt,
    this.catalogLastUpdate,
    this.sourceUrl,
    required this.hasRequirements,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['addon_id'] = Variable<String>(addonId);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || gitRef != null) {
      map['git_ref'] = Variable<String>(gitRef);
    }
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    map['installed_at'] = Variable<DateTime>(installedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || catalogLastUpdate != null) {
      map['catalog_last_update'] = Variable<DateTime>(catalogLastUpdate);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    map['has_requirements'] = Variable<bool>(hasRequirements);
    return map;
  }

  InstalledAddonsCompanion toCompanion(bool nullToAbsent) {
    return InstalledAddonsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      addonId: Value(addonId),
      displayName: Value(displayName),
      gitRef: gitRef == null && nullToAbsent
          ? const Value.absent()
          : Value(gitRef),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      installedAt: Value(installedAt),
      updatedAt: Value(updatedAt),
      catalogLastUpdate: catalogLastUpdate == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogLastUpdate),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      hasRequirements: Value(hasRequirements),
    );
  }

  factory InstalledAddon.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstalledAddon(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      addonId: serializer.fromJson<String>(json['addonId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      gitRef: serializer.fromJson<String?>(json['gitRef']),
      version: serializer.fromJson<String?>(json['version']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      catalogLastUpdate: serializer.fromJson<DateTime?>(
        json['catalogLastUpdate'],
      ),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      hasRequirements: serializer.fromJson<bool>(json['hasRequirements']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'addonId': serializer.toJson<String>(addonId),
      'displayName': serializer.toJson<String>(displayName),
      'gitRef': serializer.toJson<String?>(gitRef),
      'version': serializer.toJson<String?>(version),
      'installedAt': serializer.toJson<DateTime>(installedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'catalogLastUpdate': serializer.toJson<DateTime?>(catalogLastUpdate),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'hasRequirements': serializer.toJson<bool>(hasRequirements),
    };
  }

  InstalledAddon copyWith({
    String? id,
    String? profileId,
    String? addonId,
    String? displayName,
    Value<String?> gitRef = const Value.absent(),
    Value<String?> version = const Value.absent(),
    DateTime? installedAt,
    DateTime? updatedAt,
    Value<DateTime?> catalogLastUpdate = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
    bool? hasRequirements,
  }) => InstalledAddon(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    addonId: addonId ?? this.addonId,
    displayName: displayName ?? this.displayName,
    gitRef: gitRef.present ? gitRef.value : this.gitRef,
    version: version.present ? version.value : this.version,
    installedAt: installedAt ?? this.installedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    catalogLastUpdate: catalogLastUpdate.present
        ? catalogLastUpdate.value
        : this.catalogLastUpdate,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    hasRequirements: hasRequirements ?? this.hasRequirements,
  );
  InstalledAddon copyWithCompanion(InstalledAddonsCompanion data) {
    return InstalledAddon(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      addonId: data.addonId.present ? data.addonId.value : this.addonId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      gitRef: data.gitRef.present ? data.gitRef.value : this.gitRef,
      version: data.version.present ? data.version.value : this.version,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      catalogLastUpdate: data.catalogLastUpdate.present
          ? data.catalogLastUpdate.value
          : this.catalogLastUpdate,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      hasRequirements: data.hasRequirements.present
          ? data.hasRequirements.value
          : this.hasRequirements,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstalledAddon(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('addonId: $addonId, ')
          ..write('displayName: $displayName, ')
          ..write('gitRef: $gitRef, ')
          ..write('version: $version, ')
          ..write('installedAt: $installedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('catalogLastUpdate: $catalogLastUpdate, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('hasRequirements: $hasRequirements')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    addonId,
    displayName,
    gitRef,
    version,
    installedAt,
    updatedAt,
    catalogLastUpdate,
    sourceUrl,
    hasRequirements,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstalledAddon &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.addonId == this.addonId &&
          other.displayName == this.displayName &&
          other.gitRef == this.gitRef &&
          other.version == this.version &&
          other.installedAt == this.installedAt &&
          other.updatedAt == this.updatedAt &&
          other.catalogLastUpdate == this.catalogLastUpdate &&
          other.sourceUrl == this.sourceUrl &&
          other.hasRequirements == this.hasRequirements);
}

class InstalledAddonsCompanion extends UpdateCompanion<InstalledAddon> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> addonId;
  final Value<String> displayName;
  final Value<String?> gitRef;
  final Value<String?> version;
  final Value<DateTime> installedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> catalogLastUpdate;
  final Value<String?> sourceUrl;
  final Value<bool> hasRequirements;
  final Value<int> rowid;
  const InstalledAddonsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.addonId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.gitRef = const Value.absent(),
    this.version = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.catalogLastUpdate = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.hasRequirements = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstalledAddonsCompanion.insert({
    required String id,
    required String profileId,
    required String addonId,
    required String displayName,
    this.gitRef = const Value.absent(),
    this.version = const Value.absent(),
    required DateTime installedAt,
    required DateTime updatedAt,
    this.catalogLastUpdate = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.hasRequirements = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       addonId = Value(addonId),
       displayName = Value(displayName),
       installedAt = Value(installedAt),
       updatedAt = Value(updatedAt);
  static Insertable<InstalledAddon> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? addonId,
    Expression<String>? displayName,
    Expression<String>? gitRef,
    Expression<String>? version,
    Expression<DateTime>? installedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? catalogLastUpdate,
    Expression<String>? sourceUrl,
    Expression<bool>? hasRequirements,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (addonId != null) 'addon_id': addonId,
      if (displayName != null) 'display_name': displayName,
      if (gitRef != null) 'git_ref': gitRef,
      if (version != null) 'version': version,
      if (installedAt != null) 'installed_at': installedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (catalogLastUpdate != null) 'catalog_last_update': catalogLastUpdate,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (hasRequirements != null) 'has_requirements': hasRequirements,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstalledAddonsCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? addonId,
    Value<String>? displayName,
    Value<String?>? gitRef,
    Value<String?>? version,
    Value<DateTime>? installedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? catalogLastUpdate,
    Value<String?>? sourceUrl,
    Value<bool>? hasRequirements,
    Value<int>? rowid,
  }) {
    return InstalledAddonsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      addonId: addonId ?? this.addonId,
      displayName: displayName ?? this.displayName,
      gitRef: gitRef ?? this.gitRef,
      version: version ?? this.version,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      catalogLastUpdate: catalogLastUpdate ?? this.catalogLastUpdate,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      hasRequirements: hasRequirements ?? this.hasRequirements,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (addonId.present) {
      map['addon_id'] = Variable<String>(addonId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (gitRef.present) {
      map['git_ref'] = Variable<String>(gitRef.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (catalogLastUpdate.present) {
      map['catalog_last_update'] = Variable<DateTime>(catalogLastUpdate.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (hasRequirements.present) {
      map['has_requirements'] = Variable<bool>(hasRequirements.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstalledAddonsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('addonId: $addonId, ')
          ..write('displayName: $displayName, ')
          ..write('gitRef: $gitRef, ')
          ..write('version: $version, ')
          ..write('installedAt: $installedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('catalogLastUpdate: $catalogLastUpdate, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('hasRequirements: $hasRequirements, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PythonPackagesTable extends PythonPackages
    with TableInfo<$PythonPackagesTable, PythonPackage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PythonPackagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDirMeta = const VerificationMeta(
    'targetDir',
  );
  @override
  late final GeneratedColumn<String> targetDir = GeneratedColumn<String>(
    'target_dir',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    name,
    version,
    targetDir,
    source,
    installedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'python_packages';
  @override
  VerificationContext validateIntegrity(
    Insertable<PythonPackage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('target_dir')) {
      context.handle(
        _targetDirMeta,
        targetDir.isAcceptableOrUnknown(data['target_dir']!, _targetDirMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDirMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, name},
  ];
  @override
  PythonPackage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PythonPackage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      targetDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_dir'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
    );
  }

  @override
  $PythonPackagesTable createAlias(String alias) {
    return $PythonPackagesTable(attachedDatabase, alias);
  }
}

class PythonPackage extends DataClass implements Insertable<PythonPackage> {
  final String id;
  final String profileId;
  final String name;
  final String? version;
  final String targetDir;
  final String source;
  final DateTime installedAt;
  const PythonPackage({
    required this.id,
    required this.profileId,
    required this.name,
    this.version,
    required this.targetDir,
    required this.source,
    required this.installedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    map['target_dir'] = Variable<String>(targetDir);
    map['source'] = Variable<String>(source);
    map['installed_at'] = Variable<DateTime>(installedAt);
    return map;
  }

  PythonPackagesCompanion toCompanion(bool nullToAbsent) {
    return PythonPackagesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      targetDir: Value(targetDir),
      source: Value(source),
      installedAt: Value(installedAt),
    );
  }

  factory PythonPackage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PythonPackage(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      version: serializer.fromJson<String?>(json['version']),
      targetDir: serializer.fromJson<String>(json['targetDir']),
      source: serializer.fromJson<String>(json['source']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'name': serializer.toJson<String>(name),
      'version': serializer.toJson<String?>(version),
      'targetDir': serializer.toJson<String>(targetDir),
      'source': serializer.toJson<String>(source),
      'installedAt': serializer.toJson<DateTime>(installedAt),
    };
  }

  PythonPackage copyWith({
    String? id,
    String? profileId,
    String? name,
    Value<String?> version = const Value.absent(),
    String? targetDir,
    String? source,
    DateTime? installedAt,
  }) => PythonPackage(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    name: name ?? this.name,
    version: version.present ? version.value : this.version,
    targetDir: targetDir ?? this.targetDir,
    source: source ?? this.source,
    installedAt: installedAt ?? this.installedAt,
  );
  PythonPackage copyWithCompanion(PythonPackagesCompanion data) {
    return PythonPackage(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      version: data.version.present ? data.version.value : this.version,
      targetDir: data.targetDir.present ? data.targetDir.value : this.targetDir,
      source: data.source.present ? data.source.value : this.source,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PythonPackage(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('targetDir: $targetDir, ')
          ..write('source: $source, ')
          ..write('installedAt: $installedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, name, version, targetDir, source, installedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PythonPackage &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.version == this.version &&
          other.targetDir == this.targetDir &&
          other.source == this.source &&
          other.installedAt == this.installedAt);
}

class PythonPackagesCompanion extends UpdateCompanion<PythonPackage> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> name;
  final Value<String?> version;
  final Value<String> targetDir;
  final Value<String> source;
  final Value<DateTime> installedAt;
  final Value<int> rowid;
  const PythonPackagesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.version = const Value.absent(),
    this.targetDir = const Value.absent(),
    this.source = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PythonPackagesCompanion.insert({
    required String id,
    required String profileId,
    required String name,
    this.version = const Value.absent(),
    required String targetDir,
    required String source,
    required DateTime installedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       name = Value(name),
       targetDir = Value(targetDir),
       source = Value(source),
       installedAt = Value(installedAt);
  static Insertable<PythonPackage> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? name,
    Expression<String>? version,
    Expression<String>? targetDir,
    Expression<String>? source,
    Expression<DateTime>? installedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (version != null) 'version': version,
      if (targetDir != null) 'target_dir': targetDir,
      if (source != null) 'source': source,
      if (installedAt != null) 'installed_at': installedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PythonPackagesCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? name,
    Value<String?>? version,
    Value<String>? targetDir,
    Value<String>? source,
    Value<DateTime>? installedAt,
    Value<int>? rowid,
  }) {
    return PythonPackagesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      version: version ?? this.version,
      targetDir: targetDir ?? this.targetDir,
      source: source ?? this.source,
      installedAt: installedAt ?? this.installedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (targetDir.present) {
      map['target_dir'] = Variable<String>(targetDir.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PythonPackagesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('targetDir: $targetDir, ')
          ..write('source: $source, ')
          ..write('installedAt: $installedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BundlesTable extends Bundles with TableInfo<$BundlesTable, Bundle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BundlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bundles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bundle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bundle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bundle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BundlesTable createAlias(String alias) {
    return $BundlesTable(attachedDatabase, alias);
  }
}

class Bundle extends DataClass implements Insertable<Bundle> {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Bundle({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BundlesCompanion toCompanion(bool nullToAbsent) {
    return BundlesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Bundle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bundle(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Bundle copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Bundle(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Bundle copyWithCompanion(BundlesCompanion data) {
    return Bundle(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bundle(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bundle &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BundlesCompanion extends UpdateCompanion<Bundle> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BundlesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BundlesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Bundle> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BundlesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BundlesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BundlesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BundleItemsTable extends BundleItems
    with TableInfo<$BundleItemsTable, BundleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BundleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bundleIdMeta = const VerificationMeta(
    'bundleId',
  );
  @override
  late final GeneratedColumn<String> bundleId = GeneratedColumn<String>(
    'bundle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bundles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _addonIdMeta = const VerificationMeta(
    'addonId',
  );
  @override
  late final GeneratedColumn<String> addonId = GeneratedColumn<String>(
    'addon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gitRefMeta = const VerificationMeta('gitRef');
  @override
  late final GeneratedColumn<String> gitRef = GeneratedColumn<String>(
    'git_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [bundleId, addonId, gitRef];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bundle_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<BundleItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bundle_id')) {
      context.handle(
        _bundleIdMeta,
        bundleId.isAcceptableOrUnknown(data['bundle_id']!, _bundleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bundleIdMeta);
    }
    if (data.containsKey('addon_id')) {
      context.handle(
        _addonIdMeta,
        addonId.isAcceptableOrUnknown(data['addon_id']!, _addonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_addonIdMeta);
    }
    if (data.containsKey('git_ref')) {
      context.handle(
        _gitRefMeta,
        gitRef.isAcceptableOrUnknown(data['git_ref']!, _gitRefMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bundleId, addonId};
  @override
  BundleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BundleItem(
      bundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bundle_id'],
      )!,
      addonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}addon_id'],
      )!,
      gitRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}git_ref'],
      ),
    );
  }

  @override
  $BundleItemsTable createAlias(String alias) {
    return $BundleItemsTable(attachedDatabase, alias);
  }
}

class BundleItem extends DataClass implements Insertable<BundleItem> {
  final String bundleId;
  final String addonId;
  final String? gitRef;
  const BundleItem({
    required this.bundleId,
    required this.addonId,
    this.gitRef,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bundle_id'] = Variable<String>(bundleId);
    map['addon_id'] = Variable<String>(addonId);
    if (!nullToAbsent || gitRef != null) {
      map['git_ref'] = Variable<String>(gitRef);
    }
    return map;
  }

  BundleItemsCompanion toCompanion(bool nullToAbsent) {
    return BundleItemsCompanion(
      bundleId: Value(bundleId),
      addonId: Value(addonId),
      gitRef: gitRef == null && nullToAbsent
          ? const Value.absent()
          : Value(gitRef),
    );
  }

  factory BundleItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BundleItem(
      bundleId: serializer.fromJson<String>(json['bundleId']),
      addonId: serializer.fromJson<String>(json['addonId']),
      gitRef: serializer.fromJson<String?>(json['gitRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bundleId': serializer.toJson<String>(bundleId),
      'addonId': serializer.toJson<String>(addonId),
      'gitRef': serializer.toJson<String?>(gitRef),
    };
  }

  BundleItem copyWith({
    String? bundleId,
    String? addonId,
    Value<String?> gitRef = const Value.absent(),
  }) => BundleItem(
    bundleId: bundleId ?? this.bundleId,
    addonId: addonId ?? this.addonId,
    gitRef: gitRef.present ? gitRef.value : this.gitRef,
  );
  BundleItem copyWithCompanion(BundleItemsCompanion data) {
    return BundleItem(
      bundleId: data.bundleId.present ? data.bundleId.value : this.bundleId,
      addonId: data.addonId.present ? data.addonId.value : this.addonId,
      gitRef: data.gitRef.present ? data.gitRef.value : this.gitRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BundleItem(')
          ..write('bundleId: $bundleId, ')
          ..write('addonId: $addonId, ')
          ..write('gitRef: $gitRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bundleId, addonId, gitRef);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BundleItem &&
          other.bundleId == this.bundleId &&
          other.addonId == this.addonId &&
          other.gitRef == this.gitRef);
}

class BundleItemsCompanion extends UpdateCompanion<BundleItem> {
  final Value<String> bundleId;
  final Value<String> addonId;
  final Value<String?> gitRef;
  final Value<int> rowid;
  const BundleItemsCompanion({
    this.bundleId = const Value.absent(),
    this.addonId = const Value.absent(),
    this.gitRef = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BundleItemsCompanion.insert({
    required String bundleId,
    required String addonId,
    this.gitRef = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bundleId = Value(bundleId),
       addonId = Value(addonId);
  static Insertable<BundleItem> custom({
    Expression<String>? bundleId,
    Expression<String>? addonId,
    Expression<String>? gitRef,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bundleId != null) 'bundle_id': bundleId,
      if (addonId != null) 'addon_id': addonId,
      if (gitRef != null) 'git_ref': gitRef,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BundleItemsCompanion copyWith({
    Value<String>? bundleId,
    Value<String>? addonId,
    Value<String?>? gitRef,
    Value<int>? rowid,
  }) {
    return BundleItemsCompanion(
      bundleId: bundleId ?? this.bundleId,
      addonId: addonId ?? this.addonId,
      gitRef: gitRef ?? this.gitRef,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bundleId.present) {
      map['bundle_id'] = Variable<String>(bundleId.value);
    }
    if (addonId.present) {
      map['addon_id'] = Variable<String>(addonId.value);
    }
    if (gitRef.present) {
      map['git_ref'] = Variable<String>(gitRef.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BundleItemsCompanion(')
          ..write('bundleId: $bundleId, ')
          ..write('addonId: $addonId, ')
          ..write('gitRef: $gitRef, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MacrosTable extends Macros with TableInfo<$MacrosTable, Macro> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MacrosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MacroSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MacroSource>($MacrosTable.$convertersource);
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogCommitMeta = const VerificationMeta(
    'catalogCommit',
  );
  @override
  late final GeneratedColumn<String> catalogCommit = GeneratedColumn<String>(
    'catalog_commit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    name,
    fileName,
    source,
    installedAt,
    updatedAt,
    catalogCommit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'macros';
  @override
  VerificationContext validateIntegrity(
    Insertable<Macro> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('catalog_commit')) {
      context.handle(
        _catalogCommitMeta,
        catalogCommit.isAcceptableOrUnknown(
          data['catalog_commit']!,
          _catalogCommitMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {profileId, fileName},
  ];
  @override
  Macro map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Macro(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      source: $MacrosTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      catalogCommit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_commit'],
      ),
    );
  }

  @override
  $MacrosTable createAlias(String alias) {
    return $MacrosTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MacroSource, String, String> $convertersource =
      const EnumNameConverter<MacroSource>(MacroSource.values);
}

class Macro extends DataClass implements Insertable<Macro> {
  final String id;
  final String profileId;
  final String name;
  final String fileName;
  final MacroSource source;
  final DateTime installedAt;
  final DateTime updatedAt;
  final String? catalogCommit;
  const Macro({
    required this.id,
    required this.profileId,
    required this.name,
    required this.fileName,
    required this.source,
    required this.installedAt,
    required this.updatedAt,
    this.catalogCommit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['name'] = Variable<String>(name);
    map['file_name'] = Variable<String>(fileName);
    {
      map['source'] = Variable<String>(
        $MacrosTable.$convertersource.toSql(source),
      );
    }
    map['installed_at'] = Variable<DateTime>(installedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || catalogCommit != null) {
      map['catalog_commit'] = Variable<String>(catalogCommit);
    }
    return map;
  }

  MacrosCompanion toCompanion(bool nullToAbsent) {
    return MacrosCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      fileName: Value(fileName),
      source: Value(source),
      installedAt: Value(installedAt),
      updatedAt: Value(updatedAt),
      catalogCommit: catalogCommit == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogCommit),
    );
  }

  factory Macro.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Macro(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      fileName: serializer.fromJson<String>(json['fileName']),
      source: $MacrosTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      catalogCommit: serializer.fromJson<String?>(json['catalogCommit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'name': serializer.toJson<String>(name),
      'fileName': serializer.toJson<String>(fileName),
      'source': serializer.toJson<String>(
        $MacrosTable.$convertersource.toJson(source),
      ),
      'installedAt': serializer.toJson<DateTime>(installedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'catalogCommit': serializer.toJson<String?>(catalogCommit),
    };
  }

  Macro copyWith({
    String? id,
    String? profileId,
    String? name,
    String? fileName,
    MacroSource? source,
    DateTime? installedAt,
    DateTime? updatedAt,
    Value<String?> catalogCommit = const Value.absent(),
  }) => Macro(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    name: name ?? this.name,
    fileName: fileName ?? this.fileName,
    source: source ?? this.source,
    installedAt: installedAt ?? this.installedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    catalogCommit: catalogCommit.present
        ? catalogCommit.value
        : this.catalogCommit,
  );
  Macro copyWithCompanion(MacrosCompanion data) {
    return Macro(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      source: data.source.present ? data.source.value : this.source,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      catalogCommit: data.catalogCommit.present
          ? data.catalogCommit.value
          : this.catalogCommit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Macro(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('fileName: $fileName, ')
          ..write('source: $source, ')
          ..write('installedAt: $installedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('catalogCommit: $catalogCommit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    name,
    fileName,
    source,
    installedAt,
    updatedAt,
    catalogCommit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Macro &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.fileName == this.fileName &&
          other.source == this.source &&
          other.installedAt == this.installedAt &&
          other.updatedAt == this.updatedAt &&
          other.catalogCommit == this.catalogCommit);
}

class MacrosCompanion extends UpdateCompanion<Macro> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> name;
  final Value<String> fileName;
  final Value<MacroSource> source;
  final Value<DateTime> installedAt;
  final Value<DateTime> updatedAt;
  final Value<String?> catalogCommit;
  final Value<int> rowid;
  const MacrosCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.fileName = const Value.absent(),
    this.source = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.catalogCommit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MacrosCompanion.insert({
    required String id,
    required String profileId,
    required String name,
    required String fileName,
    required MacroSource source,
    required DateTime installedAt,
    required DateTime updatedAt,
    this.catalogCommit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       name = Value(name),
       fileName = Value(fileName),
       source = Value(source),
       installedAt = Value(installedAt),
       updatedAt = Value(updatedAt);
  static Insertable<Macro> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? name,
    Expression<String>? fileName,
    Expression<String>? source,
    Expression<DateTime>? installedAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? catalogCommit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (fileName != null) 'file_name': fileName,
      if (source != null) 'source': source,
      if (installedAt != null) 'installed_at': installedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (catalogCommit != null) 'catalog_commit': catalogCommit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MacrosCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? name,
    Value<String>? fileName,
    Value<MacroSource>? source,
    Value<DateTime>? installedAt,
    Value<DateTime>? updatedAt,
    Value<String?>? catalogCommit,
    Value<int>? rowid,
  }) {
    return MacrosCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      fileName: fileName ?? this.fileName,
      source: source ?? this.source,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      catalogCommit: catalogCommit ?? this.catalogCommit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $MacrosTable.$convertersource.toSql(source.value),
      );
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (catalogCommit.present) {
      map['catalog_commit'] = Variable<String>(catalogCommit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MacrosCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('fileName: $fileName, ')
          ..write('source: $source, ')
          ..write('installedAt: $installedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('catalogCommit: $catalogCommit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogCacheTable extends CatalogCache
    with TableInfo<$CatalogCacheTable, CatalogCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
    'last_modified',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadPathMeta = const VerificationMeta(
    'payloadPath',
  );
  @override
  late final GeneratedColumn<String> payloadPath = GeneratedColumn<String>(
    'payload_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CacheStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CacheStatus>($CatalogCacheTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [
    key,
    etag,
    lastModified,
    payloadPath,
    fetchedAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('payload_path')) {
      context.handle(
        _payloadPathMeta,
        payloadPath.isAcceptableOrUnknown(
          data['payload_path']!,
          _payloadPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadPathMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CatalogCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogCacheEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified'],
      ),
      payloadPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_path'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      status: $CatalogCacheTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $CatalogCacheTable createAlias(String alias) {
    return $CatalogCacheTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CacheStatus, String, String> $converterstatus =
      const EnumNameConverter<CacheStatus>(CacheStatus.values);
}

class CatalogCacheEntry extends DataClass
    implements Insertable<CatalogCacheEntry> {
  final String key;
  final String? etag;
  final String? lastModified;
  final String payloadPath;
  final DateTime fetchedAt;
  final CacheStatus status;
  const CatalogCacheEntry({
    required this.key,
    this.etag,
    this.lastModified,
    required this.payloadPath,
    required this.fetchedAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<String>(lastModified);
    }
    map['payload_path'] = Variable<String>(payloadPath);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    {
      map['status'] = Variable<String>(
        $CatalogCacheTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  CatalogCacheCompanion toCompanion(bool nullToAbsent) {
    return CatalogCacheCompanion(
      key: Value(key),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
      payloadPath: Value(payloadPath),
      fetchedAt: Value(fetchedAt),
      status: Value(status),
    );
  }

  factory CatalogCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogCacheEntry(
      key: serializer.fromJson<String>(json['key']),
      etag: serializer.fromJson<String?>(json['etag']),
      lastModified: serializer.fromJson<String?>(json['lastModified']),
      payloadPath: serializer.fromJson<String>(json['payloadPath']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      status: $CatalogCacheTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'etag': serializer.toJson<String?>(etag),
      'lastModified': serializer.toJson<String?>(lastModified),
      'payloadPath': serializer.toJson<String>(payloadPath),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'status': serializer.toJson<String>(
        $CatalogCacheTable.$converterstatus.toJson(status),
      ),
    };
  }

  CatalogCacheEntry copyWith({
    String? key,
    Value<String?> etag = const Value.absent(),
    Value<String?> lastModified = const Value.absent(),
    String? payloadPath,
    DateTime? fetchedAt,
    CacheStatus? status,
  }) => CatalogCacheEntry(
    key: key ?? this.key,
    etag: etag.present ? etag.value : this.etag,
    lastModified: lastModified.present ? lastModified.value : this.lastModified,
    payloadPath: payloadPath ?? this.payloadPath,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    status: status ?? this.status,
  );
  CatalogCacheEntry copyWithCompanion(CatalogCacheCompanion data) {
    return CatalogCacheEntry(
      key: data.key.present ? data.key.value : this.key,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      payloadPath: data.payloadPath.present
          ? data.payloadPath.value
          : this.payloadPath,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCacheEntry(')
          ..write('key: $key, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('payloadPath: $payloadPath, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(key, etag, lastModified, payloadPath, fetchedAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogCacheEntry &&
          other.key == this.key &&
          other.etag == this.etag &&
          other.lastModified == this.lastModified &&
          other.payloadPath == this.payloadPath &&
          other.fetchedAt == this.fetchedAt &&
          other.status == this.status);
}

class CatalogCacheCompanion extends UpdateCompanion<CatalogCacheEntry> {
  final Value<String> key;
  final Value<String?> etag;
  final Value<String?> lastModified;
  final Value<String> payloadPath;
  final Value<DateTime> fetchedAt;
  final Value<CacheStatus> status;
  final Value<int> rowid;
  const CatalogCacheCompanion({
    this.key = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.payloadPath = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogCacheCompanion.insert({
    required String key,
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    required String payloadPath,
    required DateTime fetchedAt,
    required CacheStatus status,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       payloadPath = Value(payloadPath),
       fetchedAt = Value(fetchedAt),
       status = Value(status);
  static Insertable<CatalogCacheEntry> custom({
    Expression<String>? key,
    Expression<String>? etag,
    Expression<String>? lastModified,
    Expression<String>? payloadPath,
    Expression<DateTime>? fetchedAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (etag != null) 'etag': etag,
      if (lastModified != null) 'last_modified': lastModified,
      if (payloadPath != null) 'payload_path': payloadPath,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogCacheCompanion copyWith({
    Value<String>? key,
    Value<String?>? etag,
    Value<String?>? lastModified,
    Value<String>? payloadPath,
    Value<DateTime>? fetchedAt,
    Value<CacheStatus>? status,
    Value<int>? rowid,
  }) {
    return CatalogCacheCompanion(
      key: key ?? this.key,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      payloadPath: payloadPath ?? this.payloadPath,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
    }
    if (payloadPath.present) {
      map['payload_path'] = Variable<String>(payloadPath.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $CatalogCacheTable.$converterstatus.toSql(status.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCacheCompanion(')
          ..write('key: $key, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('payloadPath: $payloadPath, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BuildsTable builds = $BuildsTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $InstalledAddonsTable installedAddons = $InstalledAddonsTable(
    this,
  );
  late final $PythonPackagesTable pythonPackages = $PythonPackagesTable(this);
  late final $BundlesTable bundles = $BundlesTable(this);
  late final $BundleItemsTable bundleItems = $BundleItemsTable(this);
  late final $MacrosTable macros = $MacrosTable(this);
  late final $CatalogCacheTable catalogCache = $CatalogCacheTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final BuildsDao buildsDao = BuildsDao(this as AppDatabase);
  late final ProfilesDao profilesDao = ProfilesDao(this as AppDatabase);
  late final InstalledAddonsDao installedAddonsDao = InstalledAddonsDao(
    this as AppDatabase,
  );
  late final PythonPackagesDao pythonPackagesDao = PythonPackagesDao(
    this as AppDatabase,
  );
  late final BundlesDao bundlesDao = BundlesDao(this as AppDatabase);
  late final MacrosDao macrosDao = MacrosDao(this as AppDatabase);
  late final CatalogCacheDao catalogCacheDao = CatalogCacheDao(
    this as AppDatabase,
  );
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    builds,
    profiles,
    installedAddons,
    pythonPackages,
    bundles,
    bundleItems,
    macros,
    catalogCache,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('installed_addons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('python_packages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bundles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bundle_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('macros', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$BuildsTableCreateCompanionBuilder =
    BuildsCompanion Function({
      required String id,
      required BuildKind kind,
      required String version,
      required BuildChannel channel,
      required BuildPlatform platform,
      required String arch,
      Value<String?> sourceUrl,
      Value<String?> assetName,
      required String localPath,
      Value<String?> sha256,
      Value<bool> verified,
      Value<String?> pythonVersion,
      Value<String?> pythonPath,
      Value<int?> sizeBytes,
      required BuildStatus status,
      Value<String?> releaseNotesUrl,
      required DateTime installedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BuildsTableUpdateCompanionBuilder =
    BuildsCompanion Function({
      Value<String> id,
      Value<BuildKind> kind,
      Value<String> version,
      Value<BuildChannel> channel,
      Value<BuildPlatform> platform,
      Value<String> arch,
      Value<String?> sourceUrl,
      Value<String?> assetName,
      Value<String> localPath,
      Value<String?> sha256,
      Value<bool> verified,
      Value<String?> pythonVersion,
      Value<String?> pythonPath,
      Value<int?> sizeBytes,
      Value<BuildStatus> status,
      Value<String?> releaseNotesUrl,
      Value<DateTime> installedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BuildsTableReferences
    extends BaseReferences<_$AppDatabase, $BuildsTable, Build> {
  $$BuildsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProfilesTable, List<Profile>> _profilesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.profiles,
    aliasName: 'builds__id__profiles__build_id',
  );

  $$ProfilesTableProcessedTableManager get profilesRefs {
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.buildId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_profilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BuildsTableFilterComposer
    extends Composer<_$AppDatabase, $BuildsTable> {
  $$BuildsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BuildKind, BuildKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BuildChannel, BuildChannel, String>
  get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<BuildPlatform, BuildPlatform, String>
  get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get arch => $composableBuilder(
    column: $table.arch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetName => $composableBuilder(
    column: $table.assetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pythonVersion => $composableBuilder(
    column: $table.pythonVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pythonPath => $composableBuilder(
    column: $table.pythonPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BuildStatus, BuildStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get releaseNotesUrl => $composableBuilder(
    column: $table.releaseNotesUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> profilesRefs(
    Expression<bool> Function($$ProfilesTableFilterComposer f) f,
  ) {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.buildId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BuildsTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildsTable> {
  $$BuildsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arch => $composableBuilder(
    column: $table.arch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetName => $composableBuilder(
    column: $table.assetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pythonVersion => $composableBuilder(
    column: $table.pythonVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pythonPath => $composableBuilder(
    column: $table.pythonPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseNotesUrl => $composableBuilder(
    column: $table.releaseNotesUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BuildsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildsTable> {
  $$BuildsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BuildKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BuildChannel, String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BuildPlatform, String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get arch =>
      $composableBuilder(column: $table.arch, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get assetName =>
      $composableBuilder(column: $table.assetName, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<bool> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => column);

  GeneratedColumn<String> get pythonVersion => $composableBuilder(
    column: $table.pythonVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pythonPath => $composableBuilder(
    column: $table.pythonPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BuildStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get releaseNotesUrl => $composableBuilder(
    column: $table.releaseNotesUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> profilesRefs<T extends Object>(
    Expression<T> Function($$ProfilesTableAnnotationComposer a) f,
  ) {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.buildId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BuildsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BuildsTable,
          Build,
          $$BuildsTableFilterComposer,
          $$BuildsTableOrderingComposer,
          $$BuildsTableAnnotationComposer,
          $$BuildsTableCreateCompanionBuilder,
          $$BuildsTableUpdateCompanionBuilder,
          (Build, $$BuildsTableReferences),
          Build,
          PrefetchHooks Function({bool profilesRefs})
        > {
  $$BuildsTableTableManager(_$AppDatabase db, $BuildsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<BuildKind> kind = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<BuildChannel> channel = const Value.absent(),
                Value<BuildPlatform> platform = const Value.absent(),
                Value<String> arch = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> assetName = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<bool> verified = const Value.absent(),
                Value<String?> pythonVersion = const Value.absent(),
                Value<String?> pythonPath = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<BuildStatus> status = const Value.absent(),
                Value<String?> releaseNotesUrl = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BuildsCompanion(
                id: id,
                kind: kind,
                version: version,
                channel: channel,
                platform: platform,
                arch: arch,
                sourceUrl: sourceUrl,
                assetName: assetName,
                localPath: localPath,
                sha256: sha256,
                verified: verified,
                pythonVersion: pythonVersion,
                pythonPath: pythonPath,
                sizeBytes: sizeBytes,
                status: status,
                releaseNotesUrl: releaseNotesUrl,
                installedAt: installedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required BuildKind kind,
                required String version,
                required BuildChannel channel,
                required BuildPlatform platform,
                required String arch,
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> assetName = const Value.absent(),
                required String localPath,
                Value<String?> sha256 = const Value.absent(),
                Value<bool> verified = const Value.absent(),
                Value<String?> pythonVersion = const Value.absent(),
                Value<String?> pythonPath = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                required BuildStatus status,
                Value<String?> releaseNotesUrl = const Value.absent(),
                required DateTime installedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BuildsCompanion.insert(
                id: id,
                kind: kind,
                version: version,
                channel: channel,
                platform: platform,
                arch: arch,
                sourceUrl: sourceUrl,
                assetName: assetName,
                localPath: localPath,
                sha256: sha256,
                verified: verified,
                pythonVersion: pythonVersion,
                pythonPath: pythonPath,
                sizeBytes: sizeBytes,
                status: status,
                releaseNotesUrl: releaseNotesUrl,
                installedAt: installedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BuildsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({profilesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (profilesRefs) db.profiles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (profilesRefs)
                    await $_getPrefetchedData<Build, $BuildsTable, Profile>(
                      currentTable: table,
                      referencedTable: $$BuildsTableReferences
                          ._profilesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BuildsTableReferences(db, table, p0).profilesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.buildId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BuildsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BuildsTable,
      Build,
      $$BuildsTableFilterComposer,
      $$BuildsTableOrderingComposer,
      $$BuildsTableAnnotationComposer,
      $$BuildsTableCreateCompanionBuilder,
      $$BuildsTableUpdateCompanionBuilder,
      (Build, $$BuildsTableReferences),
      Build,
      PrefetchHooks Function({bool profilesRefs})
    >;
typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required String buildId,
      required String pythonVersion,
      Value<int?> iconColor,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastUsedAt,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String> buildId,
      Value<String> pythonVersion,
      Value<int?> iconColor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastUsedAt,
      Value<int> rowid,
    });

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BuildsTable _buildIdTable(_$AppDatabase db) =>
      db.builds.createAlias('profiles__build_id__builds__id');

  $$BuildsTableProcessedTableManager get buildId {
    final $_column = $_itemColumn<String>('build_id')!;

    final manager = $$BuildsTableTableManager(
      $_db,
      $_db.builds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_buildIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InstalledAddonsTable, List<InstalledAddon>>
  _installedAddonsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.installedAddons,
    aliasName: 'profiles__id__installed_addons__profile_id',
  );

  $$InstalledAddonsTableProcessedTableManager get installedAddonsRefs {
    final manager = $$InstalledAddonsTableTableManager(
      $_db,
      $_db.installedAddons,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _installedAddonsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PythonPackagesTable, List<PythonPackage>>
  _pythonPackagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pythonPackages,
    aliasName: 'profiles__id__python_packages__profile_id',
  );

  $$PythonPackagesTableProcessedTableManager get pythonPackagesRefs {
    final manager = $$PythonPackagesTableTableManager(
      $_db,
      $_db.pythonPackages,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pythonPackagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MacrosTable, List<Macro>> _macrosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.macros,
    aliasName: 'profiles__id__macros__profile_id',
  );

  $$MacrosTableProcessedTableManager get macrosRefs {
    final manager = $$MacrosTableTableManager(
      $_db,
      $_db.macros,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_macrosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pythonVersion => $composableBuilder(
    column: $table.pythonVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconColor => $composableBuilder(
    column: $table.iconColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BuildsTableFilterComposer get buildId {
    final $$BuildsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.buildId,
      referencedTable: $db.builds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildsTableFilterComposer(
            $db: $db,
            $table: $db.builds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> installedAddonsRefs(
    Expression<bool> Function($$InstalledAddonsTableFilterComposer f) f,
  ) {
    final $$InstalledAddonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installedAddons,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstalledAddonsTableFilterComposer(
            $db: $db,
            $table: $db.installedAddons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pythonPackagesRefs(
    Expression<bool> Function($$PythonPackagesTableFilterComposer f) f,
  ) {
    final $$PythonPackagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pythonPackages,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PythonPackagesTableFilterComposer(
            $db: $db,
            $table: $db.pythonPackages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> macrosRefs(
    Expression<bool> Function($$MacrosTableFilterComposer f) f,
  ) {
    final $$MacrosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.macros,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MacrosTableFilterComposer(
            $db: $db,
            $table: $db.macros,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pythonVersion => $composableBuilder(
    column: $table.pythonVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconColor => $composableBuilder(
    column: $table.iconColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BuildsTableOrderingComposer get buildId {
    final $$BuildsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.buildId,
      referencedTable: $db.builds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildsTableOrderingComposer(
            $db: $db,
            $table: $db.builds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pythonVersion => $composableBuilder(
    column: $table.pythonVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get iconColor =>
      $composableBuilder(column: $table.iconColor, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  $$BuildsTableAnnotationComposer get buildId {
    final $$BuildsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.buildId,
      referencedTable: $db.builds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildsTableAnnotationComposer(
            $db: $db,
            $table: $db.builds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> installedAddonsRefs<T extends Object>(
    Expression<T> Function($$InstalledAddonsTableAnnotationComposer a) f,
  ) {
    final $$InstalledAddonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installedAddons,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstalledAddonsTableAnnotationComposer(
            $db: $db,
            $table: $db.installedAddons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pythonPackagesRefs<T extends Object>(
    Expression<T> Function($$PythonPackagesTableAnnotationComposer a) f,
  ) {
    final $$PythonPackagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pythonPackages,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PythonPackagesTableAnnotationComposer(
            $db: $db,
            $table: $db.pythonPackages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> macrosRefs<T extends Object>(
    Expression<T> Function($$MacrosTableAnnotationComposer a) f,
  ) {
    final $$MacrosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.macros,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MacrosTableAnnotationComposer(
            $db: $db,
            $table: $db.macros,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, $$ProfilesTableReferences),
          Profile,
          PrefetchHooks Function({
            bool buildId,
            bool installedAddonsRefs,
            bool pythonPackagesRefs,
            bool macrosRefs,
          })
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> buildId = const Value.absent(),
                Value<String> pythonVersion = const Value.absent(),
                Value<int?> iconColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                description: description,
                buildId: buildId,
                pythonVersion: pythonVersion,
                iconColor: iconColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required String buildId,
                required String pythonVersion,
                Value<int?> iconColor = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                description: description,
                buildId: buildId,
                pythonVersion: pythonVersion,
                iconColor: iconColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                buildId = false,
                installedAddonsRefs = false,
                pythonPackagesRefs = false,
                macrosRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (installedAddonsRefs) db.installedAddons,
                    if (pythonPackagesRefs) db.pythonPackages,
                    if (macrosRefs) db.macros,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (buildId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.buildId,
                                    referencedTable: $$ProfilesTableReferences
                                        ._buildIdTable(db),
                                    referencedColumn: $$ProfilesTableReferences
                                        ._buildIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (installedAddonsRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          InstalledAddon
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._installedAddonsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).installedAddonsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pythonPackagesRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          PythonPackage
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._pythonPackagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).pythonPackagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (macrosRefs)
                        await $_getPrefetchedData<
                          Profile,
                          $ProfilesTable,
                          Macro
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._macrosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).macrosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.profileId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, $$ProfilesTableReferences),
      Profile,
      PrefetchHooks Function({
        bool buildId,
        bool installedAddonsRefs,
        bool pythonPackagesRefs,
        bool macrosRefs,
      })
    >;
typedef $$InstalledAddonsTableCreateCompanionBuilder =
    InstalledAddonsCompanion Function({
      required String id,
      required String profileId,
      required String addonId,
      required String displayName,
      Value<String?> gitRef,
      Value<String?> version,
      required DateTime installedAt,
      required DateTime updatedAt,
      Value<DateTime?> catalogLastUpdate,
      Value<String?> sourceUrl,
      Value<bool> hasRequirements,
      Value<int> rowid,
    });
typedef $$InstalledAddonsTableUpdateCompanionBuilder =
    InstalledAddonsCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> addonId,
      Value<String> displayName,
      Value<String?> gitRef,
      Value<String?> version,
      Value<DateTime> installedAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> catalogLastUpdate,
      Value<String?> sourceUrl,
      Value<bool> hasRequirements,
      Value<int> rowid,
    });

final class $$InstalledAddonsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InstalledAddonsTable, InstalledAddon> {
  $$InstalledAddonsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('installed_addons__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<String>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InstalledAddonsTableFilterComposer
    extends Composer<_$AppDatabase, $InstalledAddonsTable> {
  $$InstalledAddonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addonId => $composableBuilder(
    column: $table.addonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gitRef => $composableBuilder(
    column: $table.gitRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get catalogLastUpdate => $composableBuilder(
    column: $table.catalogLastUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasRequirements => $composableBuilder(
    column: $table.hasRequirements,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstalledAddonsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstalledAddonsTable> {
  $$InstalledAddonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addonId => $composableBuilder(
    column: $table.addonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gitRef => $composableBuilder(
    column: $table.gitRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get catalogLastUpdate => $composableBuilder(
    column: $table.catalogLastUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasRequirements => $composableBuilder(
    column: $table.hasRequirements,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstalledAddonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstalledAddonsTable> {
  $$InstalledAddonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get addonId =>
      $composableBuilder(column: $table.addonId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gitRef =>
      $composableBuilder(column: $table.gitRef, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get catalogLastUpdate => $composableBuilder(
    column: $table.catalogLastUpdate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<bool> get hasRequirements => $composableBuilder(
    column: $table.hasRequirements,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstalledAddonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstalledAddonsTable,
          InstalledAddon,
          $$InstalledAddonsTableFilterComposer,
          $$InstalledAddonsTableOrderingComposer,
          $$InstalledAddonsTableAnnotationComposer,
          $$InstalledAddonsTableCreateCompanionBuilder,
          $$InstalledAddonsTableUpdateCompanionBuilder,
          (InstalledAddon, $$InstalledAddonsTableReferences),
          InstalledAddon,
          PrefetchHooks Function({bool profileId})
        > {
  $$InstalledAddonsTableTableManager(
    _$AppDatabase db,
    $InstalledAddonsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstalledAddonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstalledAddonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstalledAddonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> addonId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> gitRef = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> catalogLastUpdate = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<bool> hasRequirements = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstalledAddonsCompanion(
                id: id,
                profileId: profileId,
                addonId: addonId,
                displayName: displayName,
                gitRef: gitRef,
                version: version,
                installedAt: installedAt,
                updatedAt: updatedAt,
                catalogLastUpdate: catalogLastUpdate,
                sourceUrl: sourceUrl,
                hasRequirements: hasRequirements,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String addonId,
                required String displayName,
                Value<String?> gitRef = const Value.absent(),
                Value<String?> version = const Value.absent(),
                required DateTime installedAt,
                required DateTime updatedAt,
                Value<DateTime?> catalogLastUpdate = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<bool> hasRequirements = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstalledAddonsCompanion.insert(
                id: id,
                profileId: profileId,
                addonId: addonId,
                displayName: displayName,
                gitRef: gitRef,
                version: version,
                installedAt: installedAt,
                updatedAt: updatedAt,
                catalogLastUpdate: catalogLastUpdate,
                sourceUrl: sourceUrl,
                hasRequirements: hasRequirements,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InstalledAddonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable:
                                    $$InstalledAddonsTableReferences
                                        ._profileIdTable(db),
                                referencedColumn:
                                    $$InstalledAddonsTableReferences
                                        ._profileIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InstalledAddonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstalledAddonsTable,
      InstalledAddon,
      $$InstalledAddonsTableFilterComposer,
      $$InstalledAddonsTableOrderingComposer,
      $$InstalledAddonsTableAnnotationComposer,
      $$InstalledAddonsTableCreateCompanionBuilder,
      $$InstalledAddonsTableUpdateCompanionBuilder,
      (InstalledAddon, $$InstalledAddonsTableReferences),
      InstalledAddon,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$PythonPackagesTableCreateCompanionBuilder =
    PythonPackagesCompanion Function({
      required String id,
      required String profileId,
      required String name,
      Value<String?> version,
      required String targetDir,
      required String source,
      required DateTime installedAt,
      Value<int> rowid,
    });
typedef $$PythonPackagesTableUpdateCompanionBuilder =
    PythonPackagesCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> name,
      Value<String?> version,
      Value<String> targetDir,
      Value<String> source,
      Value<DateTime> installedAt,
      Value<int> rowid,
    });

final class $$PythonPackagesTableReferences
    extends BaseReferences<_$AppDatabase, $PythonPackagesTable, PythonPackage> {
  $$PythonPackagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('python_packages__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<String>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PythonPackagesTableFilterComposer
    extends Composer<_$AppDatabase, $PythonPackagesTable> {
  $$PythonPackagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDir => $composableBuilder(
    column: $table.targetDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PythonPackagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PythonPackagesTable> {
  $$PythonPackagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDir => $composableBuilder(
    column: $table.targetDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PythonPackagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PythonPackagesTable> {
  $$PythonPackagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get targetDir =>
      $composableBuilder(column: $table.targetDir, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PythonPackagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PythonPackagesTable,
          PythonPackage,
          $$PythonPackagesTableFilterComposer,
          $$PythonPackagesTableOrderingComposer,
          $$PythonPackagesTableAnnotationComposer,
          $$PythonPackagesTableCreateCompanionBuilder,
          $$PythonPackagesTableUpdateCompanionBuilder,
          (PythonPackage, $$PythonPackagesTableReferences),
          PythonPackage,
          PrefetchHooks Function({bool profileId})
        > {
  $$PythonPackagesTableTableManager(
    _$AppDatabase db,
    $PythonPackagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PythonPackagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PythonPackagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PythonPackagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String> targetDir = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PythonPackagesCompanion(
                id: id,
                profileId: profileId,
                name: name,
                version: version,
                targetDir: targetDir,
                source: source,
                installedAt: installedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String name,
                Value<String?> version = const Value.absent(),
                required String targetDir,
                required String source,
                required DateTime installedAt,
                Value<int> rowid = const Value.absent(),
              }) => PythonPackagesCompanion.insert(
                id: id,
                profileId: profileId,
                name: name,
                version: version,
                targetDir: targetDir,
                source: source,
                installedAt: installedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PythonPackagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$PythonPackagesTableReferences
                                    ._profileIdTable(db),
                                referencedColumn:
                                    $$PythonPackagesTableReferences
                                        ._profileIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PythonPackagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PythonPackagesTable,
      PythonPackage,
      $$PythonPackagesTableFilterComposer,
      $$PythonPackagesTableOrderingComposer,
      $$PythonPackagesTableAnnotationComposer,
      $$PythonPackagesTableCreateCompanionBuilder,
      $$PythonPackagesTableUpdateCompanionBuilder,
      (PythonPackage, $$PythonPackagesTableReferences),
      PythonPackage,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$BundlesTableCreateCompanionBuilder =
    BundlesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BundlesTableUpdateCompanionBuilder =
    BundlesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BundlesTableReferences
    extends BaseReferences<_$AppDatabase, $BundlesTable, Bundle> {
  $$BundlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BundleItemsTable, List<BundleItem>>
  _bundleItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bundleItems,
    aliasName: 'bundles__id__bundle_items__bundle_id',
  );

  $$BundleItemsTableProcessedTableManager get bundleItemsRefs {
    final manager = $$BundleItemsTableTableManager(
      $_db,
      $_db.bundleItems,
    ).filter((f) => f.bundleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bundleItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BundlesTableFilterComposer
    extends Composer<_$AppDatabase, $BundlesTable> {
  $$BundlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> bundleItemsRefs(
    Expression<bool> Function($$BundleItemsTableFilterComposer f) f,
  ) {
    final $$BundleItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bundleItems,
      getReferencedColumn: (t) => t.bundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BundleItemsTableFilterComposer(
            $db: $db,
            $table: $db.bundleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BundlesTableOrderingComposer
    extends Composer<_$AppDatabase, $BundlesTable> {
  $$BundlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BundlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BundlesTable> {
  $$BundlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> bundleItemsRefs<T extends Object>(
    Expression<T> Function($$BundleItemsTableAnnotationComposer a) f,
  ) {
    final $$BundleItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bundleItems,
      getReferencedColumn: (t) => t.bundleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BundleItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.bundleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BundlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BundlesTable,
          Bundle,
          $$BundlesTableFilterComposer,
          $$BundlesTableOrderingComposer,
          $$BundlesTableAnnotationComposer,
          $$BundlesTableCreateCompanionBuilder,
          $$BundlesTableUpdateCompanionBuilder,
          (Bundle, $$BundlesTableReferences),
          Bundle,
          PrefetchHooks Function({bool bundleItemsRefs})
        > {
  $$BundlesTableTableManager(_$AppDatabase db, $BundlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BundlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BundlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BundlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BundlesCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BundlesCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BundlesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bundleItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (bundleItemsRefs) db.bundleItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bundleItemsRefs)
                    await $_getPrefetchedData<
                      Bundle,
                      $BundlesTable,
                      BundleItem
                    >(
                      currentTable: table,
                      referencedTable: $$BundlesTableReferences
                          ._bundleItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$BundlesTableReferences(
                        db,
                        table,
                        p0,
                      ).bundleItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.bundleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BundlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BundlesTable,
      Bundle,
      $$BundlesTableFilterComposer,
      $$BundlesTableOrderingComposer,
      $$BundlesTableAnnotationComposer,
      $$BundlesTableCreateCompanionBuilder,
      $$BundlesTableUpdateCompanionBuilder,
      (Bundle, $$BundlesTableReferences),
      Bundle,
      PrefetchHooks Function({bool bundleItemsRefs})
    >;
typedef $$BundleItemsTableCreateCompanionBuilder =
    BundleItemsCompanion Function({
      required String bundleId,
      required String addonId,
      Value<String?> gitRef,
      Value<int> rowid,
    });
typedef $$BundleItemsTableUpdateCompanionBuilder =
    BundleItemsCompanion Function({
      Value<String> bundleId,
      Value<String> addonId,
      Value<String?> gitRef,
      Value<int> rowid,
    });

final class $$BundleItemsTableReferences
    extends BaseReferences<_$AppDatabase, $BundleItemsTable, BundleItem> {
  $$BundleItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BundlesTable _bundleIdTable(_$AppDatabase db) =>
      db.bundles.createAlias('bundle_items__bundle_id__bundles__id');

  $$BundlesTableProcessedTableManager get bundleId {
    final $_column = $_itemColumn<String>('bundle_id')!;

    final manager = $$BundlesTableTableManager(
      $_db,
      $_db.bundles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bundleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BundleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $BundleItemsTable> {
  $$BundleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get addonId => $composableBuilder(
    column: $table.addonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gitRef => $composableBuilder(
    column: $table.gitRef,
    builder: (column) => ColumnFilters(column),
  );

  $$BundlesTableFilterComposer get bundleId {
    final $$BundlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bundleId,
      referencedTable: $db.bundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BundlesTableFilterComposer(
            $db: $db,
            $table: $db.bundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BundleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $BundleItemsTable> {
  $$BundleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get addonId => $composableBuilder(
    column: $table.addonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gitRef => $composableBuilder(
    column: $table.gitRef,
    builder: (column) => ColumnOrderings(column),
  );

  $$BundlesTableOrderingComposer get bundleId {
    final $$BundlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bundleId,
      referencedTable: $db.bundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BundlesTableOrderingComposer(
            $db: $db,
            $table: $db.bundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BundleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BundleItemsTable> {
  $$BundleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get addonId =>
      $composableBuilder(column: $table.addonId, builder: (column) => column);

  GeneratedColumn<String> get gitRef =>
      $composableBuilder(column: $table.gitRef, builder: (column) => column);

  $$BundlesTableAnnotationComposer get bundleId {
    final $$BundlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bundleId,
      referencedTable: $db.bundles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BundlesTableAnnotationComposer(
            $db: $db,
            $table: $db.bundles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BundleItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BundleItemsTable,
          BundleItem,
          $$BundleItemsTableFilterComposer,
          $$BundleItemsTableOrderingComposer,
          $$BundleItemsTableAnnotationComposer,
          $$BundleItemsTableCreateCompanionBuilder,
          $$BundleItemsTableUpdateCompanionBuilder,
          (BundleItem, $$BundleItemsTableReferences),
          BundleItem,
          PrefetchHooks Function({bool bundleId})
        > {
  $$BundleItemsTableTableManager(_$AppDatabase db, $BundleItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BundleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BundleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BundleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bundleId = const Value.absent(),
                Value<String> addonId = const Value.absent(),
                Value<String?> gitRef = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BundleItemsCompanion(
                bundleId: bundleId,
                addonId: addonId,
                gitRef: gitRef,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bundleId,
                required String addonId,
                Value<String?> gitRef = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BundleItemsCompanion.insert(
                bundleId: bundleId,
                addonId: addonId,
                gitRef: gitRef,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BundleItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bundleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bundleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bundleId,
                                referencedTable: $$BundleItemsTableReferences
                                    ._bundleIdTable(db),
                                referencedColumn: $$BundleItemsTableReferences
                                    ._bundleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BundleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BundleItemsTable,
      BundleItem,
      $$BundleItemsTableFilterComposer,
      $$BundleItemsTableOrderingComposer,
      $$BundleItemsTableAnnotationComposer,
      $$BundleItemsTableCreateCompanionBuilder,
      $$BundleItemsTableUpdateCompanionBuilder,
      (BundleItem, $$BundleItemsTableReferences),
      BundleItem,
      PrefetchHooks Function({bool bundleId})
    >;
typedef $$MacrosTableCreateCompanionBuilder =
    MacrosCompanion Function({
      required String id,
      required String profileId,
      required String name,
      required String fileName,
      required MacroSource source,
      required DateTime installedAt,
      required DateTime updatedAt,
      Value<String?> catalogCommit,
      Value<int> rowid,
    });
typedef $$MacrosTableUpdateCompanionBuilder =
    MacrosCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> name,
      Value<String> fileName,
      Value<MacroSource> source,
      Value<DateTime> installedAt,
      Value<DateTime> updatedAt,
      Value<String?> catalogCommit,
      Value<int> rowid,
    });

final class $$MacrosTableReferences
    extends BaseReferences<_$AppDatabase, $MacrosTable, Macro> {
  $$MacrosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('macros__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<String>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MacrosTableFilterComposer
    extends Composer<_$AppDatabase, $MacrosTable> {
  $$MacrosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MacroSource, MacroSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogCommit => $composableBuilder(
    column: $table.catalogCommit,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MacrosTableOrderingComposer
    extends Composer<_$AppDatabase, $MacrosTable> {
  $$MacrosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogCommit => $composableBuilder(
    column: $table.catalogCommit,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MacrosTableAnnotationComposer
    extends Composer<_$AppDatabase, $MacrosTable> {
  $$MacrosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MacroSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get catalogCommit => $composableBuilder(
    column: $table.catalogCommit,
    builder: (column) => column,
  );

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MacrosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MacrosTable,
          Macro,
          $$MacrosTableFilterComposer,
          $$MacrosTableOrderingComposer,
          $$MacrosTableAnnotationComposer,
          $$MacrosTableCreateCompanionBuilder,
          $$MacrosTableUpdateCompanionBuilder,
          (Macro, $$MacrosTableReferences),
          Macro,
          PrefetchHooks Function({bool profileId})
        > {
  $$MacrosTableTableManager(_$AppDatabase db, $MacrosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MacrosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MacrosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MacrosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<MacroSource> source = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> catalogCommit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MacrosCompanion(
                id: id,
                profileId: profileId,
                name: name,
                fileName: fileName,
                source: source,
                installedAt: installedAt,
                updatedAt: updatedAt,
                catalogCommit: catalogCommit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String name,
                required String fileName,
                required MacroSource source,
                required DateTime installedAt,
                required DateTime updatedAt,
                Value<String?> catalogCommit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MacrosCompanion.insert(
                id: id,
                profileId: profileId,
                name: name,
                fileName: fileName,
                source: source,
                installedAt: installedAt,
                updatedAt: updatedAt,
                catalogCommit: catalogCommit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MacrosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.profileId,
                                referencedTable: $$MacrosTableReferences
                                    ._profileIdTable(db),
                                referencedColumn: $$MacrosTableReferences
                                    ._profileIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MacrosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MacrosTable,
      Macro,
      $$MacrosTableFilterComposer,
      $$MacrosTableOrderingComposer,
      $$MacrosTableAnnotationComposer,
      $$MacrosTableCreateCompanionBuilder,
      $$MacrosTableUpdateCompanionBuilder,
      (Macro, $$MacrosTableReferences),
      Macro,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$CatalogCacheTableCreateCompanionBuilder =
    CatalogCacheCompanion Function({
      required String key,
      Value<String?> etag,
      Value<String?> lastModified,
      required String payloadPath,
      required DateTime fetchedAt,
      required CacheStatus status,
      Value<int> rowid,
    });
typedef $$CatalogCacheTableUpdateCompanionBuilder =
    CatalogCacheCompanion Function({
      Value<String> key,
      Value<String?> etag,
      Value<String?> lastModified,
      Value<String> payloadPath,
      Value<DateTime> fetchedAt,
      Value<CacheStatus> status,
      Value<int> rowid,
    });

class $$CatalogCacheTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogCacheTable> {
  $$CatalogCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadPath => $composableBuilder(
    column: $table.payloadPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CacheStatus, CacheStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$CatalogCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogCacheTable> {
  $$CatalogCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadPath => $composableBuilder(
    column: $table.payloadPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogCacheTable> {
  $$CatalogCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadPath => $composableBuilder(
    column: $table.payloadPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CacheStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$CatalogCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogCacheTable,
          CatalogCacheEntry,
          $$CatalogCacheTableFilterComposer,
          $$CatalogCacheTableOrderingComposer,
          $$CatalogCacheTableAnnotationComposer,
          $$CatalogCacheTableCreateCompanionBuilder,
          $$CatalogCacheTableUpdateCompanionBuilder,
          (
            CatalogCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $CatalogCacheTable,
              CatalogCacheEntry
            >,
          ),
          CatalogCacheEntry,
          PrefetchHooks Function()
        > {
  $$CatalogCacheTableTableManager(_$AppDatabase db, $CatalogCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                Value<String> payloadPath = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<CacheStatus> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogCacheCompanion(
                key: key,
                etag: etag,
                lastModified: lastModified,
                payloadPath: payloadPath,
                fetchedAt: fetchedAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> etag = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                required String payloadPath,
                required DateTime fetchedAt,
                required CacheStatus status,
                Value<int> rowid = const Value.absent(),
              }) => CatalogCacheCompanion.insert(
                key: key,
                etag: etag,
                lastModified: lastModified,
                payloadPath: payloadPath,
                fetchedAt: fetchedAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogCacheTable,
      CatalogCacheEntry,
      $$CatalogCacheTableFilterComposer,
      $$CatalogCacheTableOrderingComposer,
      $$CatalogCacheTableAnnotationComposer,
      $$CatalogCacheTableCreateCompanionBuilder,
      $$CatalogCacheTableUpdateCompanionBuilder,
      (
        CatalogCacheEntry,
        BaseReferences<_$AppDatabase, $CatalogCacheTable, CatalogCacheEntry>,
      ),
      CatalogCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BuildsTableTableManager get builds =>
      $$BuildsTableTableManager(_db, _db.builds);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$InstalledAddonsTableTableManager get installedAddons =>
      $$InstalledAddonsTableTableManager(_db, _db.installedAddons);
  $$PythonPackagesTableTableManager get pythonPackages =>
      $$PythonPackagesTableTableManager(_db, _db.pythonPackages);
  $$BundlesTableTableManager get bundles =>
      $$BundlesTableTableManager(_db, _db.bundles);
  $$BundleItemsTableTableManager get bundleItems =>
      $$BundleItemsTableTableManager(_db, _db.bundleItems);
  $$MacrosTableTableManager get macros =>
      $$MacrosTableTableManager(_db, _db.macros);
  $$CatalogCacheTableTableManager get catalogCache =>
      $$CatalogCacheTableTableManager(_db, _db.catalogCache);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
