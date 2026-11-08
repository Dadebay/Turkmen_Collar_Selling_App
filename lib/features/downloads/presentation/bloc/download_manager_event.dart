part of 'download_manager_bloc.dart';

sealed class DownloadManagerEvent {
  const DownloadManagerEvent();
}

final class DownloadManagerLoadRequested extends DownloadManagerEvent {
  const DownloadManagerLoadRequested();
}

/// Marks an item as actively downloading in the global tracking map without
/// firing the actual download. The caller owns running the file transfer and
/// dispatching progress/finished events.
final class DownloadManagerStartRequested extends DownloadManagerEvent {
  const DownloadManagerStartRequested(this.item);
  final DownloadManagerItem item;
}

/// Triggers the full download flow inside this bloc — adds the item to the
/// active map, runs [DownloadManagerService.downloadItem], emits progress, and
/// removes from active when done. Used by pages that don't own the download
/// loop themselves (e.g. DownloadedPage).
final class DownloadManagerDownloadRequested extends DownloadManagerEvent {
  const DownloadManagerDownloadRequested(this.item);
  final DownloadManagerItem item;
}

final class DownloadManagerProgressUpdated extends DownloadManagerEvent {
  const DownloadManagerProgressUpdated({
    required this.storageKey,
    required this.item,
    required this.progress,
  });
  final String storageKey;
  final DownloadManagerItem item;
  final double progress;
}

final class DownloadManagerFinished extends DownloadManagerEvent {
  const DownloadManagerFinished({required this.storageKey, required this.item});
  final String storageKey;
  final DownloadManagerItem item;
}
