// ignore_for_file: always_put_control_body_on_new_line
import 'dart:io';

import 'package:bloc/bloc.dart';

import '../../../../../core/l10n/app_translations.dart';
import '../../../data/services/download_manager_service.dart';
import '../../../data/services/usb_storage_service.dart';
import '../../../domain/entities/download_manager_item.dart';
import '../../../domain/entities/local_download_file.dart';
import '../download_manager_bloc.dart';

part 'usb_transfer_event.dart';
part 'usb_transfer_state.dart';

class UsbTransferBloc extends Bloc<UsbTransferEvent, UsbTransferState> {
  UsbTransferBloc({
    required this.usbStorage,
    required this.downloadManager,
    required this.downloadManagerBloc,
  }) : super(const UsbTransferState()) {
    on<UsbTransferStarted>(_onStarted);
    on<UsbTransferRefreshRequested>(_onRefresh);
    on<UsbFolderRequested>(_onFolderRequested);
    on<UsbVersionToggled>(_onVersionToggled);
    on<UsbAllVersionsToggled>(_onAllVersionsToggled);
    on<UsbSelectionCleared>(_onSelectionCleared);
    on<UsbProductOpened>(_onProductOpened);
    on<UsbProductClosed>(_onProductClosed);
    on<UsbTransferTriggered>(_onTransferTriggered);
  }

  final UsbStorageService usbStorage;
  final DownloadManagerService downloadManager;
  final DownloadManagerBloc downloadManagerBloc;

  /// USB transfer is backed by a native bridge on both Android (SAF) and iOS
  /// (document-picker folder + security-scoped bookmark).
  bool get _supportsUsbTransfer => Platform.isAndroid || Platform.isIOS;

  Future<void> _onStarted(
    UsbTransferStarted event,
    Emitter<UsbTransferState> emit,
  ) async {
    if (!_supportsUsbTransfer) {
      emit(state.copyWith(loading: false, androidOnly: true));
      return;
    }
    emit(state.copyWith(loading: true));
    await _refreshUsbStatus(emit);
    await _loadItems(emit);
  }

  Future<void> _onRefresh(
    UsbTransferRefreshRequested event,
    Emitter<UsbTransferState> emit,
  ) async {
    if (!_supportsUsbTransfer) return;
    await _refreshUsbStatus(emit);
    await _loadItems(emit, showLoader: false);
  }

