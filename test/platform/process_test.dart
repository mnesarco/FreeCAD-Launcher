import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/platform/process.dart';

class FakeProcessHandle implements ProcessHandle {
  final StreamController<List<int>> _stdoutController = StreamController<List<int>>();
  final StreamController<List<int>> _stderrController = StreamController<List<int>>();
  final Completer<int> _exitCompleter = Completer<int>();

  bool killed = false;
  ProcessSignal? killSignal;

  void emitStdout(String text) => _stdoutController.add(utf8.encode(text));

  void emitStderr(String text) => _stderrController.add(utf8.encode(text));

  void exit(int code) {
    if (!_exitCompleter.isCompleted) {
      _exitCompleter.complete(code);
    }
    _closeStreams();
  }

  void _closeStreams() {
    if (!_stdoutController.isClosed) {
      _stdoutController.close();
    }
    if (!_stderrController.isClosed) {
      _stderrController.close();
    }
  }

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  Future<int> get exitCode => _exitCompleter.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    killSignal = signal;
    _closeStreams();
    if (!_exitCompleter.isCompleted) {
      _exitCompleter.complete(-15);
    }
    return true;
  }
}

class FakeProcessLauncher implements ProcessLauncher {
  final List<ProcessSpec> specs = [];
  final List<FakeProcessHandle> handles = [];
  Object? error;

  @override
  Future<ProcessHandle> start(ProcessSpec spec) async {
    if (error != null) {
      throw error!;
    }
    specs.add(spec);
    final handle = FakeProcessHandle();
    handles.add(handle);
    return handle;
  }
}

void main() {
  late FakeProcessLauncher fake;
  late ProcessRunner runner;

  setUp(() {
    fake = FakeProcessLauncher();
    runner = ProcessRunner(launcher: fake);
  });

  test('collects stdout, stderr and the exit code', () async {
    final future = runner.run(
      const ProcessSpec(executable: 'python', arguments: ['-c', 'print(1)']),
    );
    await pumpEventQueue();

    final handle = fake.handles.single;
    handle.emitStdout('hello\nworld\n');
    handle.emitStderr('warning\n');
    handle.exit(0);

    final result = await future;

    expect(result.exitCode, 0);
    expect(result.isSuccess, isTrue);
    expect(result.stdout, 'hello\nworld\n');
    expect(result.stderr, 'warning\n');
  });

  test('streams decoded lines to callbacks', () async {
    final stdoutLines = <String>[];
    final stderrLines = <String>[];

    final future = runner.run(
      const ProcessSpec(executable: 'pip', arguments: ['install', 'numpy']),
      onStdout: stdoutLines.add,
      onStderr: stderrLines.add,
    );
    await pumpEventQueue();

    final handle = fake.handles.single;
    handle.emitStdout('a\nb\n');
    handle.emitStderr('e\n');
    handle.exit(0);
    await future;

    expect(stdoutLines, ['a', 'b']);
    expect(stderrLines, ['e']);
  });

  test('returns non-zero exit codes without throwing', () async {
    final future = runner.run(const ProcessSpec(executable: 'python'));
    await pumpEventQueue();

    fake.handles.single.exit(2);

    final result = await future;
    expect(result.exitCode, 2);
    expect(result.isSuccess, isFalse);
  });

  test('kills the process and throws on timeout', () async {
    final future = runner.run(
      const ProcessSpec(executable: 'pip'),
      timeout: const Duration(milliseconds: 20),
    );
    await pumpEventQueue();

    await expectLater(future, throwsA(isA<ProcessTimeoutException>()));
    expect(fake.handles.single.killed, isTrue);
  });

  test('propagates launcher failures', () async {
    fake.error = const ProcessException('missing', []);

    await expectLater(
      runner.run(const ProcessSpec(executable: 'nope')),
      throwsA(isA<ProcessException>()),
    );
  });

  test('passes arguments verbatim without a shell', () async {
    const tricky = r'$(whoami); echo "pwned" && rm -rf /';
    final future = runner.run(const ProcessSpec(executable: 'echo', arguments: [tricky]));
    await pumpEventQueue();

    fake.handles.single.exit(0);
    await future;

    expect(fake.specs.single.executable, 'echo');
    expect(fake.specs.single.arguments, [tricky]);
    expect(fake.specs.single.includeParentEnvironment, isFalse);
  });

  test('passes the environment map through to the launcher', () async {
    const spec = ProcessSpec(
      executable: 'python',
      environment: {'FREECAD_USER_HOME': '/data/profiles/p1'},
    );
    final future = runner.run(spec);
    await pumpEventQueue();

    fake.handles.single.exit(0);
    await future;

    expect(fake.specs.single.environment, {'FREECAD_USER_HOME': '/data/profiles/p1'});
  });

  test('executes a real process with special characters intact', () async {
    if (Platform.isWindows) {
      return;
    }
    const tricky = r'$(whoami); echo "pwned"';
    final result = await ProcessRunner().run(
      const ProcessSpec(executable: '/bin/echo', arguments: [tricky]),
    );

    expect(result.exitCode, 0);
    expect(result.stdout.trim(), tricky);
  });
}
