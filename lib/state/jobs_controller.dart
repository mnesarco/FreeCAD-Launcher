import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:freecad_launcher/core/cancellation.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';

class JobContext {
  JobContext._(this._jobs, this.id, this.token);

  final JobsController _jobs;
  final String id;

  /// True once the user requested cancellation; long-running work should stop
  /// at the next safe point.
  final CancellationToken token;

  bool get isCancelled => token.isCancelled;

  void report({
    double? fraction,
    String? detail,
    int? receivedBytes,
    int? totalBytes,
    int? bytesPerSecond,
  }) {
    _jobs._report(
      id,
      fraction: fraction,
      detail: detail,
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
      bytesPerSecond: bytesPerSecond,
    );
  }

  void setLogPath(String path) => _jobs._setLogPath(id, path);

  /// Marks the job as failed while still letting the task return its `Result`.
  void fail(String? message) => _jobs._markFailed(id, message);
}

class JobsController {
  JobsController({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const int downloadLimit = 2;
  static const int installLimit = 1;

  final DateTime Function() _clock;

  final jobs = signal<List<Job>>([]);

  final Map<String, CancellationToken> _tokens = {};
  final Set<String> _failed = {};
  final Map<String, Future<void> Function()> _retries = {};
  final Map<String, int> _runningByGroup = {'download': 0, 'install': 0};
  final List<_QueuedJob> _queue = [];

  List<Job> get activeJobs =>
      jobs.value.where((job) => job.isActive).toList(growable: false);

  Job? byId(String id) {
    for (final job in jobs.value) {
      if (job.id == id) {
        return job;
      }
    }
    return null;
  }

  Future<T?> run<T>({
    required JobKind kind,
    required String label,
    String? profileId,
    required Future<T> Function(JobContext context) task,
    Future<void> Function()? onRetry,
  }) {
    final id = const Uuid().v4();
    final token = CancellationToken();
    final group = _groupOf(kind);
    final completer = Completer<T?>();
    _tokens[id] = token;
    if (onRetry != null) {
      _retries[id] = onRetry;
    }
    _upsert(
      Job(
        id: id,
        kind: kind,
        label: label,
        state: JobState.queued,
        profileId: profileId,
        createdAt: _clock(),
      ),
    );

    final queued = _QueuedJob(
      id: id,
      group: group,
      start: () => _execute(id, token, task, completer),
      cancel: () {
        _updateState(id, JobState.cancelled);
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    if (_runningByGroup[group]! < _limitFor(kind)) {
      queued.start();
    } else {
      _queue.add(queued);
    }
    return completer.future;
  }

  void cancel(String id) {
    final queuedIndex = _queue.indexWhere((job) => job.id == id);
    if (queuedIndex >= 0) {
      final queued = _queue.removeAt(queuedIndex);
      queued.cancel();
      return;
    }
    _tokens[id]?.cancel();
  }

  void retry(String id) {
    final retry = _retries[id];
    if (retry != null) {
      unawaited(retry());
    }
  }

  bool canRetry(String id) => _retries.containsKey(id);

  void clearFinished() {
    final kept = jobs.value.where((job) => job.isActive).toList();
    final keptIds = kept.map((job) => job.id).toSet();
    _retries.removeWhere((id, _) => !keptIds.contains(id));
    _failed.removeWhere((id) => !keptIds.contains(id));
    jobs.value = kept;
  }

  Future<void> _execute<T>(
    String id,
    CancellationToken token,
    Future<T> Function(JobContext context) task,
    Completer<T?> completer,
  ) async {
    final group = _groupFor(id);
    _runningByGroup[group] = _runningByGroup[group]! + 1;
    _updateState(id, JobState.running);
    final context = JobContext._(this, id, token);
    try {
      final result = await task(context);
      if (token.isCancelled) {
        _updateState(id, JobState.cancelled);
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      } else if (_failed.contains(id)) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } else {
        _updateState(id, JobState.completed, fraction: 1);
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      }
    } on Object catch (error) {
      if (token.isCancelled) {
        _updateState(id, JobState.cancelled);
      } else {
        _updateState(id, JobState.failed, error: error.toString());
      }
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    } finally {
      _runningByGroup[group] = _runningByGroup[group]! - 1;
      _pump();
    }
  }

  void _pump() {
    while (_queue.isNotEmpty) {
      final index = _queue.indexWhere(
        (job) => _runningByGroup[job.group]! < _limitForGroup(job.group),
      );
      if (index < 0) {
        return;
      }
      final queued = _queue.removeAt(index);
      queued.start();
    }
  }

  void _report(
    String id, {
    double? fraction,
    String? detail,
    int? receivedBytes,
    int? totalBytes,
    int? bytesPerSecond,
  }) {
    final job = byId(id);
    if (job == null) {
      return;
    }
    final parts = <String>[
      ?detail,
      if (receivedBytes != null && totalBytes != null)
        '${_bytes(receivedBytes)} / ${_bytes(totalBytes)}',
      if (bytesPerSecond != null && bytesPerSecond > 0)
        '${_bytes(bytesPerSecond)}/s',
    ];
    _replace(
      job.copyWith(
        fraction: fraction,
        detail: parts.isEmpty ? null : parts.join('  ·  '),
      ),
    );
  }

  void _markFailed(String id, String? message) {
    final job = byId(id);
    if (job != null) {
      _failed.add(id);
      _replace(job.copyWith(state: JobState.failed, error: message));
    }
  }

  void _setLogPath(String id, String path) {
    final job = byId(id);
    if (job != null) {
      _replace(job.copyWith(logPath: path));
    }
  }

  void _updateState(
    String id,
    JobState state, {
    double? fraction,
    String? error,
  }) {
    final job = byId(id);
    if (job != null) {
      _replace(job.copyWith(state: state, fraction: fraction, error: error));
    }
  }

  void _upsert(Job job) {
    jobs.value = [...jobs.value, job];
  }

  void _replace(Job job) {
    jobs.value = [
      for (final existing in jobs.value)
        if (existing.id == job.id) job else existing,
    ];
  }

  String _groupOf(JobKind kind) => kind == JobKind.download ? 'download' : 'install';

  String _groupFor(String id) {
    final job = byId(id);
    return job == null ? 'install' : _groupOf(job.kind);
  }

  int _limitFor(JobKind kind) => kind == JobKind.download ? downloadLimit : installLimit;

  int _limitForGroup(String group) => group == 'download' ? downloadLimit : installLimit;

  static String _bytes(int bytes) {
    const kib = 1024;
    const mib = kib * 1024;
    const gib = mib * 1024;
    if (bytes >= gib) {
      return '${(bytes / gib).toStringAsFixed(2)} GiB';
    }
    if (bytes >= mib) {
      return '${(bytes / mib).toStringAsFixed(1)} MiB';
    }
    if (bytes >= kib) {
      return '${(bytes / kib).toStringAsFixed(0)} KiB';
    }
    return '$bytes B';
  }

  void dispose() {
    for (final token in _tokens.values) {
      token.cancel();
    }
    _tokens.clear();
    _queue.clear();
  }
}

class _QueuedJob {
  const _QueuedJob({
    required this.id,
    required this.group,
    required this.start,
    required this.cancel,
  });

  final String id;
  final String group;
  final void Function() start;
  final void Function() cancel;
}
