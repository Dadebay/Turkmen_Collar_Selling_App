import 'package:flutter/services.dart';

import '../../domain/entities/local_download_file.dart';

class UsbStorageService {
  UsbStorageService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.example.usb_storage');

  final MethodChannel _channel;

  MethodChannel get channel => _channel;

  Future<String?> getUsbPath() async {
    try {
      return await _channel.invokeMethod<String>('getUSBPath');
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasUsbFolderAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasUsbFolderAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> requestUsbFolderAccess() async {
    return _channel.invokeMethod<String>('requestUsbFolderAccess');
  }

  /// A user-readable label for the currently selected USB folder (e.g.
  /// "USB drive/MyCollars"), or null when no folder has been selected.
  Future<String?> getUsbFolderName() async {
    try {
      return await _channel.invokeMethod<String>('getUsbFolderName');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, List<LocalDownloadFile>>> listSourceFiles() async {
    try {
      final raw =
          await _channel.invokeMethod<List<dynamic>>('listSourceFiles') ?? [];
      final filesByPath = <String, List<LocalDownloadFile>>{};
      for (final entry in raw.whereType<Map>()) {
        final file = LocalDownloadFile.fromMap(entry);
        if (file.uri.isEmpty ||
            file.name.isEmpty ||
            file.relativePath.isEmpty) {
          continue;
        }
        filesByPath
            .putIfAbsent(file.relativePath, () => <LocalDownloadFile>[])
            .add(file);
      }
      return filesByPath;
    } catch (_) {
      return <String, List<LocalDownloadFile>>{};
    }
  }

  /// Copies a source document onto the USB drive. When [expectedSize] is
  /// provided and a same-sized file already exists at the destination, the
  /// native side skips the copy and returns [usbCopySkipped]; otherwise it
  /// returns the written file's URI.
  Future<String?> copyDocumentToUsb({
    required String documentUri,
    required String relativePath,
    required String fileName,
    int? expectedSize,
  }) async {
    return _channel.invokeMethod<String>('copyDocumentToUsb', <String, dynamic>{
      'documentUri': documentUri,
      'relativePath': relativePath,
      'fileName': fileName,
      if (expectedSize != null) 'expectedSize': expectedSize,
    });
  }
}

/// Sentinel returned by [UsbStorageService.copyDocumentToUsb] when the file was
/// already present on the USB and did not need to be copied again.
const String usbCopySkipped = 'skipped';
