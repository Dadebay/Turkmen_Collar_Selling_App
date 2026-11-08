// ignore_for_file: avoid_slow_async_io
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/download_manager_item.dart';

/// Exports already-downloaded files off the device on iOS, where there is no
/// USB copy path. It hands the files to the system share sheet, whose
/// "Save to Files" action lets the user pick any destination — including a
/// connected USB drive or SD card (Files app, iOS 13+) or iCloud Drive.
class FileExportService {
  const FileExportService();

  /// Resolves the on-disk paths for [item]'s downloaded files inside the app
  /// Documents directory (`Documents/YAKA/...`), keeping only those that
  /// actually exist on disk.
  Future<List<String>> resolveLocalFilePaths(DownloadManagerItem item) async {
    final directory = await getApplicationDocumentsDirectory();
    final base = '${directory.path}/${item.iosRelativePath}';
    final paths = <String>[];
    for (final name in item.savedFileNames) {
      final file = File('$base/$name');
      if (await file.exists()) {
        paths.add(file.path);
      }
    }
    return paths;
  }

  /// Opens the share sheet so the user can export [item]'s files to a
  /// destination of their choice (USB drive, iCloud, another app, ...).
  /// Returns `false` when no downloaded file is present to export.
  ///
  /// [sharePositionOrigin] is the anchor rect (in global coordinates) the
  /// share popover points at. It is REQUIRED on iPad — without it the sheet
  /// silently fails to present — and ignored on iPhone.
  Future<bool> exportItem(
    DownloadManagerItem item, {
    Rect? sharePositionOrigin,
  }) async {
    final paths = await resolveLocalFilePaths(item);
    debugPrint(
      '📤 export "${item.productName}" — '
      'saved=${item.savedFileNames.length}, resolved=${paths.length}, '
      'base=${item.iosRelativePath}',
    );
    if (paths.isEmpty) {
      return false;
    }
    await Share.shareXFiles(
      paths.map((path) => XFile(path)).toList(),
      subject: item.productName,
      sharePositionOrigin: sharePositionOrigin,
    );
    return true;
  }
}
