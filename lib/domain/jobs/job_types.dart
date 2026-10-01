// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
enum JobKind { download, install, pip }

enum JobState { queued, running, completed, failed, cancelled }

class Job {
  const Job({
    required this.id,
    required this.kind,
    required this.label,
    required this.state,
    required this.createdAt,
    this.profileId,
    this.fraction,
    this.detail,
    this.logPath,
    this.error,
  });

  final String id;
  final JobKind kind;
  final String label;
  final JobState state;
  final DateTime createdAt;
  final String? profileId;
  final double? fraction;
  final String? detail;
  final String? logPath;
  final String? error;

  bool get isActive => state == JobState.queued || state == JobState.running;

  Job copyWith({
    JobState? state,
    double? fraction,
    String? detail,
    String? logPath,
    String? error,
  }) {
    return Job(
      id: id,
      kind: kind,
      label: label,
      state: state ?? this.state,
      createdAt: createdAt,
      profileId: profileId,
      fraction: fraction ?? this.fraction,
      detail: detail ?? this.detail,
      logPath: logPath ?? this.logPath,
      error: error ?? this.error,
    );
  }
}
