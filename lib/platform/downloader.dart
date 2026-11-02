// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:isolate';

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

    void reportProgress(int received, int? total) => onProgress?.call(
      DownloadProgress(receivedBytes: received, totalBytes: total),
    );

    try {
      final transfer = await _transfer(
        uri: uri,
        part: part,
        cancellationToken: cancellationToken,
        onProgress: reportProgress,
      );

      if (transfer.total != null && transfer.bytes < transfer.total!) {
        throw DownloadException(
          'The download ended early (${transfer.bytes} of ${transfer.total} bytes)',
        );
      }

      String? actual;
      if (expected != null) {
        actual = await sha256File(part.path);
        if (actual != expected) {
          throw ChecksumMismatchException(expected: expected, actual: actual);
        }
      }

      if (target.existsSync()) {
        target.deleteSync();
      }
      final result = await part.rename(target.path);

      return DownloadResult(
        path: result.path,
        bytes: transfer.bytes,
        sha256: actual,
        fromCache: false,
      );
    } on Object {
      if (part.existsSync()) {
        part.deleteSync();
      }
      rethrow;
    }
  }

  Future<_Transfer> _transfer({
    required Uri uri,
    required File part,
    required CancellationToken? cancellationToken,
    required void Function(int received, int? total) onProgress,
  }) async {
    final source = _source;
    // HTTP bodies are pulled off the UI isolate; injected sources (tests) stream in-process.
    if (source is HttpDownloadSource) {
      return _transferInIsolate(
        uri: uri,
        part: part,
        cancellationToken: cancellationToken,
        onProgress: onProgress,
      );
    }
    final DownloadStream stream;
    try {
      stream = await source.open(uri);
    } on DownloadException {
      rethrow;
    } on Object catch (error) {
      throw DownloadException('Could not start the download', cause: error);
    }
    return _copyToFile(
      stream,
      part,
      isCancelled: () => cancellationToken?.isCancelled ?? false,
      onProgress: onProgress,
    );
  }

  Future<_Transfer> _transferInIsolate({
    required Uri uri,
    required File part,
    required CancellationToken? cancellationToken,
    required void Function(int received, int? total) onProgress,
  }) async {
    final messages = ReceivePort();
    final SendPort replyPort = messages.sendPort;
    SendPort? commands;
    var cancelled = false;
    var finished = false;

    cancellationToken?.addListener(() {
      cancelled = true;
      commands?.send(true);
    });
    final subscription = messages.listen((message) {
      switch (message) {
        case SendPort port:
          commands = port;
          if (cancelled) {
            port.send(true);
          }
        case _TransferProgress(:final received, :final total):
          if (!finished) {
            onProgress(received, total);
          }
      }
    });

    try {
      final transfer = await _runTransferIsolate(uri, part.path, replyPort);
      finished = true;
      if (cancelled) {
        throw const DownloadCancelledException();
      }
      return transfer;
    } finally {
      await subscription.cancel();
      messages.close();
    }
  }
}

/// Kept separate so the spawned closure captures only sendable values.
Future<_Transfer> _runTransferIsolate(Uri uri, String path, SendPort reply) =>
    Isolate.run(() => _transferWorker(uri, path, reply));

class _Transfer {
  const _Transfer({required this.bytes, required this.total});

  final int bytes;
  final int? total;
}

class _TransferProgress {
  const _TransferProgress(this.received, this.total);

  final int received;
  final int? total;
}

/// Worker isolate entry: streams [uri] into [path] and reports progress to [reply].
Future<_Transfer> _transferWorker(Uri uri, String path, SendPort reply) async {
  final commands = ReceivePort();
  var cancelled = false;
  final subscription = commands.listen((_) => cancelled = true);
  reply.send(commands.sendPort);
  final client = http.Client();
  try {
    final DownloadStream stream;
    try {
      stream = await HttpDownloadSource(client).open(uri);
    } on DownloadException {
      rethrow;
    } on Object catch (error) {
      throw DownloadException('Could not start the download', cause: error);
    }
    return await _copyToFile(
      stream,
      File(path),
      isCancelled: () => cancelled,
      onProgress: (received, total) => reply.send(_TransferProgress(received, total)),
    );
  } finally {
    await subscription.cancel();
    commands.close();
    client.close();
  }
}

Future<_Transfer> _copyToFile(
  DownloadStream stream,
  File part, {
  required bool Function() isCancelled,
  required void Function(int received, int? total) onProgress,
}) async {
  final total = stream.contentLength;
  var received = 0;
  var lastReported = 0;
  var lastPercent = -1;

  void report({required bool force}) {
    final bool shouldReport;
    if (total != null && total > 0) {
      final percent = received * 100 ~/ total;
      shouldReport = percent != lastPercent;
      lastPercent = percent;
    } else {
      shouldReport = received - lastReported >= Downloader._progressDeltaBytes;
      lastReported = received;
    }
    if (force || shouldReport) {
      onProgress(received, total);
    }
  }

  final sink = part.openWrite();
  var sinkClosed = false;
  try {
    await for (final chunk in stream.bytes) {
      if (isCancelled()) {
        throw const DownloadCancelledException();
      }
      sink.add(chunk);
      received += chunk.length;
      report(force: false);
      if (total != null && received >= total) {
        break;
      }
    }
    await sink.flush();
    await sink.close();
    sinkClosed = true;
    report(force: true);
  } on Object {
    if (!sinkClosed) {
      try {
        await sink.close();
      } catch (_) {
        // The sink may already be closed; the caller deletes the partial file.
      }
    }
    rethrow;
  }
  return _Transfer(bytes: received, total: total);
}
