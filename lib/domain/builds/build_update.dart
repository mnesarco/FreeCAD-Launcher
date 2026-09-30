// SPDX-License-Identifier: GPL-3.0-or-later
class BuildUpdate {
  const BuildUpdate({
    required this.buildId,
    required this.installedVersion,
    required this.latestVersion,
    required this.candidateId,
  });

  final String buildId;
  final String installedVersion;
  final String latestVersion;
  final String candidateId;
}
