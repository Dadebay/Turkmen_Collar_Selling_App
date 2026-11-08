// ignore_for_file: always_put_control_body_on_new_line
part of 'download_manager_bloc.dart';

class DownloadManagerState {
  const DownloadManagerState({required this.active, required this.allItems});

  final Map<String, DownloadManagerItem> active;
  final List<DownloadManagerItem> allItems;

  int get activeCount => active.length;
  bool get hasActiveDownloads => active.isNotEmpty;

  String get statusText {
    if (active.isEmpty) return '';
    if (active.length == 1) {
      final item = active.values.first;
      final progress = item.progress > 0
          ? ' ${(item.progress * 100).clamp(0, 100).round()}%'
          : '';
      return '${item.productName}$progress';
    }
    return '${active.length} ${'activeDownloads'.tr}';
  }

  double? get aggregateProgress {
    if (active.isEmpty) return null;
    final total = active.values.fold<double>(
      0,
      (sum, item) => sum + item.progress.clamp(0, 1).toDouble(),
    );
    return total / active.length;
  }

  DownloadManagerState copyWith({
    Map<String, DownloadManagerItem>? active,
    List<DownloadManagerItem>? allItems,
  }) {
    return DownloadManagerState(
      active: active ?? this.active,
      allItems: allItems ?? this.allItems,
    );
  }
}
