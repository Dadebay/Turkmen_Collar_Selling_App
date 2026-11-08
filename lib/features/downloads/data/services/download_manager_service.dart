// ignore_for_file: always_put_control_body_on_new_line, avoid_slow_async_io
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/download_manager_item.dart';
import '../datasources/downloads_remote_data_source.dart';

/// Thrown by [DownloadManagerService.downloadItem] when a download fails.
/// [message] is either a translation key (e.g. `downloadFailedNetwork`) or raw
/// text, ready to be recorded on the item and shown to the user.
class DownloadException implements Exception {
  const DownloadException(this.message);
  final String message;

  @override
  String toString() => 'DownloadException($message)';
}

class DownloadManagerService {
  DownloadManagerService({
    required this.remote,
    required this.storage,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  static const MethodChannel _usbStorageChannel = MethodChannel(
    'com.example.usb_storage',
  );

  final DownloadsRemoteDataSource remote;
  final LocalStorage storage;
  final Dio _dio;

  List<DownloadManagerItem> loadCachedItems() {
    return storage.downloadCache.map(DownloadManagerItem.fromCache).toList();
  }

  Future<List<DownloadManagerItem>> loadItems() async {
    final result = await remote.getDownloadedProducts();
    if (!result.isSuccess) {
      return loadCachedItems();
    }
    final products = result.dataOrThrow;
    final localStates = storage.downloadStates;
    final items = <DownloadManagerItem>[];

    for (final product in products) {
      final files = product.files ?? [];
      for (final file in files) {
        if (file.id == null || file.id == 0) continue;
        if (file.purchased != true) continue;
        final key = '${product.id ?? 0}:${file.id}';
        items.add(
          DownloadManagerItem.fromBackend(
            product: product,
            file: file,
            localState: localStates[key],
          ),
        );
      }
    }

    if (items.isEmpty) {
      await _saveCachedItems(items);
      return [];
    }

    final localFiles = await _discoverAllLocalFiles();
    final checkedItems = [
      for (final item in items) verifyLocalFiles(item, localFiles: localFiles),
    ];
    await _saveCachedItems(checkedItems);
    return checkedItems;
  }

  DownloadManagerItem verifyLocalFiles(
    DownloadManagerItem item, {
    required Map<String, List<String>> localFiles,
  }) {
    final discoveredFileNames = _fileNamesForItem(item, localFiles);
    if (item.savedFileNames.isEmpty) {
      if (discoveredFileNames.isNotEmpty) {
        return item.copyWith(
          savedFileNames: discoveredFileNames,
          status: DownloadManagerStatus.downloaded,
        );
      }
      return item.copyWith(
        status: item.status == DownloadManagerStatus.failed
            ? DownloadManagerStatus.failed
            : DownloadManagerStatus.notDownloaded,
      );
    }

    final downloaded = item.savedFileNames.every(
      (fileName) => discoveredFileNames.contains(fileName),
    );

    return item.copyWith(
      status: downloaded
          ? DownloadManagerStatus.downloaded
          : DownloadManagerStatus.notDownloaded,
    );
  }

  List<String> _fileNamesForItem(
    DownloadManagerItem item,
    Map<String, List<String>> localFiles,
  ) {
    // Match on-disk folders case-insensitively. Legacy builds wrote `EMB`
    // where the mapper now emits `emb`, and USB/MediaStore paths are
    // effectively case-insensitive (FAT32/exFAT), so an exact-case lookup
    // would silently hide already-downloaded files. Lowercase both sides.
    final candidates = _candidateRelativePaths(item)
        .map((path) => path.toLowerCase())
        .toSet();
    final fileNames = <String>{};
    localFiles.forEach((path, names) {
      if (candidates.contains(path.toLowerCase())) {
        fileNames.addAll(names);
      }
    });
    return fileNames.toList();
  }

  Set<String> _candidateRelativePaths(DownloadManagerItem item) {
    final candidates = <String>{};
    void addPath(String path) {
      final normalizedPath = _normalizeRelativePath(path);
      if (normalizedPath.isEmpty) return;
      candidates.add(normalizedPath);
      candidates.add('YAKA/$normalizedPath');
      if (normalizedPath.toUpperCase().startsWith('YAKA/')) {
        candidates.add(normalizedPath.substring(5));
      }
    }

    addPath(item.relativePath);
    return candidates;
  }

  String _normalizeRelativePath(String path) {
    return path
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .join('/');
  }

  Future<DownloadManagerItem> downloadItem({
    required DownloadManagerItem item,
    required void Function(double progress) onProgress,
  }) async {
    final requestedAt = DateTime.now().toIso8601String();
    final urlsResult = await remote.requestDownloadUrls(fileId: item.fileId);
    if (!urlsResult.isSuccess) {
      throw DownloadException(_failureMessageKey(urlsResult.failureOrThrow));
    }
    final urls = urlsResult.dataOrThrow;
    if (urls.isEmpty) {
      throw const DownloadException('downloadFailedNoFiles');
    }

    try {
      if (Platform.isAndroid) {
        await _ensureSourceFolderAccess();
      } else {
        await _ensureIosDirectory(item);
      }

      final expectedFileNames = urls
          .map((url) => _cleanFileName(_fileNameFromUrl(url)))
          .toList();
      await save(
        item.copyWith(
          savedFileNames: expectedFileNames,
          requestedAt: requestedAt,
          status: DownloadManagerStatus.downloading,
        ),
      );

      final savedFileNames = <String>[];
      for (var i = 0; i < urls.length; i++) {
        final url = urls[i];
        final fileName = expectedFileNames[i];

        await _downloadSingleFile(
          url: url,
          fileName: fileName,
          item: item,
          fileIndex: i,
          fileCount: urls.length,
          onProgress: onProgress,
        );
        savedFileNames.add(fileName);
        onProgress((i + 1) / urls.length);
      }

      final downloadedItem = item.copyWith(
        savedFileNames: savedFileNames,
        requestedAt: requestedAt,
        status: DownloadManagerStatus.downloaded,
        progress: 1,
        errorMessage: '',
      );
      await save(downloadedItem);
      return downloadedItem;
    } on DownloadException {
      rethrow;
    } catch (error) {
      throw DownloadException(_transferMessageKey(error));
    }
  }

  /// Maps a URL-request [AppFailure] to a localized snackbar key.
  String _failureMessageKey(AppFailure failure) {
    return switch (failure) {
      NetworkFailure() => 'downloadFailedNetwork',
      AuthFailure() => 'downloadFailedAuth',
      ServerFailure() => 'downloadFailedServer',
      _ => 'downloadFailedSubtitle',
    };
  }

  /// Maps an error thrown while transferring/saving files to a localized key.
  /// Falls back to the raw message so an unexpected reason is still recorded.
  String _transferMessageKey(Object error) {
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'downloadFailedTimeout',
        DioExceptionType.connectionError => 'downloadFailedNetwork',
        DioExceptionType.badResponse => 'downloadFailedServer',
        _ => 'downloadFailedSubtitle',
      };
    }
    // Native storage bridge (SAF access denied, disk full, copy failure).
    if (error is PlatformException) {
      return 'downloadFailedStorage';
    }
    return error.toString();
  }

