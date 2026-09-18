import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/builds/build_types.dart';
import 'package:freecad_launcher/platform/diagnostics.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/platform/process.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_process.dart';

void main() {
  late Directory tempDirectory;
  late AppPaths paths;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fcl_diagnostics_test');
    paths = AppPaths(dataRoot: tempDirectory.path);
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  DiagnosticsService buildService({
    required BuildPlatform platform,
    FakeProcessLauncher? launcher,
    Map<String, String>? environment,
    bool? fuseDevice,
    int minimumFreeBytes = 1,
  }) {
    return DiagnosticsService(
      paths: paths,
      platform: platform,
      processRunner: ProcessRunner(launcher: launcher ?? FakeProcessLauncher()),
      environment: environment,
      fuseDeviceExists: fuseDevice == null ? null : () => fuseDevice,
      minimumFreeBytes: minimumFreeBytes,
    );
  }

  test('data directory check passes for a writable directory', () async {
    final result = await buildService(platform: BuildPlatform.linux).checkDataDirectory();

    expect(result.id, DiagnosticIds.dataDirectory);
    expect(result.status, DiagnosticStatus.ok);
  });

  test('data directory check fails when the root is not writable', () async {
    final file = File(p.join(tempDirectory.path, 'not-a-directory'))
      ..writeAsStringSync('x');
    final diagnostics = DiagnosticsService(
      paths: AppPaths(dataRoot: p.join(file.path, 'child')),
      platform: BuildPlatform.linux,
    );

    final result = await diagnostics.checkDataDirectory();

    expect(result.status, DiagnosticStatus.error);
    expect(result.detail, isNotNull);
  });

  test('fuse check is not applicable outside linux', () async {
    expect(
      (await buildService(platform: BuildPlatform.windows).checkFuse()).status,
      DiagnosticStatus.notApplicable,
    );
    expect(
      (await buildService(platform: BuildPlatform.macos).checkFuse()).status,
      DiagnosticStatus.notApplicable,
    );
  });

  test('fuse check reports ok when device and helper exist', () async {
    final binDirectory = Directory(p.join(tempDirectory.path, 'bin'))..createSync();
    File(p.join(binDirectory.path, 'fusermount3')).writeAsStringSync('');

    final result = await buildService(
      platform: BuildPlatform.linux,
      environment: {'PATH': binDirectory.path},
      fuseDevice: true,
    ).checkFuse();

    expect(result.status, DiagnosticStatus.ok);
    expect(result.detail, contains('fusermount3'));
  });

  test('fuse check warns when device or helper is missing', () async {
    final result = await buildService(
      platform: BuildPlatform.linux,
      environment: {'PATH': tempDirectory.path},
      fuseDevice: false,
    ).checkFuse();

    expect(result.status, DiagnosticStatus.warning);
    expect(result.detail, contains('/dev/fuse'));
  });

  test('fuseAvailable mirrors the fuse check', () async {
    final binDirectory = Directory(p.join(tempDirectory.path, 'bin'))..createSync();
    File(p.join(binDirectory.path, 'fusermount3')).writeAsStringSync('');

    expect(
      await buildService(
        platform: BuildPlatform.linux,
        environment: {'PATH': binDirectory.path},
        fuseDevice: true,
      ).fuseAvailable(),
      isTrue,
    );
    expect(
      await buildService(
        platform: BuildPlatform.linux,
        environment: {'PATH': tempDirectory.path},
        fuseDevice: false,
      ).fuseAvailable(),
      isFalse,
    );
  });

  test('gatekeeper check is not applicable outside macos', () async {
    final result = await buildService(platform: BuildPlatform.linux).checkGatekeeper();

    expect(result.status, DiagnosticStatus.notApplicable);
  });

  test('gatekeeper check reports ok when assessments are enabled', () async {
    final launcher = FakeProcessLauncher();
    final future = buildService(platform: BuildPlatform.macos, launcher: launcher)
        .checkGatekeeper();
    await pumpEventQueue();

    launcher.handles.single
      ..emitStdout('assessments enabled\n')
      ..exit(0);

    final result = await future;

    expect(result.status, DiagnosticStatus.ok);
    expect(launcher.specs.single.executable, 'spctl');
    expect(launcher.specs.single.arguments, ['--status']);
  });

  test('gatekeeper check warns when assessments are disabled', () async {
    final launcher = FakeProcessLauncher();
    final future = buildService(platform: BuildPlatform.macos, launcher: launcher)
        .checkGatekeeper();
    await pumpEventQueue();

    launcher.handles.single
      ..emitStdout('assessments disabled\n')
      ..exit(0);

    final result = await future;

    expect(result.status, DiagnosticStatus.warning);
    expect(result.detail, contains('disabled'));
  });

  test('gatekeeper check reports an error when spctl fails', () async {
    final launcher = FakeProcessLauncher();
    final future = buildService(platform: BuildPlatform.macos, launcher: launcher)
        .checkGatekeeper();
    await pumpEventQueue();

    launcher.handles.single
      ..emitStderr('spctl: command failed\n')
      ..exit(1);

    final result = await future;

    expect(result.status, DiagnosticStatus.error);
  });

  test('disk check parses df output and compares with the minimum', () async {
    const dfOutput =
        'Filesystem 1024-blocks Used Available Capacity Mounted on\n'
        '/dev/sda1 100000000 1000 99000 10% /\n';

    final launcher = FakeProcessLauncher();
    final future = buildService(
      platform: BuildPlatform.linux,
      launcher: launcher,
      minimumFreeBytes: 1,
    ).checkDiskSpace();
    await pumpEventQueue();

    launcher.handles.single
      ..emitStdout(dfOutput)
      ..exit(0);

    final result = await future;

    expect(result.status, DiagnosticStatus.ok);
    expect(launcher.specs.single.arguments, ['-k', '-P', paths.dataRoot]);
  });

  test('disk check warns when free space is below the minimum', () async {
    const dfOutput =
        'Filesystem 1024-blocks Used Available Capacity Mounted on\n'
        '/dev/sda1 100000000 1000 99000 10% /\n';

    final launcher = FakeProcessLauncher();
    final future = buildService(
      platform: BuildPlatform.linux,
      launcher: launcher,
      minimumFreeBytes: 10 << 30,
    ).checkDiskSpace();
    await pumpEventQueue();

    launcher.handles.single
      ..emitStdout(dfOutput)
      ..exit(0);

    final result = await future;

    expect(result.status, DiagnosticStatus.warning);
  });

  test('disk check is not applicable on windows', () async {
    final result = await buildService(platform: BuildPlatform.windows).checkDiskSpace();

    expect(result.status, DiagnosticStatus.notApplicable);
  });

  test('runAll returns one result per check', () async {
    final launcher = FakeProcessLauncher();
    final future = buildService(
      platform: BuildPlatform.linux,
      launcher: launcher,
      environment: {'PATH': ''},
      fuseDevice: false,
    ).runAll();

    for (var attempt = 0; attempt < 250 && launcher.handles.isEmpty; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    launcher.handles.single
      ..emitStdout(
        'Filesystem 1024-blocks Used Available Capacity Mounted on\n'
        '/dev/sda1 100000000 1000 99000 10% /\n',
      )
      ..exit(0);

    final report = await future;

    expect(report.results, hasLength(4));
    expect(
      report.results.map((result) => result.id),
      containsAll([
        DiagnosticIds.dataDirectory,
        DiagnosticIds.fuse,
        DiagnosticIds.gatekeeper,
        DiagnosticIds.diskSpace,
      ]),
    );
  });
}
