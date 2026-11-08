import 'package:flutter/foundation.dart';

/// Debug-only, colored HTTP output shared by the http and Dio clients.
abstract final class ApiLogger {
  static const _reset = '\x1B[0m';
  static const _cyan = '\x1B[36m';
  static const _green = '\x1B[32m';
  static const _red = '\x1B[31m';
  static void request(String method, Uri uri) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('$_cyan[API] $method ${uri.origin}$_reset');
  }

  static void response(String method, Uri uri, int status) {
    if (!kDebugMode) {
      return;
    }
    final color = status >= 200 && status < 300 ? _green : _red;
    debugPrint('$color[API] $method ${uri.origin} → HTTP $status$_reset');
  }

  static void error(String method, Uri uri, Object error) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '$_red[API] $method ${uri.origin} → NETWORK ERROR: ${error.runtimeType}$_reset',
    );
  }
}