  Future<void> save(DownloadManagerItem item) async {
    final states = storage.downloadStates;
    final previousState = states[item.storageKey];
    final previousFileNames =
        (previousState?['savedFileNames'] as List?)
            ?.whereType<String>()
            .toList() ??
        <String>[];
    if (item.savedFileNames.isEmpty && previousFileNames.isNotEmpty) {
      states[item.storageKey] = item
          .copyWith(savedFileNames: previousFileNames)
          .toLocalState();
      await storage.saveDownloadStates(states);
      await _mergeCachedItem(item.copyWith(savedFileNames: previousFileNames));
      return;
    }
    if (_shouldPersistLocalState(item)) {
      states[item.storageKey] = item.toLocalState();
    } else {
      states.remove(item.storageKey);
    }
    await storage.saveDownloadStates(states);
    await _mergeCachedItem(item);
  }

  /// One-time legacy-cache cleanup. Deletes the rebuildable `YAKA` source
  /// cache (Android: `Download/YAKA` via the native bridge; iOS: the
  /// app-documents `YAKA` folder) and resets persisted manager state so
  /// statuses self-heal to `notDownloaded`. Files re-download lazily on demand.
  /// On Android a [PlatformException] propagates so the caller can leave its
  /// run-once flag unset and retry on the next launch.
  Future<void> clearAllSourceFiles() async {
    if (Platform.isAndroid) {
      await _usbStorageChannel.invokeMethod<dynamic>('clearSourceFiles');
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final yakaDirectory = Directory('${directory.path}/YAKA');
      if (await yakaDirectory.exists()) {
        await yakaDirectory.delete(recursive: true);
      }
    }
    await storage.saveDownloadStates(<String, Map<String, dynamic>>{});
    await storage.saveDownloadCache(<Map<String, dynamic>>[]);
  }

  Future<Map<String, List<String>>> _discoverAllLocalFiles() {
    return Platform.isAndroid
        ? _androidFileNamesByPath()
        : _iosFileNamesByPath();
  }

  Future<Map<String, List<String>>> _androidFileNamesByPath() async {
    try {
      final files = await _usbStorageChannel.invokeMethod<List<dynamic>>(
        'listSourceFiles',
      );
      if (files == null) return {};

      final filesByPath = <String, List<String>>{};
      for (final file in files.whereType<Map>()) {
        final relativePath = file['relativePath']?.toString() ?? '';
        final name = file['name']?.toString() ?? '';
        final normalizedPath = _normalizeRelativePath(relativePath);
        if (normalizedPath.isEmpty || name.isEmpty) continue;
        filesByPath.putIfAbsent(normalizedPath, () => <String>[]).add(name);
      }
      return filesByPath;
    } on PlatformException {
      return {};
    }
  }

