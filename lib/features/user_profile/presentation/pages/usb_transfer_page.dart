// ignore_for_file: always_put_control_body_on_new_line
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/no_image.dart';
import '../../../../injection_container.dart';
import '../../../downloads/domain/entities/download_manager_item.dart';
import '../../../downloads/presentation/bloc/usb_transfer/usb_transfer_bloc.dart';
import '../../../../core/icons/app_icon.dart';

class UsbTransferPage extends StatelessWidget {
  const UsbTransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UsbTransferBloc>(
      create: (_) => sl<UsbTransferBloc>()..add(const UsbTransferStarted()),
      child: const _UsbTransferView(),
    );
  }
}

class _UsbTransferView extends StatefulWidget {
  const _UsbTransferView();

  @override
  State<_UsbTransferView> createState() => _UsbTransferViewState();
}

class _UsbTransferViewState extends State<_UsbTransferView> {
  // Tracks the modal transfer dialog so it's shown exactly once per run and the
  // transfer's own outcome isn't also duplicated as a snackbar.
  bool _transferDialogOpen = false;

  /// Opens the progress/completion dialog when a transfer starts. The dialog
  /// listens to the same bloc, so it swaps to the completion layout on its own
  /// once [UsbTransferState.transferComplete] flips.
  void _handleTransferDialog(BuildContext context, UsbTransferState state) {
    if (state.isTransferring && !_transferDialogOpen) {
      _transferDialogOpen = true;
      final bloc = context.read<UsbTransferBloc>();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider<UsbTransferBloc>.value(
          value: bloc,
          child: const _UsbTransferDialog(),
        ),
      ).whenComplete(() => _transferDialogOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsbTransferBloc, UsbTransferState>(
      listener: (context, state) {
        _handleTransferDialog(context, state);
        // Non-transfer errors (folder access, load failures) surface as a
        // snackbar; the transfer's own outcome is shown inside the dialog, so
        // it's suppressed here while the dialog is open.
        if (state.errorMessage != null && !_transferDialogOpen) {
          showSnackBar(
            context,
            'errorTitle',
            state.errorMessage!,
            ColorConstants.redColor,
          );
        }
      },
      builder: (context, state) {
        final appBarForeground =
            Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
        return PopScope(
          canPop: state.activeProductId == null,
          onPopInvoked: (result) {
            if (state.activeProductId != null) {
              context.read<UsbTransferBloc>().add(const UsbProductClosed());
              return;
            }
          },
          child: Scaffold(
            backgroundColor: AppPalette.of(context).surface,
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                onPressed: () {
                  if (state.activeProductId != null) {
                    context.read<UsbTransferBloc>().add(
                      const UsbProductClosed(),
                    );
                  } else {
                    context.pop();
                  }
                },
                icon: AppIcon(
                  Icons.arrow_back_ios_new_rounded,
                  color: appBarForeground,
                ),
              ),
              title: Text(
                'usbTransferTitle'.tr,
                style: TextStyle(
                  color: appBarForeground,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              actions: [
                // Change/select the USB drive — kept here so the drive can be
                // switched even when one is already selected.
                if (!state.androidOnly)
                  IconButton(
                    tooltip: 'usbSelectDriveButton'.tr,
                    onPressed: state.isTransferring
                        ? null
                        : () => context.read<UsbTransferBloc>().add(
                            const UsbFolderRequested(),
                          ),
                    icon: AppIcon(
                      Icons.folder_open_rounded,
                      color: appBarForeground,
                    ),
                  ),
              ],
            ),
            body: state.androidOnly
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 24,
                      ),
                      child: Text(
                        'copyUsbAndroidOnly'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppPalette.of(context).text,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
                            sliver: SliverToBoxAdapter(
                              child: _SelectionHeader(state: state),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            sliver: _ProductsGrid(state: state),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 30, 12, 20),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _InstructionsItem(
                                    icon: Icons.looks_one_rounded,
                                    text: 'usbInstruction1'.tr,
                                  ),
                                  _InstructionsItem(
                                    icon: Icons.looks_two_rounded,
                                    text: 'usbInstruction2'.tr,
                                  ),
                                  _InstructionsItem(
                                    icon: Icons.looks_3_rounded,
                                    text: 'usbInstruction3'.tr,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (state.activeProductId != null)
                        Container(
                          height: double.maxFinite,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                          child: _ProductDetailView(state: state),
                        ),
                    ],
                  ),
            bottomNavigationBar: state.androidOnly
                ? null
                : _BottomActions(state: state),
          ),
        );
      },
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.state});
  final UsbTransferState state;

