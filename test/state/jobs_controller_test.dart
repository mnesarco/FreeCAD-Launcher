// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/state/jobs_controller.dart';

void main() {
  late JobsController controller;

  setUp(() {
    controller = JobsController(clock: () => DateTime.utc(2026, 9, 19, 16));
  });

  tearDown(() {
    controller.dispose();
  });

  test('runs a job, surfaces progress and completes with the result', () async {
    final result = await controller.run<int>(
      kind: JobKind.install,
      label: 'Install FreeCAD 1.1.3',
      profileId: 'profile-1',
      task: (context) async {
        context.report(fraction: 0.5, detail: 'Downloading');
        context.setLogPath('/logs/job.log');
        return 7;
      },
    );

    expect(result, 7);
    final job = controller.jobs.value.single;
    expect(job.state, JobState.completed);
    expect(job.fraction, 1);
    expect(job.detail, 'Downloading');
    expect(job.logPath, '/logs/job.log');
    expect(job.profileId, 'profile-1');
    expect(job.createdAt, DateTime.utc(2026, 9, 19, 16));
    expect(controller.activeJobs, isEmpty);
  });

  test('formats byte progress in the job detail', () async {
    await controller.run<void>(
      kind: JobKind.download,
      label: 'Download',
      task: (context) async {
        context.report(
          receivedBytes: 2048,
          totalBytes: 4096,
          bytesPerSecond: 1024,
        );
      },
    );

    expect(controller.jobs.value.single.detail, contains('2 KiB / 4 KiB'));
    expect(controller.jobs.value.single.detail, contains('1 KiB/s'));
  });

  test('reports failures with the error message', () async {
    final result = await controller.run<Object?>(
      kind: JobKind.pip,
      label: 'Install numpy',
      task: (context) async => throw StateError('pip exploded'),
    );

    expect(result, isNull);
    final job = controller.jobs.value.single;
    expect(job.state, JobState.failed);
    expect(job.error, contains('pip exploded'));
  });

  test('queues install jobs beyond the single install slot', () async {
    final first = Completer<void>();
    final second = Completer<void>();
    final firstRun = controller.run<void>(
      kind: JobKind.install,
      label: 'First',
      task: (context) => first.future,
    );
    final secondRun = controller.run<void>(
      kind: JobKind.install,
      label: 'Second',
      task: (context) => second.future,
    );

    expect(controller.jobs.value[0].state, JobState.running);
    expect(controller.jobs.value[1].state, JobState.queued);
    expect(controller.activeJobs, hasLength(2));

    first.complete();
    await firstRun;
    await pumpEventQueue();

    expect(controller.jobs.value[0].state, JobState.completed);
    expect(controller.jobs.value[1].state, JobState.running);

    second.complete();
    await secondRun;
    expect(controller.jobs.value[1].state, JobState.completed);
  });

  test('allows two concurrent downloads and queues the third', () async {
    final completers = [Completer<void>(), Completer<void>(), Completer<void>()];
    final runs = [
      for (final completer in completers)
        controller.run<void>(
          kind: JobKind.download,
          label: 'Download',
          task: (context) => completer.future,
        ),
    ];

    expect(controller.jobs.value[0].state, JobState.running);
    expect(controller.jobs.value[1].state, JobState.running);
    expect(controller.jobs.value[2].state, JobState.queued);

    completers[0].complete();
    await runs[0];
    await pumpEventQueue();
    expect(controller.jobs.value[2].state, JobState.running);

    completers[1].complete();
    completers[2].complete();
    await Future.wait(runs.skip(1));
  });

  test('cancelling a queued job finishes it without running the task', () async {
    final gate = Completer<void>();
    final running = controller.run<void>(
      kind: JobKind.install,
      label: 'Running',
      task: (context) => gate.future,
    );
    var queuedRan = false;
    final queued = controller.run<Object?>(
      kind: JobKind.install,
      label: 'Queued',
      task: (context) async {
        queuedRan = true;
        return null;
      },
    );

    controller.cancel(controller.jobs.value[1].id);

    expect(await queued, isNull);
    expect(controller.jobs.value[1].state, JobState.cancelled);
    expect(queuedRan, isFalse);

    gate.complete();
    await running;
  });

  test('cancelling a running job marks it cancelled so tasks can stop', () async {
    final started = Completer<void>();
    final gate = Completer<void>();
    final run = controller.run<Object?>(
      kind: JobKind.download,
      label: 'Download',
      task: (context) async {
        started.complete();
        await gate.future;
        if (context.isCancelled) {
          throw StateError('cancelled');
        }
        return null;
      },
    );
    await started.future;

    controller.cancel(controller.jobs.value.single.id);
    gate.complete();

    expect(await run, isNull);
    expect(controller.jobs.value.single.state, JobState.cancelled);
  });

  test('retry runs the registered retry callback', () async {
    var attempts = 0;
    final run = controller.run<void>(
      kind: JobKind.pip,
      label: 'Install numpy',
      onRetry: () async {
        attempts++;
      },
      task: (context) async {
        throw StateError('boom');
      },
    );
    await run;

    final id = controller.jobs.value.single.id;
    expect(controller.canRetry(id), isTrue);
    expect(controller.canRetry('missing'), isFalse);

    controller.retry(id);
    await pumpEventQueue();
    expect(attempts, 1);
  });

  test('clearFinished removes finished jobs and keeps active ones', () async {
    final gate = Completer<void>();
    final active = controller.run<void>(
      kind: JobKind.download,
      label: 'Active',
      task: (context) => gate.future,
    );
    await controller.run<void>(
      kind: JobKind.pip,
      label: 'Finished',
      task: (context) async {},
    );

    controller.clearFinished();

    expect(controller.jobs.value, hasLength(1));
    expect(controller.jobs.value.single.label, 'Active');

    gate.complete();
    await active;
  });

  test('dispose cancels the tokens of running jobs', () async {
    final started = Completer<void>();
    final gate = Completer<void>();
    final run = controller.run<void>(
      kind: JobKind.download,
      label: 'Download',
      task: (context) async {
        started.complete();
        await gate.future;
      },
    );
    await started.future;

    var cancelled = false;
    controller.dispose();
    gate.complete();
    await run.whenComplete(() => cancelled = true);

    expect(cancelled, isTrue);
  });
}