  Future<Map<String, List<String>>> _iosFileNamesByPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final yakaDirectory = Directory('${directory.path}/YAKA');
    if (!await yakaDirectory.exists()) return {};

    final filesByPath = <String, List<String>>{};
    await for (final entity in yakaDirectory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.parent.path
            .replaceFirst('${yakaDirectory.path}${Platform.pathSeparator}', '')
            .replaceAll(Platform.pathSeparator, '/');
        final normalizedPath = _normalizeRelativePath(relativePath);
        if (normalizedPath.isEmpty) continue;
        filesByPath
            .putIfAbsent(normalizedPath, () => <String>[])
            .add(entity.uri.pathSegments.last);
      }
    }
    return filesByPath;
  }

  /// Makes sure `Download/YAKA` is writable before a download starts. On
  /// Android 10+ that never needs a permission (files are the app's own
  /// MediaStore rows); below Q the bridge prompts for the storage grant the
  /// first time and reports a denial, so the download stops with a message the
  /// user can act on instead of an opaque IO failure mid-transfer.
  Future<void> _ensureSourceFolderAccess() async {
    if (!Platform.isAndroid) return;
    final hasAccess =
        await _usbStorageChannel.invokeMethod<bool>('hasSourceFolderAccess') ??
        false;
    if (hasAccess) return;
    try {
      await _usbStorageChannel.invokeMethod<String>(
        'requestSourceFolderAccess',
      );
    } on PlatformException catch (error) {
      throw DownloadException(
        error.code == 'storage_permission_permanently_denied'
            ? 'downloadFailedStoragePermissionSettings'
            : 'downloadFailedStoragePermission',
      );
    }
  }

  Future<void> _ensureIosDirectory(DownloadManagerItem item) async {
    final directory = await getApplicationDocumentsDirectory();
    final saveDirectory = Directory(
      '${directory.path}/${item.iosRelativePath}',
    );
    if (!await saveDirectory.exists()) {
      await saveDirectory.create(recursive: true);
    }
  }

  Future<void> _downloadSingleFile({
    required String url,
    required String fileName,
    required DownloadManagerItem item,
    required int fileIndex,
    required int fileCount,
    required void Function(double progress) onProgress,
  }) async {
    if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final savePath = '${directory.path}/${item.iosRelativePath}/$fileName';
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          final currentFileProgress = received / total;
          onProgress((fileIndex + currentFileProgress) / fileCount);
        },
      );
      return;
    }

    final tempDirectory = await getTemporaryDirectory();
    final tempSaveDirectory = Directory(
      '${tempDirectory.path}/yaka_manager_downloads',
    );
    if (!await tempSaveDirectory.exists()) {
      await tempSaveDirectory.create(recursive: true);
    }
    final tempPath =
        '${tempSaveDirectory.path}/${DateTime.now().microsecondsSinceEpoch}_$fileName';

    try {
      await _dio.download(
        url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          final currentFileProgress = received / total;
          onProgress((fileIndex + currentFileProgress) / fileCount);
        },
      );
      await _usbStorageChannel.invokeMethod<String>('copyFileToSource', {
        'filePath': tempPath,
        'relativePath': item.relativePath,
        'fileName': fileName,
      });
    } finally {
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  String _fileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      // pathSegments are already percent-decoded by Uri, so return as-is.
      // Decoding again corrupts (or throws on) non-Latin names.
      return uri.pathSegments.last;
    }
    final rawName = url.split('/').last;
    try {
      return Uri.decodeComponent(rawName);
    } on FormatException {
      return rawName;
    }
  }

  String _cleanFileName(String fileName) {
    var cleanName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final parts = cleanName.split('.');
    if (parts.length > 2 && parts.last == parts[parts.length - 2]) {
      cleanName = parts.sublist(0, parts.length - 1).join('.');
    }
    return cleanName;
  }

  bool _shouldPersistLocalState(DownloadManagerItem item) {
    return item.status == DownloadManagerStatus.downloading ||
        item.status == DownloadManagerStatus.failed ||
        item.savedFileNames.isNotEmpty;
  }

  Future<void> _saveCachedItems(List<DownloadManagerItem> items) {
    return storage.saveDownloadCache(
      items.map((item) => item.toCacheJson()).toList(),
    );
  }

  Future<void> _mergeCachedItem(DownloadManagerItem updatedItem) async {
    final cachedItems = loadCachedItems();
    var found = false;
    final mergedItems = cachedItems.map((item) {
      if (item.storageKey != updatedItem.storageKey) return item;
      found = true;
      return updatedItem;
    }).toList();

    if (!found) mergedItems.add(updatedItem);
    await _saveCachedItems(mergedItems);
  }
}