  @override
  Widget build(BuildContext context) {
    if (state.products.isEmpty && !state.loading) {
      return const SizedBox.shrink();
    }
    final selectedTotal = state.totalSelectedMachineCount();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'downloadedCollarsCount'.tr.replaceAll(
              '@count',
              '${state.products.length}',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        if (selectedTotal > 0)
          TextButton.icon(
            onPressed: () => context.read<UsbTransferBloc>().add(
              const UsbSelectionCleared(),
            ),
            icon: const AppIcon(Icons.close_rounded, size: 18),
            label: Text(
              '${'usbSelectedTotal'.tr.replaceAll('@count', '$selectedTotal')}'
              ' · ${'usbClearSelection'.tr}',
            ),
            style: TextButton.styleFrom(
              foregroundColor: ColorConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
      ],
    );
  }
}

class _InstructionsItem extends StatelessWidget {
  const _InstructionsItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, size: 22, color: ColorConstants.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppPalette.of(context).muted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  const _ProductsGrid({required this.state});
  final UsbTransferState state;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (state.products.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppPalette.of(context).surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppPalette.of(context).border),
          ),
          child: Column(
            children: [
              AppIcon(
                Icons.folder_open_rounded,
                size: 40,
                color: AppPalette.of(context).muted,
              ),
              const SizedBox(height: 10),
              Text(
                'noDownloadedCollarsFound'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPalette.of(context).muted),
              ),
            ],
          ),
        ),
      );
    }
    final products = state.products;
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 252,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            _UsbProductCard(product: products[index], state: state),
        childCount: products.length,
      ),
    );
  }
}

class _UsbProductCard extends StatelessWidget {
  const _UsbProductCard({required this.product, required this.state});

  final UsbProductSummary product;
  final UsbTransferState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final availableCount = state.availableVersions[product.id]?.length ?? 0;
    final selectedCount = state.selectedVersions[product.id]?.length ?? 0;
    final isSelected = selectedCount > 0;
    final isFullySelected =
        availableCount > 0 && selectedCount == availableCount;
    final productItems = state.items.where((i) => i.productId == product.id);
    final downloadedCount = productItems
        .where((i) => i.status == DownloadManagerStatus.downloaded)
        .length;
    DownloadManagerItem? activeDownload;
    for (final item in productItems) {
      if (item.status == DownloadManagerStatus.downloading) {
        activeDownload = item;
        break;
      }
    }

    final selectedLabel = 'selectedCountInfo'.tr
        .replaceAll('@selected', '$selectedCount')
        .replaceAll('@total', '$availableCount');
    final downloadedLabel =
        '$downloadedCount/$availableCount '
        '${'copyUsbStatusDownloaded'.tr.toLowerCase()}';

