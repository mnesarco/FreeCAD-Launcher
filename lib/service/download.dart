import 'dart:io';
import 'package:signals_flutter/signals_flutter.dart';
import '../util/path.dart';

class DownloadManager {
  final HttpClient _client = HttpClient()
    ..autoUncompress = false
    ..connectionTimeout = const Duration(seconds: 15);

  /// Reactive list of URLs currently being downloaded.
  final activeDownloads = listSignal<String>([]);

  /// Reactive list of URLs failed to download.
  final failedDownloads = listSignal<String>([]);

  /// Whether a given URL is currently being downloaded.
  bool isDownloading(String url) => activeDownloads.contains(url);

  /// Whether a given URL download has failed.
  bool failedDownload(String url) => failedDownloads.contains(url);

  void dispose() {
    clear();
    _client.close(force: true);
  }

  void clear() {
    activeDownloads.clear();
    failedDownloads.clear();
  }

  void clearFailed() {
    failedDownloads.clear();
  }

  /// Download the url file into output path and return it, create any parent directory if needed.
  /// If the file already exists, return the cached path according to ttlSeconds.
  Future<String> download(String url, dynamic path, [int ttlSeconds = -1]) async {
    final output = await Path.support() / "downloads" / path;

    if (ttlSeconds != 0) {
      final live = await output.live();
      if (live > 0 && (ttlSeconds < 0 || live < ttlSeconds)) {
        return output.str;
      }
    }

    activeDownloads.add(url);
    failedDownloads.remove(url);
    try {
      final dir = Directory(output.str).parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final uri = Uri.parse(url);
      final request = await _client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        await response.drain();
        throw HttpException(
          'Download failed: ${response.statusCode} ${response.reasonPhrase}',
          uri: uri,
        );
      }

      final file = File(output.str);
      final sink = file.openWrite();
      var partial = true;
      try {
        await response.pipe(sink);
        partial = false;
      } finally {
        await sink.close();
        if (partial && await file.exists()) {
          await file.delete();
        }
      }

      return output.str;
    } catch (e) {
      failedDownloads.add(url);
      rethrow;
    } finally {
      activeDownloads.remove(url);
    }
  }
}
