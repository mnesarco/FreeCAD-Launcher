// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:freecad_launcher/platform/process.dart';

class FakeProcessHandle implements ProcessHandle {
  final StreamController<List<int>> _stdoutController = StreamController<List<int>>();
  final StreamController<List<int>> _stderrController = StreamController<List<int>>();
  final Completer<int> _exitCompleter = Completer<int>();

  bool killed = false;
  bool stdinClosed = false;
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
  Future<void> closeStdin() async {
    stdinClosed = true;
  }

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