    return Material(
      color: isSelected
          ? ColorConstants.primaryColor.withOpacity(0.06)
          : palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? ColorConstants.primaryColor : palette.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.read<UsbTransferBloc>().add(UsbProductOpened(product.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: palette.surfaceAlt,
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      memCacheWidth: 440,
                      placeholder: (context, url) => const Loading(),
                      errorWidget: (context, url, error) => const NoImage(),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? ColorConstants.primaryColor
                            : palette.surface.withOpacity(0.96),
                        border: Border.all(
                          color: isSelected
                              ? ColorConstants.primaryColor
                              : palette.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AppIcon(
                          isFullySelected
                              ? Icons.check_rounded
                              : isSelected
                              ? Icons.edit_rounded
                              : Icons.chevron_right_rounded,
                          size: 19,
                          color: isSelected ? Colors.white : palette.text,
                        ),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: ColorConstants.primaryColor,
                        child: SizedBox(height: 3),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 110,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        AppIcon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 13,
                          color: isSelected
                              ? ColorConstants.primaryColor
                              : palette.muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            selectedLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? ColorConstants.primaryColor
                                  : palette.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (activeDownload != null)
                      _DownloadStatusBadge(item: activeDownload)
                    else
                      Row(
                        children: [
                          AppIcon(
                            downloadedCount == availableCount &&
                                    availableCount > 0
                                ? Icons.check_circle
                                : Icons.download,
                            size: 13,
                            color:
                                downloadedCount == availableCount &&
                                    availableCount > 0
                                ? ColorConstants.greenColor
                                : palette.muted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              downloadedLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    downloadedCount == availableCount &&
                                        availableCount > 0
                                    ? ColorConstants.greenColor
                                    : palette.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView({required this.state});
  final UsbTransferState state;

  @override
  Widget build(BuildContext context) {
    final activeId = state.activeProductId;
    if (activeId == null) return const SizedBox.shrink();
    final product = state.productById(activeId);
    if (product == null) return const SizedBox.shrink();
    final available = state.availableVersions[activeId] ?? const <String>[];
    final selected = state.selectedVersions[activeId] ?? const <String>{};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: CachedNetworkImage(
              imageUrl: product.image,
              fit: BoxFit.cover,
              memCacheWidth: 600,
              placeholder: (context, url) => const Loading(),
              errorWidget: (context, url, e) => const NoImage(),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: Text(
                  'availableModelsTitle'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (available.isNotEmpty)
                TextButton.icon(
                  onPressed: () => context.read<UsbTransferBloc>().add(
                    UsbAllVersionsToggled(activeId),
                  ),
                  icon: AppIcon(
                    selected.length >= available.length
                        ? Icons.remove_done_rounded
                        : Icons.done_all_rounded,
                    size: 18,
                  ),
                  label: Text(
                    selected.length >= available.length
                        ? 'usbClearSelection'.tr
                        : 'usbSelectAllModels'.tr,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: available.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final machineName = available[index];
              final isSelected = selected.contains(machineName);
              final item = state.items.firstWhere(
                (i) =>
                    i.productId == activeId &&
                    i.machineName.toUpperCase() == machineName.toUpperCase(),
                orElse: () => state.items.firstWhere(
                  (i) => i.productId == activeId,
                  orElse: () => state.items.first,
                ),
              );
              return InkWell(
                onTap: () => context.read<UsbTransferBloc>().add(
                  UsbVersionToggled(
                    productId: activeId,
                    machineName: machineName,
                  ),
                ),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected
                          ? ColorConstants.primaryColor
                          : AppPalette.of(context).border,
                      width: 2,
                    ),
                    color: isSelected
                        ? ColorConstants.primaryColor.withOpacity(0.05)
                        : AppPalette.of(context).surface,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppPalette.of(context).surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          fadeInCurve: Curves.ease,
                          imageUrl: item.machineLogo,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Loading(),
                          errorWidget: (context, url, e) => AppIcon(
                            Icons.print_rounded,
                            size: 20,
                            color: AppPalette.of(context).muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              machineName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _DownloadStatusBadge(item: item),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? ColorConstants.primaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? ColorConstants.primaryColor
                                : AppPalette.of(context).muted,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const AppIcon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  context.read<UsbTransferBloc>().add(const UsbProductClosed()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                side: const BorderSide(color: ColorConstants.primaryColor),
              ),
              child: Text(
                'backButton'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DownloadStatusBadge extends StatelessWidget {
  const _DownloadStatusBadge({required this.item});
  final DownloadManagerItem item;

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.status == DownloadManagerStatus.downloading)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: item.progress <= 0 ? null : item.progress,
              color: color,
            ),
          )
        else
          AppIcon(_icon, color: color, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            _label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Color _color(BuildContext context) {
    switch (item.status) {
      case DownloadManagerStatus.downloaded:
        return ColorConstants.greenColor;
      case DownloadManagerStatus.downloading:
        return ColorConstants.primaryColor;
      case DownloadManagerStatus.failed:
        return ColorConstants.redColor;
      case DownloadManagerStatus.notDownloaded:
        return AppPalette.of(context).muted;
    }
  }

  IconData get _icon {
    switch (item.status) {
      case DownloadManagerStatus.downloaded:
        return Icons.check_circle;
      case DownloadManagerStatus.downloading:
        return Icons.downloading;
      case DownloadManagerStatus.failed:
        return Icons.refresh;
      case DownloadManagerStatus.notDownloaded:
        return Icons.download;
    }
  }

  String get _label {
    switch (item.status) {
      case DownloadManagerStatus.downloaded:
        return 'copyUsbStatusDownloaded'.tr;
      case DownloadManagerStatus.downloading:
        final progress = (item.progress * 100).clamp(0, 100).round();
        return '${'copyUsbStatusDownloading'.tr} $progress%';
      case DownloadManagerStatus.failed:
        return 'copyUsbStatusFailed'.tr;
      case DownloadManagerStatus.notDownloaded:
        return 'copyUsbStatusNotDownloaded'.tr;
    }
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.state});
  final UsbTransferState state;

  @override
  Widget build(BuildContext context) {
    final hasAccess = state.hasUsbAccess;
    final isTransferring = state.isTransferring;
    final transferComplete = state.transferComplete;
    final hasSelection = state.selectedVersions.isNotEmpty;
    final total = state.totalTransferItems;

    // Without a selected drive the main button reverts to "select drive" — the
    // same recovery path the user needs when a USB selection fails.
    final isSelectDrive = !hasAccess;
    final canTransfer = !isTransferring && hasSelection;
    final enabled = isSelectDrive ? !isTransferring : canTransfer;
    // The small-font prompt state is only the "select files first" hint.
    final isFilesHint = hasAccess && !isTransferring && !hasSelection;

    final String label;
    if (isSelectDrive) {
      label = 'usbSelectDriveButton'.tr;
    } else if (isTransferring) {
      label = total > 0
          ? 'copyUsbCopyingProgress'.trParams({
              'copied': '${state.processedTransferItems}',
              'total': '$total',
            })
          : 'transferringStatus'.tr;
    } else if (hasSelection) {
      label = 'transferToUsbButton'.tr;
    } else if (transferComplete) {
      label = 'transferFinishedStatus'.tr;
    } else {
      label = 'usbSelectFilesFirst'.tr;
    }

    final Widget icon;
    if (isTransferring) {
      icon = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    } else {
      icon = AppIcon(
        isSelectDrive
            ? Icons.usb_rounded
            : (!hasSelection && transferComplete
                  ? Icons.check_circle
                  : Icons.file_upload_rounded),
        color: enabled ? Colors.white : AppPalette.of(context).muted,
      );
    }

    final driveName = state.usbFolderName?.isNotEmpty ?? false
        ? state.usbFolderName!
        : 'usbDriveSelected'.tr;

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      // Keep the action button clear of the system navigation bar / gesture
      // area; without this the button overlaps the on-screen nav buttons.
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTransferring && total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.processedTransferItems / total,
                  minHeight: 6,
                  backgroundColor: AppPalette.of(context).border,
                  color: ColorConstants.greenColor,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !enabled
                    ? null
                    : () => context.read<UsbTransferBloc>().add(
                        isSelectDrive
                            ? const UsbFolderRequested()
                            : const UsbTransferTriggered(),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelectDrive
                      ? ColorConstants.primaryColor
                      : ColorConstants.greenColor,
                  disabledBackgroundColor: AppPalette.of(context).border,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                icon: icon,
                label: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isFilesHint ? 14 : 17,
                    fontWeight: FontWeight.bold,
                    color: enabled
                        ? Colors.white
                        : AppPalette.of(context).muted,
                  ),
                ),
              ),
            ),
            if (hasAccess) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    Icons.usb_rounded,
                    size: 14,
                    color: AppPalette.of(context).muted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${'usbSelectedDriveLabel'.tr}: $driveName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.of(context).muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Modal shown for the duration of a transfer. While transferring it renders a
/// progress layout (USB icon, item progress bar, running tally, "don't remove"
/// warning); once [UsbTransferState.transferComplete] flips it swaps to a
/// completion layout (result icon, summary, OK button) that the user dismisses.
///
/// Mirrors the single unified dialog used on `main`, driven off bloc state
/// instead of GetX reactive values.
class _UsbTransferDialog extends StatelessWidget {
  const _UsbTransferDialog();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsbTransferBloc, UsbTransferState>(
      builder: (context, state) {
        final complete = state.transferComplete;
        final anySuccess = state.copiedFiles > 0 || state.skippedFiles > 0;

        return PopScope(
          // Block back-button dismissal while transferring; the OK button's
          // programmatic pop still closes it once complete.
          canPop: complete,
          child: Dialog(
            backgroundColor: AppPalette.of(context).surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    complete
                        ? (anySuccess
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded)
                        : Icons.usb_rounded,
                    size: 64,
                    color: complete
                        ? (anySuccess
                              ? ColorConstants.greenColor
                              : ColorConstants.redColor)
                        : ColorConstants.primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    complete
                        ? 'transferFinishedStatus'.tr
                        : 'transferringStatus'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.of(context).text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (complete)
                    _CompletionBody(state: state, anySuccess: anySuccess)
                  else
                    _ProgressBody(state: state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.state});
  final UsbTransferState state;

  @override
  Widget build(BuildContext context) {
    final total = state.totalTransferItems;
    final processed = state.processedTransferItems;
    // Blend the currently-downloading item's fractional progress into the bar
    // so it keeps moving during a long download instead of jumping per item.
    final activeFraction = state.items
        .where((i) => i.status == DownloadManagerStatus.downloading)
        .map((i) => i.progress)
        .fold<double>(0, (a, b) => a + b);
    final value = total > 0
        ? ((processed + activeFraction) / total).clamp(0.0, 1.0)
        : 0.0;
    final tally = _transferTally(state);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (total > 0)
          Text(
            'copyUsbCopyingProgress'.trParams({
              'copied': '$processed',
              'total': '$total',
            }),
            style: TextStyle(fontSize: 14, color: AppPalette.of(context).muted),
          ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: total > 0 ? value : null,
            minHeight: 10,
            backgroundColor: AppPalette.of(context).border,
            valueColor: const AlwaysStoppedAnimation<Color>(
              ColorConstants.primaryColor,
            ),
          ),
        ),
        if (tally.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            tally,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppPalette.of(context).muted),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'usbDoNotRemove'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: ColorConstants.redColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CompletionBody extends StatelessWidget {
  const _CompletionBody({required this.state, required this.anySuccess});
  final UsbTransferState state;
  final bool anySuccess;

  @override
  Widget build(BuildContext context) {
    final tally = _transferTally(state);
    final message = tally.isNotEmpty
        ? tally
        : (anySuccess
              ? 'allFilesTransferredSuccess'.tr
              : 'transferFinishedStatus'.tr);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppPalette.of(context).muted),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: anySuccess
                  ? ColorConstants.greenColor
                  : ColorConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'ok'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Localised running tally of file-level results, e.g. "12 copied · 3 already
/// on USB · 1 failed" (zero parts omitted). Mirrors the bloc's summary so the
/// dialog and any snackbar stay consistent.
String _transferTally(UsbTransferState state) {
  final parts = <String>[];
  if (state.copiedFiles > 0) {
    parts.add('copyUsbCopiedCount'.trParams({'count': '${state.copiedFiles}'}));
  }
  if (state.skippedFiles > 0) {
    parts.add(
      'copyUsbSkippedCount'.trParams({'count': '${state.skippedFiles}'}),
    );
  }
  if (state.failedFiles > 0) {
    parts.add('copyUsbFailedCount'.trParams({'count': '${state.failedFiles}'}));
  }
  return parts.join(' · ');
}
