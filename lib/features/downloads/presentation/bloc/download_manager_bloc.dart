// ignore_for_file: always_put_control_body_on_new_line
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../data/services/download_manager_service.dart';
import '../../domain/entities/download_manager_item.dart';

part 'download_manager_event.dart';
part 'download_manager_state.dart';

class DownloadManagerBloc
    extends Bloc<DownloadManagerEvent, DownloadManagerState> {
  DownloadManagerBloc({required this.service})
    : super(
        DownloadManagerState(
          active: const {},
          allItems: service.loadCachedItems(),
        ),
      ) {
    on<DownloadManagerLoadRequested>(_onLoadRequested);
    on<DownloadManagerStartRequested>(_onStartRequested);
    on<DownloadManagerDownloadRequested>(_onDownloadRequested);
    on<DownloadManagerProgressUpdated>(_onProgressUpdated);
    on<DownloadManagerFinished>(_onFinished);
  }

  final DownloadManagerService service;

  Future<void> _onLoadRequested(
    DownloadManagerLoadRequested event,
    Emitter<DownloadManagerState> emit,
  ) async {
    final items = await service.loadItems();
    emit(state.copyWith(allItems: items));
  }

  /// Marks an item as "actively downloading" in the global map so the progress
  /// ribbon and other listeners see it. The caller (e.g. UsbTransferBloc) owns
  /// the actual file download via [DownloadManagerService.downloadItem] and is
  /// responsible for dispatching [DownloadManagerProgressUpdated] /
  /// [DownloadManagerFinished] events as the download progresses.
  void _onStartRequested(
    DownloadManagerStartRequested event,
    Emitter<DownloadManagerState> emit,
  ) {
    final startItem = event.item.copyWith(
      status: DownloadManagerStatus.downloading,
      progress: 0,
    );
    final nextActive = Map<String, DownloadManagerItem>.from(state.active)
      ..[startItem.storageKey] = startItem;
    emit(state.copyWith(active: nextActive));
  }

  /// Runs the full download flow: adds the item to the active map, calls the
  /// service, emits progress events, and removes from active on completion or
  /// failure.
  Future<void> _onDownloadRequested(
    DownloadManagerDownloadRequested event,
    Emitter<DownloadManagerState> emit,
  ) async {
    final startItem = event.item.copyWith(
      status: DownloadManagerStatus.downloading,
      progress: 0,
    );
    final nextActive = Map<String, DownloadManagerItem>.from(state.active)
      ..[startItem.storageKey] = startItem;
    emit(state.copyWith(active: nextActive));

    try {
      final downloaded = await service.downloadItem(
        item: startItem,
        onProgress: (progress) => add(
          DownloadManagerProgressUpdated(
            storageKey: startItem.storageKey,
            item: startItem,
            progress: progress,
          ),
        ),
      );
      add(
        DownloadManagerFinished(
          storageKey: downloaded.storageKey,
          item: downloaded,
        ),
      );
    } catch (error) {
      final failedItem = startItem.copyWith(
        status: DownloadManagerStatus.failed,
        progress: 0,
        errorMessage: error is DownloadException
            ? error.message
            : 'downloadFailedSubtitle',
      );
      await service.save(failedItem);
      add(
        DownloadManagerFinished(
          storageKey: failedItem.storageKey,
          item: failedItem,
        ),
      );
    }
  }

  void _onProgressUpdated(
    DownloadManagerProgressUpdated event,
    Emitter<DownloadManagerState> emit,
  ) {
    final updated = event.item.copyWith(
      status: DownloadManagerStatus.downloading,
      progress: event.progress.clamp(0, 1).toDouble(),
    );
    final nextActive = Map<String, DownloadManagerItem>.from(state.active)
      ..[event.storageKey] = updated;
    emit(state.copyWith(active: nextActive));
  }

  void _onFinished(
    DownloadManagerFinished event,
    Emitter<DownloadManagerState> emit,
  ) {
    final nextActive = Map<String, DownloadManagerItem>.from(state.active)
      ..remove(event.storageKey);
    final nextAllItems = state.allItems.map((existing) {
      if (existing.storageKey == event.storageKey) return event.item;
      return existing;
    }).toList();
    final hasInList = nextAllItems.any((i) => i.storageKey == event.storageKey);
    if (!hasInList) nextAllItems.add(event.item);
    emit(state.copyWith(active: nextActive, allItems: nextAllItems));
  }
}
