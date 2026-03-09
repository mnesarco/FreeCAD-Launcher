// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AppsTable extends Apps with TableInfo<$AppsTable, App> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _commandMeta = const VerificationMeta(
    'command',
  );
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
    'command',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _argsMeta = const VerificationMeta('args');
  @override
  late final GeneratedColumn<String> args = GeneratedColumn<String>(
    'args',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cwdMeta = const VerificationMeta('cwd');
  @override
  late final GeneratedColumn<String> cwd = GeneratedColumn<String>(
    'cwd',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, command, args, kind, cwd];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'apps';
  @override
  VerificationContext validateIntegrity(
    Insertable<App> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('command')) {
      context.handle(
        _commandMeta,
        command.isAcceptableOrUnknown(data['command']!, _commandMeta),
      );
    } else if (isInserting) {
      context.missing(_commandMeta);
    }
    if (data.containsKey('args')) {
      context.handle(
        _argsMeta,
        args.isAcceptableOrUnknown(data['args']!, _argsMeta),
      );
    } else if (isInserting) {
      context.missing(_argsMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('cwd')) {
      context.handle(
        _cwdMeta,
        cwd.isAcceptableOrUnknown(data['cwd']!, _cwdMeta),
      );
    } else if (isInserting) {
      context.missing(_cwdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  App map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return App(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      command: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command'],
      )!,
      args: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}args'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      cwd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cwd'],
      )!,
    );
  }

  @override
  $AppsTable createAlias(String alias) {
    return $AppsTable(attachedDatabase, alias);
  }
}