  Future<void> _onFolderRequested(
    UsbFolderRequested event,
    Emitter<UsbTransferState> emit,
  ) async {
    if (!_supportsUsbTransfer || state.isTransferring) return;
    try {
      await _refreshUsbStatus(emit);
      await usbStorage.requestUsbFolderAccess();
      await _refreshUsbStatus(emit);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'usbFolderAccessRequired'));
    }
  }

  void _onProductOpened(
    UsbProductOpened event,
    Emitter<UsbTransferState> emit,
  ) {
    if (!state.hasUsbAccess) {
      emit(state.copyWith(errorMessage: 'usbNotFoundStatus'));
      return;
    }
    emit(state.copyWith(activeProductId: event.productId));
  }

  void _onProductClosed(
    UsbProductClosed event,
    Emitter<UsbTransferState> emit,
  ) {
    emit(state.clearActiveProduct());
  }

  void _onVersionToggled(
    UsbVersionToggled event,
    Emitter<UsbTransferState> emit,
  ) {
    if (!state.hasUsbAccess) {
      emit(state.copyWith(errorMessage: 'usbNotFoundStatus'));
      return;
    }
    final nextSelected = <int, Set<String>>{
      for (final entry in state.selectedVersions.entries)
        entry.key: Set<String>.from(entry.value),
    };
    final current = nextSelected.putIfAbsent(event.productId, () => <String>{});
    if (current.contains(event.machineName)) {
      current.remove(event.machineName);
      if (current.isEmpty) nextSelected.remove(event.productId);
    } else {
      current.add(event.machineName);
    }
    emit(state.copyWith(selectedVersions: nextSelected));
  }

  void _onAllVersionsToggled(
    UsbAllVersionsToggled event,
    Emitter<UsbTransferState> emit,
  ) {
    if (!state.hasUsbAccess) {
      emit(state.copyWith(errorMessage: 'usbNotFoundStatus'));
      return;
    }
    final available = state.availableVersions[event.productId] ?? const [];
    if (available.isEmpty) return;

    final nextSelected = <int, Set<String>>{
      for (final entry in state.selectedVersions.entries)
        entry.key: Set<String>.from(entry.value),
    };
    final current = nextSelected[event.productId] ?? const <String>{};
    final allSelected =
        current.length >= available.length && available.every(current.contains);
    if (allSelected) {
      nextSelected.remove(event.productId);
    } else {
      nextSelected[event.productId] = available.toSet();
    }
    emit(state.copyWith(selectedVersions: nextSelected));
  }

  void _onSelectionCleared(
    UsbSelectionCleared event,
    Emitter<UsbTransferState> emit,
  ) {
    emit(state.copyWith(selectedVersions: const <int, Set<String>>{}));
  }

  Future<void> _onTransferTriggered(
    UsbTransferTriggered event,
    Emitter<UsbTransferState> emit,
  ) async {
    if (state.selectedVersions.isEmpty) {
      emit(state.copyWith(errorMessage: 'copyUsbSelectAtLeastOneFile'));
      return;
    }

    // Ensure USB folder access before transferring.
    if (!state.hasUsbAccess) {
      await _refreshUsbStatus(emit);
      if (!state.hasUsbAccess) {
        emit(state.copyWith(errorMessage: 'copyUsbStorageNotSelected'));
        return;
      }
    }

    final selectedItems = _itemsForSelection();
    emit(
      state.copyWith(
        isTransferring: true,
        copiedFiles: 0,
        skippedFiles: 0,
        failedFiles: 0,
        processedTransferItems: 0,
        totalTransferItems: selectedItems.length,
        transferComplete: false,
      ),
    );

    var localFiles = state.localFilesByPath;

    // Each model (item) is processed independently: a failure copying or
    // downloading one does not abort the rest, so the user still gets whatever
    // could be transferred plus an honest summary of what didn't.
    for (final item in selectedItems) {
      try {
        var copyItem = item;
        if (copyItem.status != DownloadManagerStatus.downloaded) {
          final downloaded = await _downloadItem(copyItem, emit);
          if (downloaded == null) {
            emit(
              state.copyWith(
                failedFiles: state.failedFiles + 1,
                processedTransferItems: state.processedTransferItems + 1,
              ),
            );
            continue;
          }
          copyItem = downloaded;
          localFiles = await usbStorage.listSourceFiles();
          emit(state.copyWith(localFilesByPath: localFiles));
        }

        final files = _filesForPath(localFiles, copyItem.relativePath);
        for (final file in files) {
          final result = await usbStorage.copyDocumentToUsb(
            documentUri: file.uri,
            relativePath: copyItem.relativePath,
            fileName: file.name,
            expectedSize: file.size,
          );
          if (result == usbCopySkipped) {
            emit(state.copyWith(skippedFiles: state.skippedFiles + 1));
          } else {
            emit(state.copyWith(copiedFiles: state.copiedFiles + 1));
          }
        }
        emit(
          state.copyWith(
            processedTransferItems: state.processedTransferItems + 1,
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(
            failedFiles: state.failedFiles + 1,
            processedTransferItems: state.processedTransferItems + 1,
          ),
        );
      }
    }

    // Stay green as long as anything made it across (the summary still names
    // the failed count); only a total failure surfaces as an error.
    final anySuccess = state.copiedFiles > 0 || state.skippedFiles > 0;
    final summary = _transferSummary();
    emit(
      state.copyWith(
        selectedVersions: const <int, Set<String>>{},
        isTransferring: false,
        transferComplete: true,
        successMessage: anySuccess ? summary : null,
        errorMessage: anySuccess ? null : summary,
      ),
    );
    await _loadItems(emit, showLoader: false);
  }

  /// Builds a human-readable, already-localised summary of the last transfer,
  /// e.g. "12 copied · 3 already on USB · 1 failed" (omitting zero parts).
  String _transferSummary() {
    final parts = <String>[
      'copyUsbCopiedCount'.trParams({'count': '${state.copiedFiles}'}),
    ];
    if (state.skippedFiles > 0) {
      parts.add(
        'copyUsbSkippedCount'.trParams({'count': '${state.skippedFiles}'}),
      );
    }
    if (state.failedFiles > 0) {
      parts.add(
        'copyUsbFailedCount'.trParams({'count': '${state.failedFiles}'}),
      );
    }
    return parts.join(' · ');
  }

  Future<DownloadManagerItem?> _downloadItem(
    DownloadManagerItem item,
    Emitter<UsbTransferState> emit,
  ) async {
    final downloadingItem = item.copyWith(
      requestedAt: DateTime.now().toIso8601String(),
      status: DownloadManagerStatus.downloading,
      progress: 0,
    );
    downloadManagerBloc.add(DownloadManagerStartRequested(downloadingItem));
    await downloadManager.save(downloadingItem);
    _replaceItem(downloadingItem, emit);

    try {
      final downloaded = await downloadManager.downloadItem(
        item: downloadingItem,
        onProgress: (progress) {
          downloadManagerBloc.add(
            DownloadManagerProgressUpdated(
              storageKey: downloadingItem.storageKey,
              item: downloadingItem,
              progress: progress,
            ),
          );
          _replaceItem(
            downloadingItem.copyWith(
              status: DownloadManagerStatus.downloading,
              progress: progress,
            ),
            emit,
          );
        },
      );
      downloadManagerBloc.add(
        DownloadManagerFinished(
          storageKey: downloaded.storageKey,
          item: downloaded,
        ),
      );
      _replaceItem(downloaded, emit);
      return downloaded;
    } catch (_) {
      final failed = downloadingItem.copyWith(
        status: DownloadManagerStatus.failed,
        progress: 0,
      );
      downloadManagerBloc.add(
        DownloadManagerFinished(storageKey: failed.storageKey, item: failed),
      );
      await downloadManager.save(failed);
      _replaceItem(failed, emit);
      return null;
    }
  }

  void _replaceItem(
    DownloadManagerItem updated,
    Emitter<UsbTransferState> emit,
  ) {
    final next = state.items
        .map((i) => i.storageKey == updated.storageKey ? updated : i)
        .toList();
    emit(state.copyWith(items: next));
  }

  /// Looks up source files case-insensitively: on-disk folders may use the
  /// legacy `EMB` casing while the mapper now emits `emb`, and USB filesystems
  /// are case-insensitive, so an exact-key lookup would miss the files.
  List<LocalDownloadFile> _filesForPath(
    Map<String, List<LocalDownloadFile>> localFiles,
    String relativePath,
  ) {
    final target = relativePath.toLowerCase();
    for (final entry in localFiles.entries) {
      if (entry.key.toLowerCase() == target) return entry.value;
    }
    return const [];
  }

  List<DownloadManagerItem> _itemsForSelection() {
    final out = <DownloadManagerItem>[];
    for (final entry in state.selectedVersions.entries) {
      final productId = entry.key;
      final machineNames = entry.value;
      for (final item in state.items) {
        if (item.productId != productId) continue;
        if (machineNames.contains(item.machineName.toUpperCase()) ||
            machineNames.contains(item.machineName)) {
          out.add(item);
        }
      }
    }
    return out;
  }

  Future<void> _refreshUsbStatus(Emitter<UsbTransferState> emit) async {
    if (!_supportsUsbTransfer) return;
    final usbPath = await usbStorage.getUsbPath();
    final hasFolderAccess = await usbStorage.hasUsbFolderAccess();
    final folderName = hasFolderAccess
        ? await usbStorage.getUsbFolderName()
        : null;
    emit(
      state.copyWith(
        usbConnected:
            (usbPath != null && usbPath.isNotEmpty) || hasFolderAccess,
        usbFolderSelected: hasFolderAccess,
        usbFolderName: folderName,
      ),
    );
  }

  Future<void> _loadItems(
    Emitter<UsbTransferState> emit, {
    bool showLoader = true,
  }) async {
    if (showLoader) emit(state.copyWith(loading: true));
    try {
      final items = await downloadManager.loadItems();
      final localFiles = await usbStorage.listSourceFiles();
      final merged = items.map((item) {
        return downloadManagerBloc.state.active[item.storageKey] ?? item;
      }).toList();
      emit(
        state.copyWith(
          items: merged,
          localFilesByPath: localFiles,
          loading: false,
          availableVersions: _deriveAvailableVersions(merged),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(loading: false, errorMessage: 'copyUsbReadSourceError'),
      );
    }
  }

  Map<int, List<String>> _deriveAvailableVersions(
    List<DownloadManagerItem> items,
  ) {
    final byProduct = <int, List<String>>{};
    for (final item in items) {
      final machine = item.machineName.toUpperCase();
      if (machine.isEmpty) continue;
      final list = byProduct.putIfAbsent(item.productId, () => <String>[]);
      if (!list.contains(machine)) list.add(machine);
    }
    return byProduct;
  }
}
