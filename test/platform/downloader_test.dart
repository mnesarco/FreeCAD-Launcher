import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/cancellation.dart';
import 'package:freecad_launcher/platform/checksum.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_download.dart';

void main() {
  late Directory cacheDirectory;
  late FakeDownloadSource source;
  late Downloader downloader;

  setUp(() {
    cacheDirectory = Directory.systemTemp.createTempSync('fcl_downloader_test');
    source = FakeDownloadSource();
    downloader = Downloader(source: source, cacheDirectory: cacheDirectory.path);
  });

  tearDown(() {
    if (cacheDirectory.existsSync()) {
      cacheDirectory.deleteSync(recursive: true);
    }
  });

  final data = List<int>.generate(1000, (index) => index % 251);
  final uri = Uri.parse('https://example.invalid/FreeCAD.7z');

  test('downloads, verifies and renames the file', () async {
    source
      ..streamFactory = (() => Stream.fromIterable([data.sublist(0, 400), data.sublist(400)]))
      ..contentLength = data.length;
    final progress = <DownloadProgress>[];

    final result = await downloader.download(
      uri: uri,
      fileName: 'FreeCAD.7z',
      expectedSha256: sha256OfBytes(data),
      onProgress: progress.add,
    );

    expect(result.fromCache, isFalse);
    expect(result.bytes, data.length);
    expect(result.sha256, sha256OfBytes(data));
    expect(File(result.path).readAsBytesSync(), data);
    expect(File('${result.path}.part').existsSync(), isFalse);
    expect(progress, isNotEmpty);
    expect(progress.last.receivedBytes, data.length);
    expect(progress.last.totalBytes, data.length);
    expect(progress.last.fraction, 1.0);
  });

  test('skips hashing when no checksum is provided', () async {
    source.streamFactory = () => Stream.fromIterable([data]);

    final result = await downloader.download(uri: uri, fileName: 'FreeCAD.7z');

    expect(result.sha256, isNull);
    expect(File(result.path).readAsBytesSync(), data);
  });

  test('coalesces progress updates but always reports completion', () async {
    final chunks = List.generate(256, (index) => List<int>.filled(65536, index % 256));
    source
      ..streamFactory = (() => Stream.fromIterable(chunks))
      ..contentLength = 256 * 65536;
    final progress = <DownloadProgress>[];

    await downloader.download(uri: uri, fileName: 'FreeCAD.7z', onProgress: progress.add);

    expect(progress.length, lessThan(chunks.length));
    expect(progress.last.receivedBytes, 256 * 65536);
    expect(progress.last.fraction, 1.0);
  });

  test('returns a cached file without opening the source', () async {
    final target = File(p.join(cacheDirectory.path, 'FreeCAD.7z'))..writeAsBytesSync(data);

    final result = await downloader.download(
      uri: uri,
      fileName: 'FreeCAD.7z',
      expectedSha256: sha256OfBytes(data),
    );

    expect(result.fromCache, isTrue);
    expect(result.path, target.path);
    expect(result.bytes, data.length);
    expect(source.requests, isEmpty);
  });

  test('rejects a corrupted download and leaves no files behind', () async {
    source
      ..streamFactory = (() => Stream.fromIterable([data]))
      ..contentLength = data.length;
    final expected = List.filled(64, '0').join();

    await expectLater(
      downloader.download(uri: uri, fileName: 'FreeCAD.7z', expectedSha256: expected),
      throwsA(isA<ChecksumMismatchException>()),
    );

    expect(File(p.join(cacheDirectory.path, 'FreeCAD.7z')).existsSync(), isFalse);
    expect(File(p.join(cacheDirectory.path, 'FreeCAD.7z.part')).existsSync(), isFalse);
  });

  test('propagates HTTP errors without leaving partial files', () async {
    source.error = const DownloadException('Request failed with HTTP 404', statusCode: 404);

    await expectLater(
      downloader.download(uri: uri, fileName: 'FreeCAD.7z'),
      throwsA(isA<DownloadException>()),
    );

    expect(Directory(cacheDirectory.path).listSync(), isEmpty);
  });

  test('cleans up when the stream fails mid-download', () async {
    source.streamFactory = () => () async* {
      yield data.sublist(0, 100);
      throw const DownloadException('connection lost');
    }();

    await expectLater(
      downloader.download(uri: uri, fileName: 'FreeCAD.7z'),
      throwsA(isA<DownloadException>()),
    );

    expect(Directory(cacheDirectory.path).listSync(), isEmpty);
  });

  test('cancels and cleans up when the token is triggered', () async {
    final token = CancellationToken();
    source
      ..streamFactory = (() => Stream.fromIterable([data.sublist(0, 400), data.sublist(400)]))
      ..contentLength = data.length;

    await expectLater(
      downloader.download(
        uri: uri,
        fileName: 'FreeCAD.7z',
        cancellationToken: token,
        onProgress: (progress) {
          if (progress.receivedBytes >= 400) {
            token.cancel();
          }
        },
      ),
      throwsA(isA<DownloadCancelledException>()),
    );

    expect(Directory(cacheDirectory.path).listSync(), isEmpty);
  });

  test('reports unknown totals as a null fraction', () async {
    source.streamFactory = () => Stream.fromIterable([data]);
    final progress = <DownloadProgress>[];

    await downloader.download(uri: uri, fileName: 'FreeCAD.7z', onProgress: progress.add);

    expect(progress.last.fraction, isNull);
  });
}
