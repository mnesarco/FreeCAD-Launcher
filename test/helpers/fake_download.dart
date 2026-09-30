// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:freecad_launcher/platform/downloader.dart';

class FakeDownloadSource implements DownloadSource {
  final List<Uri> requests = [];
  Stream<List<int>> Function()? streamFactory;
  int? contentLength;
  Object? error;

  @override
  Future<DownloadStream> open(Uri uri) async {
    requests.add(uri);
    if (error != null) {
      throw error!;
    }
    return DownloadStream(bytes: streamFactory!(), contentLength: contentLength);
  }
}

class FakeDownloadSourceWithResponses implements DownloadSource {
  FakeDownloadSourceWithResponses(this.handler);

  final Future<DownloadStream> Function(Uri uri) handler;
  final List<Uri> requests = [];

  @override
  Future<DownloadStream> open(Uri uri) async {
    requests.add(uri);
    return handler(uri);
  }
}

Stream<List<int>> bytesStream(List<int> bytes) => Stream.fromIterable([bytes]);
