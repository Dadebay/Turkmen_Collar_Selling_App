import 'dart:convert';

import 'package:http/http.dart' as client;

import 'api_logger.dart';

export 'package:http/http.dart' hide get, post;

const _requestTimeout = Duration(seconds: 30);

Future<client.Response> get(Uri url, {Map<String, String>? headers}) =>
    _run('GET', url, () => client.get(url, headers: headers));

Future<client.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _run(
  'POST',
  url,
  () => client.post(url, headers: headers, body: body, encoding: encoding),
);

Future<client.Response> _run(
  String method,
  Uri url,
  Future<client.Response> Function() operation,
) async {
  ApiLogger.request(method, url);
  try {
    final response = await operation().timeout(_requestTimeout);
    ApiLogger.response(method, url, response.statusCode);
    return response;
  } catch (error) {
    ApiLogger.error(method, url, error);
    rethrow;
  }
}

/// Covers multipart and custom requests while retaining response streaming.
Future<client.StreamedResponse> send(client.BaseRequest request) async {
  ApiLogger.request(request.method, request.url);
  try {
    final response = await request.send().timeout(_requestTimeout);
    ApiLogger.response(request.method, request.url, response.statusCode);
    return response;
  } catch (error) {
    ApiLogger.error(request.method, request.url, error);
    rethrow;
  }
}
