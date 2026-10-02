// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:freecad_launcher/domain/jobs/job_types.dart';
import 'package:freecad_launcher/l10n/gen/app_localizations.dart';
import 'package:freecad_launcher/state/app_services.dart';
import 'package:freecad_launcher/ui/widgets/compact_badge.dart';

Future<void> showJobsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context).jobsTitle),
      content: SizedBox(width: 560, height: 380, child: const JobsList()),
      actions: [
        TextButton(
          onPressed: () => AppScope.of(context).jobs.clearFinished(),
          child: Text(AppLocalizations.of(context).jobsClearFinished),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).jobsClose),
        ),
      ],
    ),
  );
}

class JobsList extends SignalWidget {
  const JobsList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).jobs;
    final jobs = controller.jobs.value.reversed.toList();

    if (jobs.isEmpty) {
      return Center(child: Text(l10n.jobsEmpty));
    }

    return ListView.separated(
      itemCount: jobs.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _JobTile(job: jobs[index]),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).jobs;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_stateIcon(job.state), size: 18, color: _stateColor(context, job.state)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(job.label, style: theme.textTheme.titleSmall),
              ),
              CompactBadge(label: _stateLabel(l10n, job.state)),
            ],
          ),
          if (job.isActive) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: job.fraction),
          ],
          if (job.detail != null && job.detail!.isNotEmpty)
            Text(job.detail!, style: theme.textTheme.bodySmall),
          if (job.error != null && job.error!.isNotEmpty)
            Text(
              job.error!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          if (job.logPath != null)
            SelectableText(
              '${l10n.jobsLog}: ${job.logPath}',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (job.isActive)
                TextButton(
                  onPressed: () => controller.cancel(job.id),
                  child: Text(l10n.jobsCancel),
                ),
              if ((job.state == JobState.failed || job.state == JobState.cancelled) &&
                  controller.canRetry(job.id))
                TextButton(
                  onPressed: () => controller.retry(job.id),
                  child: Text(l10n.jobsRetry),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _stateLabel(AppLocalizations l10n, JobState state) {
    return switch (state) {
      JobState.queued => l10n.jobsQueued,
      JobState.running => l10n.jobsRunning,
      JobState.completed => l10n.jobsCompleted,
      JobState.failed => l10n.jobsFailed,
      JobState.cancelled => l10n.jobsCancelled,
    };
  }

  IconData _stateIcon(JobState state) {
    return switch (state) {
      JobState.queued => Icons.schedule,
      JobState.running => Icons.sync,
      JobState.completed => Icons.check_circle_outline,
      JobState.failed => Icons.error_outline,
      JobState.cancelled => Icons.cancel_outlined,
    };
  }

  Color _stateColor(BuildContext context, JobState state) {
    return switch (state) {
      JobState.completed => Colors.green,
      JobState.failed => Theme.of(context).colorScheme.error,
      JobState.cancelled => Theme.of(context).colorScheme.outline,
      _ => Theme.of(context).colorScheme.primary,
    };
  }
}
