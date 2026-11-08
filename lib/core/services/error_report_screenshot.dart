import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Captures the visible app, including its snackbar, before the report dialog
/// replaces the screen. A logical-pixel PNG keeps chat uploads small.
class ErrorReportScreenshot {
  ErrorReportScreenshot._();

  static final GlobalKey boundaryKey = GlobalKey();

  static Future<File?> capture() async {
    try {
      var boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        return null;
      }

      for (
        var attempt = 0;
        attempt < 3 && boundary!.debugNeedsPaint;
        attempt++
      ) {
        WidgetsBinding.instance.scheduleFrame();
        await WidgetsBinding.instance.endOfFrame;
        boundary =
            boundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
      }
      if (boundary == null || boundary.debugNeedsPaint) {
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) {
          return null;
        }
        final bytes = data.buffer.asUint8List();
        if (bytes.length > 3 * 1024 * 1024) {
          return null;
        }
        final directory = await getTemporaryDirectory();
        final file = File(
          '${directory.path}/yaka_error_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        file.writeAsBytesSync(bytes, flush: true);
        return file;
      } finally {
        image.dispose();
      }
    } catch (error) {
      debugPrint('[ErrorReport] Screenshot capture failed: $error');
      return null;
    }
  }
}
