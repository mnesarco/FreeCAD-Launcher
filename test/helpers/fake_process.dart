// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
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

  /// Exits while the stdio pipes stay open, as Windows can do when a child
  /// process inherits the write handles.
  void exitWithoutClosingStreams(int code) {
    if (!_exitCompleter.isCompleted) {
      _exitCompleter.complete(code);
    }
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

  final List<(int, Completer<FakeProcessHandle>)> _waiters = [];

  /// Resolves with the handle at [index] as soon as that process has been
  /// started — a deterministic replacement for timer-based polling (which
  /// flakes under load when the start path does real I/O first).
  Future<FakeProcessHandle> whenStarted(int index) {
    if (index < handles.length) {
      return Future.value(handles[index]);
    }
    final completer = Completer<FakeProcessHandle>();
    _waiters.add((index, completer));
    return completer.future;
  }

  @override
  Future<ProcessHandle> start(ProcessSpec spec) async {
    if (error != null) {
      throw error!;
    }
    specs.add(spec);
    final handle = FakeProcessHandle();
    handles.add(handle);
    _waiters.removeWhere((waiter) {
      if (waiter.$1 >= handles.length) {
        return false;
      }
      waiter.$2.complete(handles[waiter.$1]);
      return true;
    });
    return handle;
  }
}