class App extends DataClass implements Insertable<App> {
  final int id;
  final String name;
  final String command;
  final String args;
  final String kind;
  final String cwd;
  const App({
    required this.id,
    required this.name,
    required this.command,
    required this.args,
    required this.kind,
    required this.cwd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['command'] = Variable<String>(command);
    map['args'] = Variable<String>(args);
    map['kind'] = Variable<String>(kind);
    map['cwd'] = Variable<String>(cwd);
    return map;
  }

  AppsCompanion toCompanion(bool nullToAbsent) {
    return AppsCompanion(
      id: Value(id),
      name: Value(name),
      command: Value(command),
      args: Value(args),
      kind: Value(kind),
      cwd: Value(cwd),
    );
  }

  factory App.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return App(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      command: serializer.fromJson<String>(json['command']),
      args: serializer.fromJson<String>(json['args']),
      kind: serializer.fromJson<String>(json['kind']),
      cwd: serializer.fromJson<String>(json['cwd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'command': serializer.toJson<String>(command),
      'args': serializer.toJson<String>(args),
      'kind': serializer.toJson<String>(kind),
      'cwd': serializer.toJson<String>(cwd),
    };
  }

  App copyWith({
    int? id,
    String? name,
    String? command,
    String? args,
    String? kind,
    String? cwd,
  }) => App(
    id: id ?? this.id,
    name: name ?? this.name,
    command: command ?? this.command,
    args: args ?? this.args,
    kind: kind ?? this.kind,
    cwd: cwd ?? this.cwd,
  );
  App copyWithCompanion(AppsCompanion data) {
    return App(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      command: data.command.present ? data.command.value : this.command,
      args: data.args.present ? data.args.value : this.args,
      kind: data.kind.present ? data.kind.value : this.kind,
      cwd: data.cwd.present ? data.cwd.value : this.cwd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('App(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('command: $command, ')
          ..write('args: $args, ')
          ..write('kind: $kind, ')
          ..write('cwd: $cwd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, command, args, kind, cwd);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is App &&
          other.id == this.id &&
          other.name == this.name &&
          other.command == this.command &&
          other.args == this.args &&
          other.kind == this.kind &&
          other.cwd == this.cwd);
}

class AppsCompanion extends UpdateCompanion<App> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> command;
  final Value<String> args;
  final Value<String> kind;
  final Value<String> cwd;
  const AppsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.command = const Value.absent(),
    this.args = const Value.absent(),
    this.kind = const Value.absent(),
    this.cwd = const Value.absent(),
  });
  AppsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String command,
    required String args,
    required String kind,
    required String cwd,
  }) : name = Value(name),
       command = Value(command),
       args = Value(args),
       kind = Value(kind),
       cwd = Value(cwd);
  static Insertable<App> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? command,
    Expression<String>? args,
    Expression<String>? kind,
    Expression<String>? cwd,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (command != null) 'command': command,
      if (args != null) 'args': args,
      if (kind != null) 'kind': kind,
      if (cwd != null) 'cwd': cwd,
    });
  }

  AppsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? command,
    Value<String>? args,
    Value<String>? kind,
    Value<String>? cwd,
  }) {
    return AppsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      args: args ?? this.args,
      kind: kind ?? this.kind,
      cwd: cwd ?? this.cwd,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (args.present) {
      map['args'] = Variable<String>(args.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (cwd.present) {
      map['cwd'] = Variable<String>(cwd.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('command: $command, ')
          ..write('args: $args, ')
          ..write('kind: $kind, ')
          ..write('cwd: $cwd')
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
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _argsMeta = const VerificationMeta('args');
  @override
  late final GeneratedColumn<String> args = GeneratedColumn<String>(
    'args',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cwdMeta = const VerificationMeta('cwd');
  @override
  late final GeneratedColumn<String> cwd = GeneratedColumn<String>(
    'cwd',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, args, cwd];
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
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('args')) {
      context.handle(
        _argsMeta,
        args.isAcceptableOrUnknown(data['args']!, _argsMeta),
      );
    } else if (isInserting) {
      context.missing(_argsMeta);
    }
    if (data.containsKey('cwd')) {
      context.handle(
        _cwdMeta,
        cwd.isAcceptableOrUnknown(data['cwd']!, _cwdMeta),
      );
    } else if (isInserting) {
      context.missing(_cwdMeta);
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
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      args: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}args'],
      )!,
      cwd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cwd'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String name;
  final String args;
  final String cwd;
  const Profile({
    required this.id,
    required this.name,
    required this.args,
    required this.cwd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['args'] = Variable<String>(args);
    map['cwd'] = Variable<String>(cwd);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      args: Value(args),
      cwd: Value(cwd),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      args: serializer.fromJson<String>(json['args']),
      cwd: serializer.fromJson<String>(json['cwd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'args': serializer.toJson<String>(args),
      'cwd': serializer.toJson<String>(cwd),
    };
  }

  Profile copyWith({int? id, String? name, String? args, String? cwd}) =>
      Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        args: args ?? this.args,
        cwd: cwd ?? this.cwd,
      );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      args: data.args.present ? data.args.value : this.args,
      cwd: data.cwd.present ? data.cwd.value : this.cwd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('args: $args, ')
          ..write('cwd: $cwd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, args, cwd);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.args == this.args &&
          other.cwd == this.cwd);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> args;
  final Value<String> cwd;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.args = const Value.absent(),
    this.cwd = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String args,
    required String cwd,
  }) : name = Value(name),
       args = Value(args),
       cwd = Value(cwd);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? args,
    Expression<String>? cwd,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (args != null) 'args': args,
      if (cwd != null) 'cwd': cwd,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? args,
    Value<String>? cwd,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      args: args ?? this.args,
      cwd: cwd ?? this.cwd,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (args.present) {
      map['args'] = Variable<String>(args.value);
    }
    if (cwd.present) {
      map['cwd'] = Variable<String>(cwd.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('args: $args, ')
          ..write('cwd: $cwd')
          ..write(')'))
        .toString();
  }
}

class $DownloadedAddonsTable extends DownloadedAddons
    with TableInfo<$DownloadedAddonsTable, DownloadedAddon> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedAddonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repoUrlMeta = const VerificationMeta(
    'repoUrl',
  );
  @override
  late final GeneratedColumn<String> repoUrl = GeneratedColumn<String>(
    'repo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zipUrlMeta = const VerificationMeta('zipUrl');
  @override
  late final GeneratedColumn<String> zipUrl = GeneratedColumn<String>(
    'zip_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
    'branch',
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
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedNameMeta = const VerificationMeta(
    'downloadedName',
  );
  @override
  late final GeneratedColumn<String> downloadedName = GeneratedColumn<String>(
    'downloaded_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    name,
    repoUrl,
    zipUrl,
    branch,
    version,
    updatedAt,
    downloadedAt,
    downloadedName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_addons';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedAddon> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('repo_url')) {
      context.handle(
        _repoUrlMeta,
        repoUrl.isAcceptableOrUnknown(data['repo_url']!, _repoUrlMeta),
      );
    }
    if (data.containsKey('zip_url')) {
      context.handle(
        _zipUrlMeta,
        zipUrl.isAcceptableOrUnknown(data['zip_url']!, _zipUrlMeta),
      );
    }
    if (data.containsKey('branch')) {
      context.handle(
        _branchMeta,
        branch.isAcceptableOrUnknown(data['branch']!, _branchMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('downloaded_name')) {
      context.handle(
        _downloadedNameMeta,
        downloadedName.isAcceptableOrUnknown(
          data['downloaded_name']!,
          _downloadedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    repoUrl,
    zipUrl,
    branch,
    version,
    updatedAt,
  };
  @override
  DownloadedAddon map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedAddon(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      repoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo_url'],
      ),
      zipUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zip_url'],
      ),
      branch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
      downloadedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}downloaded_name'],
      )!,
    );
  }

  @override
  $DownloadedAddonsTable createAlias(String alias) {
    return $DownloadedAddonsTable(attachedDatabase, alias);
  }
}

class DownloadedAddon extends DataClass implements Insertable<DownloadedAddon> {
  final String name;
  final String? repoUrl;
  final String? zipUrl;
  final String? branch;
  final String? version;
  final DateTime updatedAt;
  final DateTime downloadedAt;
  final String downloadedName;
  const DownloadedAddon({
    required this.name,
    this.repoUrl,
    this.zipUrl,
    this.branch,
    this.version,
    required this.updatedAt,
    required this.downloadedAt,
    required this.downloadedName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || repoUrl != null) {
      map['repo_url'] = Variable<String>(repoUrl);
    }
    if (!nullToAbsent || zipUrl != null) {
      map['zip_url'] = Variable<String>(zipUrl);
    }
    if (!nullToAbsent || branch != null) {
      map['branch'] = Variable<String>(branch);
    }
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    map['downloaded_name'] = Variable<String>(downloadedName);
    return map;
  }

  DownloadedAddonsCompanion toCompanion(bool nullToAbsent) {
    return DownloadedAddonsCompanion(
      name: Value(name),
      repoUrl: repoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(repoUrl),
      zipUrl: zipUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(zipUrl),
      branch: branch == null && nullToAbsent
          ? const Value.absent()
          : Value(branch),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      updatedAt: Value(updatedAt),
      downloadedAt: Value(downloadedAt),
      downloadedName: Value(downloadedName),
    );
  }

  factory DownloadedAddon.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedAddon(
      name: serializer.fromJson<String>(json['name']),
      repoUrl: serializer.fromJson<String?>(json['repoUrl']),
      zipUrl: serializer.fromJson<String?>(json['zipUrl']),
      branch: serializer.fromJson<String?>(json['branch']),
      version: serializer.fromJson<String?>(json['version']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
      downloadedName: serializer.fromJson<String>(json['downloadedName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'repoUrl': serializer.toJson<String?>(repoUrl),
      'zipUrl': serializer.toJson<String?>(zipUrl),
      'branch': serializer.toJson<String?>(branch),
      'version': serializer.toJson<String?>(version),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
      'downloadedName': serializer.toJson<String>(downloadedName),
    };
  }

  DownloadedAddon copyWith({
    String? name,
    Value<String?> repoUrl = const Value.absent(),
    Value<String?> zipUrl = const Value.absent(),
    Value<String?> branch = const Value.absent(),
    Value<String?> version = const Value.absent(),
    DateTime? updatedAt,
    DateTime? downloadedAt,
    String? downloadedName,
  }) => DownloadedAddon(
    name: name ?? this.name,
    repoUrl: repoUrl.present ? repoUrl.value : this.repoUrl,
    zipUrl: zipUrl.present ? zipUrl.value : this.zipUrl,
    branch: branch.present ? branch.value : this.branch,
    version: version.present ? version.value : this.version,
    updatedAt: updatedAt ?? this.updatedAt,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    downloadedName: downloadedName ?? this.downloadedName,
  );
  DownloadedAddon copyWithCompanion(DownloadedAddonsCompanion data) {
    return DownloadedAddon(
      name: data.name.present ? data.name.value : this.name,
      repoUrl: data.repoUrl.present ? data.repoUrl.value : this.repoUrl,
      zipUrl: data.zipUrl.present ? data.zipUrl.value : this.zipUrl,
      branch: data.branch.present ? data.branch.value : this.branch,
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      downloadedName: data.downloadedName.present
          ? data.downloadedName.value
          : this.downloadedName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedAddon(')
          ..write('name: $name, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('zipUrl: $zipUrl, ')
          ..write('branch: $branch, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('downloadedName: $downloadedName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    name,
    repoUrl,
    zipUrl,
    branch,
    version,
    updatedAt,
    downloadedAt,
    downloadedName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedAddon &&
          other.name == this.name &&
          other.repoUrl == this.repoUrl &&
          other.zipUrl == this.zipUrl &&
          other.branch == this.branch &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.downloadedAt == this.downloadedAt &&
          other.downloadedName == this.downloadedName);
}

class DownloadedAddonsCompanion extends UpdateCompanion<DownloadedAddon> {
  final Value<String> name;
  final Value<String?> repoUrl;
  final Value<String?> zipUrl;
  final Value<String?> branch;
  final Value<String?> version;
  final Value<DateTime> updatedAt;
  final Value<DateTime> downloadedAt;
  final Value<String> downloadedName;
  final Value<int> rowid;
  const DownloadedAddonsCompanion({
    this.name = const Value.absent(),
    this.repoUrl = const Value.absent(),
    this.zipUrl = const Value.absent(),
    this.branch = const Value.absent(),
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.downloadedName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadedAddonsCompanion.insert({
    required String name,
    this.repoUrl = const Value.absent(),
    this.zipUrl = const Value.absent(),
    this.branch = const Value.absent(),
    this.version = const Value.absent(),
    required DateTime updatedAt,
    required DateTime downloadedAt,
    required String downloadedName,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       updatedAt = Value(updatedAt),
       downloadedAt = Value(downloadedAt),
       downloadedName = Value(downloadedName);
  static Insertable<DownloadedAddon> custom({
    Expression<String>? name,
    Expression<String>? repoUrl,
    Expression<String>? zipUrl,
    Expression<String>? branch,
    Expression<String>? version,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? downloadedAt,
    Expression<String>? downloadedName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (repoUrl != null) 'repo_url': repoUrl,
      if (zipUrl != null) 'zip_url': zipUrl,
      if (branch != null) 'branch': branch,
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (downloadedName != null) 'downloaded_name': downloadedName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadedAddonsCompanion copyWith({
    Value<String>? name,
    Value<String?>? repoUrl,
    Value<String?>? zipUrl,
    Value<String?>? branch,
    Value<String?>? version,
    Value<DateTime>? updatedAt,
    Value<DateTime>? downloadedAt,
    Value<String>? downloadedName,
    Value<int>? rowid,
  }) {
    return DownloadedAddonsCompanion(
      name: name ?? this.name,
      repoUrl: repoUrl ?? this.repoUrl,
      zipUrl: zipUrl ?? this.zipUrl,
      branch: branch ?? this.branch,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      downloadedName: downloadedName ?? this.downloadedName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (repoUrl.present) {
      map['repo_url'] = Variable<String>(repoUrl.value);
    }
    if (zipUrl.present) {
      map['zip_url'] = Variable<String>(zipUrl.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (downloadedName.present) {
      map['downloaded_name'] = Variable<String>(downloadedName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedAddonsCompanion(')
          ..write('name: $name, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('zipUrl: $zipUrl, ')
          ..write('branch: $branch, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('downloadedName: $downloadedName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final $AppsTable apps = $AppsTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $DownloadedAddonsTable downloadedAddons = $DownloadedAddonsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    apps,
    profiles,
    downloadedAddons,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$AppsTableCreateCompanionBuilder =
    AppsCompanion Function({
      Value<int> id,
      required String name,
      required String command,
      required String args,
      required String kind,
      required String cwd,
    });
typedef $$AppsTableUpdateCompanionBuilder =
    AppsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> command,
      Value<String> args,
      Value<String> kind,
      Value<String> cwd,
    });

class $$AppsTableFilterComposer extends Composer<_$Database, $AppsTable> {
  $$AppsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get args => $composableBuilder(
    column: $table.args,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cwd => $composableBuilder(
    column: $table.cwd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppsTableOrderingComposer extends Composer<_$Database, $AppsTable> {
  $$AppsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get args => $composableBuilder(
    column: $table.args,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cwd => $composableBuilder(
    column: $table.cwd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppsTableAnnotationComposer extends Composer<_$Database, $AppsTable> {
  $$AppsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get args =>
      $composableBuilder(column: $table.args, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get cwd =>
      $composableBuilder(column: $table.cwd, builder: (column) => column);
}

class $$AppsTableTableManager
    extends
        RootTableManager<
          _$Database,
          $AppsTable,
          App,
          $$AppsTableFilterComposer,
          $$AppsTableOrderingComposer,
          $$AppsTableAnnotationComposer,
          $$AppsTableCreateCompanionBuilder,
          $$AppsTableUpdateCompanionBuilder,
          (App, BaseReferences<_$Database, $AppsTable, App>),
          App,
          PrefetchHooks Function()
        > {
  $$AppsTableTableManager(_$Database db, $AppsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> command = const Value.absent(),
                Value<String> args = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> cwd = const Value.absent(),
              }) => AppsCompanion(
                id: id,
                name: name,
                command: command,
                args: args,
                kind: kind,
                cwd: cwd,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String command,
                required String args,
                required String kind,
                required String cwd,
              }) => AppsCompanion.insert(
                id: id,
                name: name,
                command: command,
                args: args,
                kind: kind,
                cwd: cwd,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppsTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $AppsTable,
      App,
      $$AppsTableFilterComposer,
      $$AppsTableOrderingComposer,
      $$AppsTableAnnotationComposer,
      $$AppsTableCreateCompanionBuilder,
      $$AppsTableUpdateCompanionBuilder,
      (App, BaseReferences<_$Database, $AppsTable, App>),
      App,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      required String name,
      required String args,
      required String cwd,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> args,
      Value<String> cwd,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$Database, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get args => $composableBuilder(
    column: $table.args,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cwd => $composableBuilder(
    column: $table.cwd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$Database, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get args => $composableBuilder(
    column: $table.args,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cwd => $composableBuilder(
    column: $table.cwd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$Database, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get args =>
      $composableBuilder(column: $table.args, builder: (column) => column);

  GeneratedColumn<String> get cwd =>
      $composableBuilder(column: $table.cwd, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$Database,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$Database, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$Database db, $ProfilesTable table)
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
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> args = const Value.absent(),
                Value<String> cwd = const Value.absent(),
              }) => ProfilesCompanion(id: id, name: name, args: args, cwd: cwd),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String args,
                required String cwd,
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                args: args,
                cwd: cwd,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$Database, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$DownloadedAddonsTableCreateCompanionBuilder =
    DownloadedAddonsCompanion Function({
      required String name,
      Value<String?> repoUrl,
      Value<String?> zipUrl,
      Value<String?> branch,
      Value<String?> version,
      required DateTime updatedAt,
      required DateTime downloadedAt,
      required String downloadedName,
      Value<int> rowid,
    });
typedef $$DownloadedAddonsTableUpdateCompanionBuilder =
    DownloadedAddonsCompanion Function({
      Value<String> name,
      Value<String?> repoUrl,
      Value<String?> zipUrl,
      Value<String?> branch,
      Value<String?> version,
      Value<DateTime> updatedAt,
      Value<DateTime> downloadedAt,
      Value<String> downloadedName,
      Value<int> rowid,
    });

class $$DownloadedAddonsTableFilterComposer
    extends Composer<_$Database, $DownloadedAddonsTable> {
  $$DownloadedAddonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zipUrl => $composableBuilder(
    column: $table.zipUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadedName => $composableBuilder(
    column: $table.downloadedName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedAddonsTableOrderingComposer
    extends Composer<_$Database, $DownloadedAddonsTable> {
  $$DownloadedAddonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zipUrl => $composableBuilder(
    column: $table.zipUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadedName => $composableBuilder(
    column: $table.downloadedName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedAddonsTableAnnotationComposer
    extends Composer<_$Database, $DownloadedAddonsTable> {
  $$DownloadedAddonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get repoUrl =>
      $composableBuilder(column: $table.repoUrl, builder: (column) => column);

  GeneratedColumn<String> get zipUrl =>
      $composableBuilder(column: $table.zipUrl, builder: (column) => column);

  GeneratedColumn<String> get branch =>
      $composableBuilder(column: $table.branch, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get downloadedName => $composableBuilder(
    column: $table.downloadedName,
    builder: (column) => column,
  );
}

class $$DownloadedAddonsTableTableManager
    extends
        RootTableManager<
          _$Database,
          $DownloadedAddonsTable,
          DownloadedAddon,
          $$DownloadedAddonsTableFilterComposer,
          $$DownloadedAddonsTableOrderingComposer,
          $$DownloadedAddonsTableAnnotationComposer,
          $$DownloadedAddonsTableCreateCompanionBuilder,
          $$DownloadedAddonsTableUpdateCompanionBuilder,
          (
            DownloadedAddon,
            BaseReferences<_$Database, $DownloadedAddonsTable, DownloadedAddon>,
          ),
          DownloadedAddon,
          PrefetchHooks Function()
        > {
  $$DownloadedAddonsTableTableManager(
    _$Database db,
    $DownloadedAddonsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedAddonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedAddonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadedAddonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String?> repoUrl = const Value.absent(),
                Value<String?> zipUrl = const Value.absent(),
                Value<String?> branch = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<String> downloadedName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedAddonsCompanion(
                name: name,
                repoUrl: repoUrl,
                zipUrl: zipUrl,
                branch: branch,
                version: version,
                updatedAt: updatedAt,
                downloadedAt: downloadedAt,
                downloadedName: downloadedName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                Value<String?> repoUrl = const Value.absent(),
                Value<String?> zipUrl = const Value.absent(),
                Value<String?> branch = const Value.absent(),
                Value<String?> version = const Value.absent(),
                required DateTime updatedAt,
                required DateTime downloadedAt,
                required String downloadedName,
                Value<int> rowid = const Value.absent(),
              }) => DownloadedAddonsCompanion.insert(
                name: name,
                repoUrl: repoUrl,
                zipUrl: zipUrl,
                branch: branch,
                version: version,
                updatedAt: updatedAt,
                downloadedAt: downloadedAt,
                downloadedName: downloadedName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedAddonsTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $DownloadedAddonsTable,
      DownloadedAddon,
      $$DownloadedAddonsTableFilterComposer,
      $$DownloadedAddonsTableOrderingComposer,
      $$DownloadedAddonsTableAnnotationComposer,
      $$DownloadedAddonsTableCreateCompanionBuilder,
      $$DownloadedAddonsTableUpdateCompanionBuilder,
      (
        DownloadedAddon,
        BaseReferences<_$Database, $DownloadedAddonsTable, DownloadedAddon>,
      ),
      DownloadedAddon,
      PrefetchHooks Function()
    >;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $$AppsTableTableManager get apps => $$AppsTableTableManager(_db, _db.apps);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$DownloadedAddonsTableTableManager get downloadedAddons =>
      $$DownloadedAddonsTableTableManager(_db, _db.downloadedAddons);
}
