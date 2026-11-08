import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/no_image.dart';
import '../../../../injection_container.dart';
import '../../../downloads/data/services/file_export_service.dart';
import '../../../downloads/domain/entities/download_manager_item.dart';
import '../../../downloads/presentation/bloc/download_manager_bloc.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../../../core/icons/app_icon.dart';

enum _DownloadStatusFilter {
  all,
  downloaded,
  downloading,
  failed,
  notDownloaded,
}

class DownloadedPage extends StatefulWidget {
  const DownloadedPage({super.key});

  @override
  State<DownloadedPage> createState() => _DownloadedPageState();
}

class _DownloadedPageState extends State<DownloadedPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _DownloadStatusFilter _filter = _DownloadStatusFilter.all;

  @override
  void initState() {
    super.initState();
    // Fetch the latest item list from the backend; the bloc starts with cached
    // items so the list shows something immediately.
    context.read<DownloadManagerBloc>().add(
      const DownloadManagerLoadRequested(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _download(DownloadManagerItem item) {
    final isAlreadyDownloading = context
        .read<DownloadManagerBloc>()
        .state
        .active
        .containsKey(item.storageKey);
    if (item.status == DownloadManagerStatus.downloading ||
        isAlreadyDownloading) {
      return;
    }
    context.read<DownloadManagerBloc>().add(
      DownloadManagerDownloadRequested(item),
    );
  }

  /// iOS has no USB copy path, so downloaded files are exported through the
  /// system share sheet ("Save to Files" → USB drive / iCloud / other apps).
  Future<void> _export(DownloadManagerItem item) async {
    // The share popover needs an anchor rect on iPad; use the page's bounds.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    try {
      final exported = await sl<FileExportService>().exportItem(
        item,
        sharePositionOrigin: origin,
      );
      if (!exported && mounted) {
        showSnackBar(context, 'exportNoFiles', '', ColorConstants.redColor);
      }
    } catch (e) {
      debugPrint('📤 export failed: $e');
      if (mounted) {
        showSnackBar(context, 'exportNoFiles', '', ColorConstants.redColor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'downloaded', showBackButton: true),
      body: BlocBuilder<DownloadManagerBloc, DownloadManagerState>(
        builder: (context, state) {
          final items = _mergeActive(state);
          if (items.isEmpty) {
            return const EmptyState(
              name: 'emptyData',
              type: EmptyStateType.text,
            );
          }
          final visible = _visibleItems(items);
          return RefreshIndicator(
            color: ColorConstants.primaryColor,
            onRefresh: () async {
              context.read<DownloadManagerBloc>().add(
                const DownloadManagerLoadRequested(),
              );
            },
            // A single CustomScrollView drives one viewport. The tile list is a
            // SliverList so only on-screen tiles are built/recycled — the list
            // stays smooth no matter how many items there are. (The previous
            // shrink-wrapped inner ListView built every tile up front, which
            // froze the UI thread on large lists.)
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: context.padding.normal,
                  sliver: SliverToBoxAdapter(
                    child: _SearchAndFilterBar(
                      controller: _searchController,
                      filter: _filter,
                      onSearchChanged: (value) {
                        setState(() => _query = value.trim().toLowerCase());
                      },
                      onFilterChanged: (filter) {
                        setState(() => _filter = filter);
                      },
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  SliverPadding(
                    padding: context.padding.verticalHigh,
                    sliver: const SliverToBoxAdapter(
                      child: EmptyState(
                        name: 'emptyData',
                        type: EmptyStateType.text,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: context.padding.horizontalNormal.copyWith(
                      bottom: 24,
                    ),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        return _DownloadManagerTile(
                          item: item,
                          onTap: () => context.push(
                            AppRoutes.productDetailPath(item.productId),
                            extra: _itemToProduct(item),
                          ),
                          onStatusPressed: () => _download(item),
                          onExportPressed: () => _export(item),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Overlays the global "active downloads" map onto the cached/loaded list so
  /// the tile always reflects the latest progress.
  List<DownloadManagerItem> _mergeActive(DownloadManagerState state) {
    return state.allItems.map((item) {
      return state.active[item.storageKey] ?? item;
    }).toList();
  }

  List<DownloadManagerItem> _visibleItems(List<DownloadManagerItem> items) {
    return items.where((item) {
      final matchesSearch =
          _query.isEmpty ||
          item.productName.toLowerCase().contains(_query) ||
          item.machineName.toLowerCase().contains(_query);
      final matchesFilter = switch (_filter) {
        _DownloadStatusFilter.all => true,
        _DownloadStatusFilter.downloaded =>
          item.status == DownloadManagerStatus.downloaded,
        _DownloadStatusFilter.downloading =>
          item.status == DownloadManagerStatus.downloading,
        _DownloadStatusFilter.failed =>
          item.status == DownloadManagerStatus.failed,
        _DownloadStatusFilter.notDownloaded =>
          item.status == DownloadManagerStatus.notDownloaded,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  ProductEntity _itemToProduct(DownloadManagerItem item) {
    return ProductEntity(
      id: item.productId,
      name: item.productName,
      price: item.price,
      image: item.image,
      categoryName: 'Yakalar',
      downloadable: true,
      createdAt: item.productCreatedAt,
      images: item.productImages,
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.controller,
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final _DownloadStatusFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_DownloadStatusFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: AppIcon(
                  IconlyLight.search,
                  size: 20,
                  color: palette.muted,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              hintText: 'search'.tr,
              hintStyle: TextStyle(color: palette.muted),
              isDense: true,
              filled: true,
              fillColor: palette.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _DownloadStatusFilter.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _DownloadStatusFilter.values[index];
                final selected = option == filter;
                return ChoiceChip(
                  selected: selected,
                  label: Text(_filterLabel(option)),
                  selectedColor: ColorConstants.primaryColor,
                  backgroundColor: AppPalette.of(context).muted
                      .withOpacity(.12),
                  labelStyle: context.general.textTheme.bodySmall?.copyWith(
                    color: selected
                        ? Colors.white
                        : AppPalette.of(context).text,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => onFilterChanged(option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(_DownloadStatusFilter filter) {
    switch (filter) {
      case _DownloadStatusFilter.all:
        return 'filter_all'.tr;
      case _DownloadStatusFilter.downloaded:
        return 'filter_downloaded'.tr;
      case _DownloadStatusFilter.downloading:
        return 'filter_downloading'.tr;
      case _DownloadStatusFilter.failed:
        return 'filter_failed'.tr;
      case _DownloadStatusFilter.notDownloaded:
        return 'filter_not_downloaded'.tr;
    }
  }
}

class _DownloadManagerTile extends StatelessWidget {
  const _DownloadManagerTile({
    required this.item,
    required this.onTap,
    required this.onStatusPressed,
    required this.onExportPressed,
  });

  final DownloadManagerItem item;
  final VoidCallback onTap;
  final VoidCallback onStatusPressed;
  final VoidCallback onExportPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _image(palette),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.general.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.text,
                          ),
                        ),
                        if (item.machineName.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            item.machineName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.general.textTheme.bodySmall
                                ?.copyWith(color: palette.muted),
                          ),
                        ],
                        if (item.displayDate.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.displayDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.general.textTheme.bodySmall
                                ?.copyWith(color: palette.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _statusBadge(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (Platform.isIOS &&
                      item.status == DownloadManagerStatus.downloaded) ...[
                    _actionButton(
                      icon: IconlyLight.upload,
                      color: ColorConstants.primaryColor,
                      tooltip: 'exportFile'.tr,
                      onPressed: onExportPressed,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _statusAction(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(AppPalette palette) {
    return SizedBox(
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: item.image.isEmpty
            ? ColoredBox(color: palette.surfaceAlt, child: const NoImage())
            : CachedNetworkImage(
                imageUrl: item.image,
                fit: BoxFit.cover,
                memCacheWidth: 216,
                placeholder: (context, url) => const Loading(),
                errorWidget: (context, url, error) => const NoImage(),
              ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context) {
    final palette = AppPalette.of(context);
    final (label, icon, color) = switch (item.status) {
      DownloadManagerStatus.downloaded => (
        'filter_downloaded'.tr,
        Icons.check_circle,
        ColorConstants.greenColor,
      ),
      DownloadManagerStatus.downloading => (
        'filter_downloading'.tr,
        Icons.downloading,
        ColorConstants.primaryColor,
      ),
      DownloadManagerStatus.failed => (
        'filter_failed'.tr,
        Icons.error_outline,
        ColorConstants.redColor,
      ),
      DownloadManagerStatus.notDownloaded => (
        'filter_not_downloaded'.tr,
        IconlyLight.download,
        palette.muted,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.general.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusAction(BuildContext context) {
    switch (item.status) {
      case DownloadManagerStatus.downloaded:
        return _actionButton(
          onPressed: onStatusPressed,
          icon: Icons.refresh,
          color: AppPalette.of(context).muted,
          tooltip: 'download'.tr,
        );
      case DownloadManagerStatus.downloading:
        return SizedBox(
          height: 44,
          width: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: item.progress <= 0 ? null : item.progress,
                strokeWidth: 3,
                color: ColorConstants.primaryColor,
              ),
              if (item.progress > 0)
                Text(
                  '${(item.progress * 100).clamp(0, 100).round()}%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.of(context).text,
                  ),
                ),
            ],
          ),
        );
      case DownloadManagerStatus.failed:
        return _actionButton(
          onPressed: onStatusPressed,
          icon: Icons.refresh,
          color: ColorConstants.redColor,
          tooltip: 'download'.tr,
        );
      case DownloadManagerStatus.notDownloaded:
        return _actionButton(
          onPressed: onStatusPressed,
          icon: IconlyLight.download,
          color: ColorConstants.primaryColor,
          tooltip: 'download'.tr,
        );
    }
  }

  Widget _actionButton({
    required Object icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(.10),
      borderRadius: BorderRadius.circular(12),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
        icon: AppIcon(icon, size: 20, color: color),
      ),
    );
  }
}
