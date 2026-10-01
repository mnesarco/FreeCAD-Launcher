// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:freecad_launcher/core/cancellation.dart';
import 'package:freecad_launcher/core/constants.dart';
import 'package:freecad_launcher/platform/checksum.dart';

class DownloadProgress {
  const DownloadProgress({required this.receivedBytes, this.totalBytes});

  final int receivedBytes;
  final int? totalBytes;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) {
      return null;
    }
    return receivedBytes / total;
  }
}

class DownloadStream {
  const DownloadStream({required this.bytes, this.contentLength});

  final Stream<List<int>> bytes;
  final int? contentLength;
}

abstract interface class DownloadSource {
  Future<DownloadStream> open(Uri uri);
}

class DownloadException implements Exception {
  const DownloadException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() =>
      'DownloadException: $message${cause == null ? '' : ' ($cause)'}';
}

class ChecksumMismatchException implements Exception {
  const ChecksumMismatchException({required this.expected, required this.actual});

  final String expected;
  final String actual;

  @override
  String toString() => 'Checksum mismatch: expected $expected, got $actual';
}

class DownloadCancelledException implements Exception {
  const DownloadCancelledException();

  @override
  String toString() => 'Download was cancelled';
}

class DownloadResult {
  const DownloadResult({
    required this.path,
    required this.bytes,
    this.sha256,
    required this.fromCache,
  });

  final String path;
  final int bytes;

  /// Present only when the file was verified against an expected checksum or
  /// read from a verified cache entry.
  final String? sha256;

  final bool fromCache;
}

class HttpDownloadSource implements DownloadSource {
  HttpDownloadSource(this._client);

  final http.Client _client;

  @override
  Future<DownloadStream> open(Uri uri) async {
    final request = http.Request('GET', uri);
    request.headers['User-Agent'] = '$appName/$appVersion';

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw DownloadException(
        'Request failed with HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return DownloadStream(bytes: response.stream, contentLength: response.contentLength);
  }
}

class Downloader {
  Downloader({required DownloadSource source, required String cacheDirectory})
    : _source = source,
      _cacheDirectory = cacheDirectory;

  static const int _progressDeltaBytes = 256 * 1024;

  final DownloadSource _source;
  final String _cacheDirectory;

  Future<DownloadResult> download({
    required Uri uri,
    required String fileName,
    String? directory,
    String? expectedSha256,
    void Function(DownloadProgress progress)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final targetDirectory = directory ?? _cacheDirectory;
    await Directory(targetDirectory).create(recursive: true);
    final target = File(p.join(targetDirectory, fileName));
    final part = File('${target.path}.part');

    final expected = expectedSha256?.toLowerCase();

    if (expected != null && target.existsSync()) {
      final existing = await sha256File(target.path);
      if (existing == expected) {
        return DownloadResult(
          path: target.path,
          bytes: await target.length(),
          sha256: existing,
          fromCache: true,
        );
      }
      target.deleteSync();
    }

    DownloadStream stream;
    try {
      stream = await _source.open(uri);
    } on DownloadException {
      rethrow;
    } on Object catch (error) {
      throw DownloadException('Could not start the download', cause: error);
    }

    var received = 0;
    var lastReported = 0;
    var lastPercent = -1;
    var sinkClosed = false;
    final sink = part.openWrite();
    final totalBytes = stream.contentLength;

    void reportProgress({required bool force}) {
      final bool shouldReport;
      if (totalBytes != null && totalBytes > 0) {
        final percent = received * 100 ~/ totalBytes;
        shouldReport = percent != lastPercent;
        lastPercent = percent;
      } else {
        shouldReport = received - lastReported >= _progressDeltaBytes;
        lastReported = received;
      }
      if (!force && !shouldReport) {
        return;
      }
      onProgress?.call(
        DownloadProgress(receivedBytes: received, totalBytes: totalBytes),
      );
    }

    try {
      await for (final chunk in stream.bytes) {
        if (cancellationToken?.isCancelled ?? false) {
          throw const DownloadCancelledException();
        }
        sink.add(chunk);
        received += chunk.length;
        reportProgress(force: false);
        if (totalBytes != null && received >= totalBytes) {
          break;
        }
      }
      await sink.flush();
      await sink.close();
      sinkClosed = true;
      reportProgress(force: true);
    } on Object {
      if (!sinkClosed) {
        try {
          await sink.close();
        } catch (_) {
          // The sink may already be closed; cleanup below still applies.
        }
      }
      if (part.existsSync()) {
        part.deleteSync();
      }
      rethrow;
    }

    if (totalBytes != null && received < totalBytes) {
      if (part.existsSync()) {
        part.deleteSync();
      }
      throw DownloadException(
        'The download ended early ($received of $totalBytes bytes)',
      );
    }

    String? actual;
    if (expected != null) {
      actual = await sha256File(part.path);
      if (actual != expected) {
        part.deleteSync();
        throw ChecksumMismatchException(expected: expected, actual: actual);
      }
    }

    if (target.existsSync()) {
      target.deleteSync();
    }
    final result = await part.rename(target.path);

    return DownloadResult(
      path: result.path,
      bytes: received,
      sha256: actual,
      fromCache: false,
    );
  }
}
