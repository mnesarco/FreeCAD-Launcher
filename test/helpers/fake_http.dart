// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

typedef FakeHttpHandler = Future<http.Response> Function(http.Request request);

class FakeHttp {
  FakeHttp(this.handler);

  factory FakeHttp.json(
    String body, {
    int statusCode = 200,
    Map<String, String> headers = const {},
  }) {
    return FakeHttp((request) async => http.Response(body, statusCode, headers: headers));
  }

  final FakeHttpHandler handler;
  final List<http.Request> requests = [];

  int get requestCount => requests.length;

  late final http.Client client = MockClient((request) async {
    requests.add(request);
    return handler(request);
  });
}
