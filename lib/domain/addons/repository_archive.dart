// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
enum ArchiveResolutionIssue { invalidUrl, unsupportedScheme, unsupportedHost, missingRef }

class ArchiveResolution {
  const ArchiveResolution.success(this.uri, {required this.direct}) : issue = null;

  const ArchiveResolution.failure(this.issue) : uri = null, direct = false;

  final Uri? uri;
  final ArchiveResolutionIssue? issue;
  final bool direct;

  bool get isSuccess => uri != null;
}

const _archiveExtensions = ['.zip', '.tar.gz', '.tgz', '.tar'];

const _giteaHosts = {'codeberg.org', 'gitea.com', 'forgejo.org'};

ArchiveResolution resolveRepositoryArchive(String repositoryUrl, String? gitRef) {
  final uri = Uri.tryParse(repositoryUrl.trim());
  if (uri == null || uri.host.isEmpty) {
    return const ArchiveResolution.failure(ArchiveResolutionIssue.invalidUrl);
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return const ArchiveResolution.failure(ArchiveResolutionIssue.unsupportedScheme);
  }
  if (isArchiveUrl(uri)) {
    return ArchiveResolution.success(uri, direct: true);
  }

  final ref = gitRef?.trim() ?? '';
  if (ref.isEmpty) {
    return const ArchiveResolution.failure(ArchiveResolutionIssue.missingRef);
  }

  final segments = uri.pathSegments
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) {
    return const ArchiveResolution.failure(ArchiveResolutionIssue.invalidUrl);
  }

  final encodedRef = Uri.encodeComponent(ref);
  final host = uri.host.toLowerCase();
  final repository = _withoutGitSuffix(segments.last);

  if (host == 'github.com' && segments.length >= 2) {
    return ArchiveResolution.success(
      Uri.parse('https://github.com/${segments[0]}/$repository/archive/$encodedRef.zip'),
      direct: false,
    );
  }
  if (host == 'gitlab.com' && segments.length >= 2) {
    return ArchiveResolution.success(
      Uri.parse(
        'https://gitlab.com/${segments.join('/')}/-/archive/$encodedRef/'
        '$repository-$encodedRef.zip',
      ),
      direct: false,
    );
  }
  if (_isGiteaHost(host) && segments.length >= 2) {
    return ArchiveResolution.success(
      Uri.parse('${uri.scheme}://${uri.host}/${segments.join('/')}/archive/$encodedRef.zip'),
      direct: false,
    );
  }
  return const ArchiveResolution.failure(ArchiveResolutionIssue.unsupportedHost);
}

bool isArchiveUrl(Uri uri) {
  final path = uri.path.toLowerCase();
  return _archiveExtensions.any(path.endsWith);
}

bool _isGiteaHost(String host) {
  if (_giteaHosts.contains(host)) {
    return true;
  }
  return host.contains('gitea') || host.contains('forgejo') || host.contains('codeberg');
}

String _withoutGitSuffix(String segment) {
  if (segment.toLowerCase().endsWith('.git')) {
    return segment.substring(0, segment.length - 4);
  }
  return segment;
}
