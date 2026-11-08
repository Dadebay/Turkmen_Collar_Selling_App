import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/icon_constants.dart';
import '../../../../core/icons/app_icon.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_functions.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading.dart';
import '../../../downloads/domain/entities/download_manager_item.dart';
import '../../../downloads/presentation/bloc/download_manager_bloc.dart';
import '../../../home/domain/entities/collar_entity.dart';
import '../../../home/presentation/bloc/balance/balance_bloc.dart';
import '../../../payment/presentation/bloc/payment_status_bloc.dart';
import '../bloc/product_detail_bloc.dart';

class DownloadYakaPage extends StatefulWidget {
  final int id;
  final String image;
  final String pageName;
  const DownloadYakaPage({
    required this.image,
    required this.pageName,
    required this.id,
    super.key,
  });

  @override
  State<DownloadYakaPage> createState() => _DownloadYakaPageState();
}

class _DownloadYakaPageState extends State<DownloadYakaPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductDetailBloc>().add(
      ProductDetailLoadRequested(id: widget.id, isCollar: true),
    );
    // Refresh the wallet balance so the pre-flight purchase check below has an
    // up-to-date value (the app bar wallet reads the same BalanceBloc).
    context.read<BalanceBloc>().add(const BalanceFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.of(context).surfaceAlt,
      appBar: CustomAppBar(
        title: widget.pageName,
        showBackButton: true,
        showWallet: true,
      ),
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is ProductDetailInitial || state is ProductDetailLoading) {
            return const Loading();
          }
          if (state is ProductDetailError) {
            return ErrorState(
              onTap: () => context.read<ProductDetailBloc>().add(
                ProductDetailLoadRequested(id: widget.id, isCollar: true),
              ),
            );
          }
          if (state is ProductDetailCollarLoaded) {
            final collar = state.collar;
            final image = widget.image.isNotEmpty
                ? widget.image
                : (collar.images.isEmpty ? '' : collar.images.first.toString());
            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 320 ? 2 : 1;
                final textScale =
                    MediaQuery.textScalerOf(context).scale(14) / 14;
                final tileHeight = 114.0 * (textScale > 1.0 ? textScale : 1.0);
                final rows = (collar.files.length + columns - 1) ~/ columns;
                final gridHeight =
                    rows * tileHeight + (rows > 0 ? (rows - 1) * 8.0 : 0.0);
                final previewHeight =
                    (constraints.maxHeight -
                            24 - // Outer vertical padding.
                            12 - // Space below the preview.
                            34 * textScale - // Section heading.
                            12 - // Space above the grid.
                            gridHeight)
                        .clamp(100.0, 200.0);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  children: [
                    _preview(collar, image, height: previewHeight),
                    const SizedBox(height: 12),
                    _sectionHeading(collar.files.length),
                    const SizedBox(height: 12),
                    if (collar.files.isEmpty)
                      _emptyFiles()
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: collar.files.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: tileHeight,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) =>
                            _fileCard(collar, collar.files[index]),
                      ),
                  ],
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _preview(CollarEntity collar, String image, {required double height}) {
    final palette = AppPalette.of(context);
    final title = collar.name?.isNotEmpty == true
        ? collar.name!
        : (widget.pageName.isNotEmpty ? widget.pageName : 'collars'.tr);
    return Semantics(
      button: image.isNotEmpty,
      label: title,
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: image.isEmpty
              ? null
              : () => context.push(
                  AppRoutes.photoView,
                  extra: {'image': image, 'networkImage': true},
                ),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image.isEmpty)
                  _imageFallback(palette)
                else
                  CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imageFallback(palette),
                    errorWidget: (_, __, ___) => _imageFallback(palette),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xb8000000)],
                      stops: [0.42, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 56,
                  bottom: 16,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (image.isNotEmpty)
                  const Positioned(
                    right: 14,
                    bottom: 14,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xccffffff),
                      child: AppIcon(
                        Icons.search,
                        size: 19,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(AppPalette palette) => ColoredBox(
    color: palette.surfaceAlt,
    child: Center(
      child: AppIcon(Icons.image_outlined, size: 40, color: palette.muted),
    ),
  );

  Widget _sectionHeading(int count) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'availableModelsTitle'.tr,
            style: TextStyle(
              color: palette.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ColorConstants.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: ColorConstants.primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyFiles() {
    final palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          AppIcon(Icons.folder_open_rounded, size: 32, color: palette.muted),
          const SizedBox(height: 12),
          Text(
            'downloadFailedNoFiles'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _fileCard(CollarEntity collar, CollarFileEntity file) {
    final palette = AppPalette.of(context);
    final logo = file.machineLogo ?? '';
    final name = file.machineName?.trim().isNotEmpty == true
        ? file.machineName!.trim()
        : 'selectMachine'.tr.trim();
    final storageKey = '${collar.id ?? widget.id}:${file.id ?? 0}';
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final effectiveScale = textScale > 1.0 ? textScale : 1.0;
    final buttonHeight = 36.0 * effectiveScale;
    const logoFallback = Center(
      child: AppIcon(
        Icons.folder_open_rounded,
        size: 21,
        color: ColorConstants.primaryColor,
      ),
    );
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: BlocBuilder<DownloadManagerBloc, DownloadManagerState>(
        builder: (context, downloads) {
          final active = downloads.active[storageKey];
          final isDownloading =
              active?.status == DownloadManagerStatus.downloading;
          final progress = active?.progress ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(3),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: palette.border),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: logo.isEmpty
                          ? logoFallback
                          : CachedNetworkImage(
                              imageUrl: logo,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => logoFallback,
                              errorWidget: (_, __, ___) => logoFallback,
                            ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            bottom: 18 * effectiveScale,
                            child: Tooltip(
                              message: name,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.text,
                                    fontSize: 13,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Text(
                              file.purchased
                                  ? 'downloadedYAKA'.tr
                                  : '${CustomFunctions.findPrice((file.price ?? 0).toString())} TMT',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: file.purchased
                                    ? ColorConstants.greenColor
                                    : ColorConstants.primaryColor,
                                fontSize: 14,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: buttonHeight,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: effectiveScale > 1.0 ? 1.0 : 0.78,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FilledButton.icon(
                          onPressed: isDownloading
                              ? null
                              : () => _onDownloadTap(
                                  context,
                                  collar: collar,
                                  file: file,
                                ),
                          style: FilledButton.styleFrom(
                            backgroundColor: ColorConstants.primaryColor,
                            disabledBackgroundColor: ColorConstants.primaryColor
                                .withValues(alpha: 0.55),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: AppIcon(
                            isDownloading ? Icons.downloading : Icons.download,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            isDownloading
                                ? '${(progress * 100).round()}%'
                                : 'download'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isDownloading)
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 4,
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0, 1).toDouble(),
                                  minHeight: 3,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.3,
                                  ),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Handles a download tap for a single collar file:
  /// 1. Already purchased files download for free.
  /// 2. Otherwise the user must confirm the purchase, then payments must be
  ///    enabled (Apple-compliant fallback) and the wallet must hold enough
  ///    balance — the actual purchase happens server-side when the download
  ///    manager requests the download URLs.
  void _onDownloadTap(
    BuildContext context, {
    required CollarEntity collar,
    required CollarFileEntity file,
  }) {
    // Downloading requires an account — the backend charges the wallet and
    // serves the file against the user's token. Ask guests to sign in first.
    final token = LocalStorage().token;
    if (token == null || token.isEmpty) {
      _promptLogin(context);
      return;
    }

    // Paid (unpurchased) files spend from the wallet, so confirm first — the
    // balance/payment checks run once the user agrees.
    if (!file.purchased) {
      DialogUtils.showBuyCollarDialog(
        context: context,
        onAgree: () => _startDownload(context, collar: collar, file: file),
      );
      return;
    }

    _startDownload(context, collar: collar, file: file);
  }

  /// Validates payment/balance for paid files then dispatches the download.
  void _startDownload(
    BuildContext context, {
    required CollarEntity collar,
    required CollarFileEntity file,
  }) {
    final priceInCents = file.price ?? 0;

    if (!file.purchased) {
      final paymentsDisabled = context
          .read<PaymentStatusBloc>()
          .state
          .isDisabled;
      if (paymentsDisabled) {
        showSnackBar(context, 'errorTitle', 'noData', ColorConstants.redColor);
        return;
      }

      final balanceState = context.read<BalanceBloc>().state;
      final balance = balanceState is BalanceLoaded
          ? balanceState.balance
          : 0.0;
      // Balance is in TMT; the file price is stored in cents.
      if (balance * 100 < priceInCents) {
        showSnackBar(
          context,
          'money_error_title',
          'money_error_subtitle',
          ColorConstants.redColor,
        );
        context.push(AppRoutes.addMoney);
        return;
      }
    }

    final item = DownloadManagerItem(
      productId: collar.id ?? widget.id,
      fileId: file.id ?? 0,
      productName: collar.name ?? widget.pageName,
      machineName: file.machineName ?? collar.machineName ?? '',
      machineLogo: file.machineLogo ?? '',
      productCreatedAt: collar.createdAt ?? '',
      fileCreatedAt: file.createdAt ?? '',
      image: widget.image,
      price: priceInCents.toString(),
      productImages: widget.image.isEmpty ? const [] : [widget.image],
      savedFileNames: const [],
      requestedAt: '',
      status: DownloadManagerStatus.notDownloaded,
      progress: 0,
    );

    // The global download listener shows a modal progress dialog while this
    // runs and a success dialog on completion, so no start snackbar is needed.
    context.read<DownloadManagerBloc>().add(
      DownloadManagerDownloadRequested(item),
    );
  }

  /// Asks a guest to sign in / sign up before they can download.
  void _promptLogin(BuildContext context) {
    DialogUtils.showLoginDialog(
      context: context,
      title: 'loginError',
      agreeButton: 'login',
      subtitle: 'loginSubtitle',
      image: IconConstants.loginLottie,
      onRetry: () {
        Navigator.of(context).pop();
        context.push(AppRoutes.login);
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
