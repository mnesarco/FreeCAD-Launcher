import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ProcessSpec {
  const ProcessSpec({
    required this.executable,
    this.arguments = const [],
    this.environment = const {},
    this.workingDirectory,
    this.includeParentEnvironment = false,
  });

  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
  final String? workingDirectory;
  final bool includeParentEnvironment;
}

class ProcessResult {
  const ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get isSuccess => exitCode == 0;
}

class ProcessTimeoutException implements Exception {
  const ProcessTimeoutException(this.executable, this.timeout);

  final String executable;
  final Duration timeout;

  @override
  String toString() => 'Process "$executable" timed out after $timeout';
}

abstract interface class ProcessHandle {
  Stream<List<int>> get stdout;

  Stream<List<int>> get stderr;

  Future<int> get exitCode;

  Future<void> closeStdin();

  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);
}

abstract interface class ProcessLauncher {
  Future<ProcessHandle> start(ProcessSpec spec);
}

class IoProcessLauncher implements ProcessLauncher {
  const IoProcessLauncher();

  @override
  Future<ProcessHandle> start(ProcessSpec spec) async {
    final process = await Process.start(
      spec.executable,
      spec.arguments,
      environment: spec.environment.isEmpty ? null : spec.environment,
      workingDirectory: spec.workingDirectory,
      includeParentEnvironment: spec.includeParentEnvironment,
      runInShell: false,
    );
    return IoProcessHandle(process);
  }
}

class IoProcessHandle implements ProcessHandle {
  IoProcessHandle(this._process);

  final Process _process;

  @override
  Stream<List<int>> get stdout => _process.stdout;

  @override
  Stream<List<int>> get stderr => _process.stderr;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  Future<void> closeStdin() async {
    try {
      await _process.stdin.close();
    } on Object {
      // The process may have exited already; EOF is best-effort.
    }
  }

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    if (Platform.isWindows) {
      unawaited(_killTreeWindows());
      return true;
    }
    return _process.kill(signal);
  }

  Future<void> _killTreeWindows() async {
    try {
      final killer = await Process.start(
        'taskkill',
        ['/pid', '${_process.pid}', '/T', '/F'],
        runInShell: false,
      );
      await killer.exitCode;
    } catch (_) {
      _process.kill();
    }
  }
}

class ProcessRunner {
  ProcessRunner({ProcessLauncher launcher = const IoProcessLauncher()})
    : _launcher = launcher;

  final ProcessLauncher _launcher;

  Future<ProcessHandle> start(ProcessSpec spec) => _launcher.start(spec);

  Future<ProcessResult> run(
    ProcessSpec spec, {
    Duration? timeout,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  }) async {
    final handle = await _launcher.start(spec);
    // Some tools (e.g. FreeCAD) fall back to an interactive prompt when stdin
    // stays open; `run` is non-interactive, so give the child EOF.
    await handle.closeStdin();
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final stdoutDone = _consume(handle.stdout, stdoutBuffer, onStdout);
    final stderrDone = _consume(handle.stderr, stderrBuffer, onStderr);

    var timedOut = false;
    Future<int> exitFuture = handle.exitCode;
    if (timeout != null) {
      exitFuture = exitFuture.timeout(
        timeout,
        onTimeout: () {
          timedOut = true;
          handle.kill();
          return -1;
        },
      );
    }

    final exitCode = await exitFuture;
    await Future.wait([stdoutDone, stderrDone]);

    if (timedOut) {
      throw ProcessTimeoutException(spec.executable, timeout!);
    }

    return ProcessResult(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

  Future<void> _consume(
    Stream<List<int>> stream,
    StringBuffer buffer,
    void Function(String line)? onLine,
  ) {
    return stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            buffer.writeln(line);
            onLine?.call(line);
          },
          cancelOnError: true,
        )
        .asFuture<void>();
  }
}
