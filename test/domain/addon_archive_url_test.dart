// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/addons/repository_archive.dart';

void main() {
  group('resolveRepositoryArchive', () {
    test('builds the GitHub archive URL for a branch', () {
      final result = resolveRepositoryArchive('https://github.com/FreeCAD/FreeCAD-addons', 'main');

      expect(result.isSuccess, isTrue);
      expect(result.direct, isFalse);
      expect(result.uri.toString(), 'https://github.com/FreeCAD/FreeCAD-addons/archive/main.zip');
    });

    test('strips a .git suffix and trailing slash', () {
      final result = resolveRepositoryArchive('https://github.com/owner/repo.git/', 'v1.0');

      expect(result.uri.toString(), 'https://github.com/owner/repo/archive/v1.0.zip');
    });

    test('builds the GitLab archive URL for nested groups', () {
      final result = resolveRepositoryArchive('https://gitlab.com/group/sub/repo', 'main');

      expect(
        result.uri.toString(),
        'https://gitlab.com/group/sub/repo/-/archive/main/repo-main.zip',
      );
    });

    test('builds the Gitea/Codeberg archive URL', () {
      final result = resolveRepositoryArchive('https://codeberg.org/owner/repo', 'main');

      expect(result.uri.toString(), 'https://codeberg.org/owner/repo/archive/main.zip');
    });

    test('supports self-hosted Gitea hosts', () {
      final result = resolveRepositoryArchive('https://git.gitea.example.com/owner/repo', 'dev');

      expect(result.uri.toString(), 'https://git.gitea.example.com/owner/repo/archive/dev.zip');
    });

    test('encodes refs with special characters', () {
      final result = resolveRepositoryArchive('https://github.com/owner/repo', 'feature/x');

      expect(result.uri.toString(), 'https://github.com/owner/repo/archive/feature%2Fx.zip');
    });

    test('passes a direct archive URL through and ignores the ref', () {
      final result = resolveRepositoryArchive(
        'https://example.com/files/addon.zip?token=abc',
        null,
      );

      expect(result.isSuccess, isTrue);
      expect(result.direct, isTrue);
      expect(result.uri.toString(), 'https://example.com/files/addon.zip?token=abc');
    });

    test('accepts direct tar.gz URLs', () {
      final result = resolveRepositoryArchive('https://example.com/addon.tar.gz', '');

      expect(result.isSuccess, isTrue);
      expect(result.direct, isTrue);
    });

    test('requires a ref for repository URLs', () {
      final result = resolveRepositoryArchive('https://github.com/owner/repo', ' ');

      expect(result.isSuccess, isFalse);
      expect(result.issue, ArchiveResolutionIssue.missingRef);
    });

    test('rejects unsupported hosts', () {
      final result = resolveRepositoryArchive('https://example.com/owner/repo', 'main');

      expect(result.isSuccess, isFalse);
      expect(result.issue, ArchiveResolutionIssue.unsupportedHost);
    });

    test('rejects non-http schemes', () {
      final result = resolveRepositoryArchive('ftp://github.com/owner/repo', 'main');

      expect(result.isSuccess, isFalse);
      expect(result.issue, ArchiveResolutionIssue.unsupportedScheme);
    });

    test('rejects invalid URLs', () {
      final result = resolveRepositoryArchive('not a url', 'main');

      expect(result.isSuccess, isFalse);
      expect(result.issue, ArchiveResolutionIssue.invalidUrl);
    });
  });
}
