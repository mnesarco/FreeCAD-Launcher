import 'dart:io';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/platform/debug_bundle.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/platform/paths.dart';

class DebugBundleController {
  DebugBundleController({
    required DebugBundleService service,
    required AppDatabase database,
    required DiagnosticsService diagnostics,
    required AppPaths paths,
    DateTime Function()? clock,
  }) : _service = service,
       _database = database,
       _diagnostics = diagnostics,
       _paths = paths,
       _clock = clock ?? DateTime.now;

  final DebugBundleService _service;
  final AppDatabase _database;
  final DiagnosticsService _diagnostics;
  final AppPaths _paths;
  final DateTime Function() _clock;

  final exporting = signal(false);
  final lastExportedPath = signal<String?>(null);

  String suggestedFileName() =>
      DebugBundleService.suggestedFileName(_clock());

  Future<Result<String>> export(String outputPath) async {
    exporting.value = true;
    try {
      final report = await _diagnostics.runAll();
      final result = await _service.create(
        outputPath: outputPath,
        systemInfo: await _systemInfo(),
        diagnostics: _formatDiagnostics(report),
      );
      lastExportedPath.value = result.path;
      return Ok(result.path);
    } on Object catch (error, stackTrace) {
      return Err(AppError.from(error, stackTrace: stackTrace));
    } finally {
      exporting.value = false;
    }
  }

  Future<String> _systemInfo() async {
    final builds = await _database.buildsDao.getAll();
    final profiles = await _database.profilesDao.getAll();
    final addons = await _database.installedAddonsDao.getAll();
    final packages = await _database.pythonPackagesDao.watchAll().first;
    final buildsById = {for (final build in builds) build.id: build};

    final buffer = StringBuffer()
      ..writeln('$appName $appVersion')
      ..writeln('Dart: ${Platform.version}')
      ..writeln('OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
      ..writeln('Data directory: ${_paths.dataRoot}')
      ..writeln()
      ..writeln('Builds (${builds.length}):');
    for (final build in builds) {
      final name = build.displayLabel == build.version
          ? build.displayLabel
          : '${build.displayLabel} (${build.version})';
      buffer.writeln(
        '- $name  ${build.channel.name}  ${build.kind.name}  '
        '${build.status.name}  python=${build.pythonVersion ?? 'unknown'}',
      );
    }

    buffer
      ..writeln()
      ..writeln('Profiles (${profiles.length}):');
    for (final profile in profiles) {
      final build = buildsById[profile.buildId];
      final addonCount = addons
          .where((addon) => addon.profileId == profile.id)
          .length;
      final packageCount = packages
          .where((package) => package.profileId == profile.id)
          .length;
      buffer.writeln(
        '- ${profile.name}  build=${build?.displayLabel ?? 'missing'} '
        '${build?.channel.name ?? ''}  python=${profile.pythonVersion}  '
        'addons=$addonCount  packages=$packageCount',
      );
    }
    return buffer.toString();
  }

  String _formatDiagnostics(DiagnosticsReport report) {
    final buffer = StringBuffer()
      ..writeln('$appName $appVersion diagnostics')
      ..writeln();
    for (final result in report.results) {
      buffer.writeln(
        '${result.id}: ${result.status.name}'
        '${result.detail == null ? '' : ' — ${result.detail}'}',
      );
    }
    return buffer.toString();
  }
}
