import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class AndroidSystemUi {
  const AndroidSystemUi._();

  static const _channel = MethodChannel('com.gurbanov.yaka/system_ui');

  static Future<void> showNavigationBar() async {
    if (!Platform.isAndroid) {
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    await _channel.invokeMethod<void>('showNavigationBar');
  }
}
