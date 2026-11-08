import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';

import '../../features/downloads/presentation/bloc/download_manager_bloc.dart';
import '../../features/home/presentation/bloc/balance/balance_bloc.dart';
import '../../features/payment/presentation/bloc/payment_status_bloc.dart';
import '../constants/icon_constants.dart';
import '../l10n/app_translations.dart';
import '../router/app_router.dart';
import '../storage/local_storage.dart';
import '../theme/color_constants.dart';
import '../theme/context_extensions.dart';
import '../utils/dialog_utils.dart';
import '../icons/app_icon.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool? showWallet;
  final Widget? actionButton;
  final Widget? leadingButton;
  final Widget? titleWidget;

  const CustomAppBar({
    required this.title,
    required this.showBackButton,
    this.showWallet,
    this.leadingButton,
    this.actionButton,
    this.titleWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final barTheme = Theme.of(context).appBarTheme;
    final foreground = barTheme.foregroundColor ?? Colors.white;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: barTheme.backgroundColor,
      foregroundColor: foreground,
      scrolledUnderElevation: 0.0,
      leadingWidth: leadingButton != null
          ? 88
          : (titleWidget != null ? 50 : 56),
      elevation: 0.0,
      leading: showBackButton
          ? IconButton(
              onPressed: () {
                // Use go_router's pop so we never empty the root navigator
                // (which shows a black screen). If there is nothing to pop back
                // to — e.g. this page is the root after a `context.go` — fall
                // back to home instead.
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
              icon: AppIcon(IconlyLight.arrowLeftCircle, color: foreground),
            )
          : Center(child: leadingButton ?? const SizedBox.shrink()),
      title:
          titleWidget ??
          Text(
            title.tr,
            style: context.general.textTheme.headlineMedium!.copyWith(
              color: foreground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
      actions: [
        if (showWallet == true)
          BlocSelector<PaymentStatusBloc, PaymentStatusState, bool>(
            selector: (state) => state.isEnabled,
            builder: (context, paymentsEnabled) => paymentsEnabled
                ? _walletIcon(context, foreground)
                : const SizedBox.shrink(),
          ),
        actionButton ?? const SizedBox.shrink(),
      ],
    );
  }

  GestureDetector _walletIcon(BuildContext context, Color foreground) {
    return GestureDetector(
      onTap: () => _onWalletTap(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BlocBuilder<BalanceBloc, BalanceState>(
            builder: (context, state) {
              final balance = state is BalanceLoaded ? state.balance : 0.0;
              return Text(
                '$balance',
                style: context.general.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 8, top: 4),
            child: Text(
              ' TMT',
              style: context.general.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Topping up the wallet requires an account — ask guests to sign in first.
  void _onWalletTap(BuildContext context) {
    final token = LocalStorage().token;
    if (token == null || token.isEmpty) {
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
      return;
    }
    context.push(AppRoutes.addMoney);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Slim banner shown above all screens whenever a download is in progress.
///
/// Mount once at the root (e.g. MaterialApp.builder) so the ribbon doesn't
/// allocate space in any individual Scaffold's appBar. Height collapses to
/// zero when there are no active downloads.
class DownloadsRibbon extends StatelessWidget {
  const DownloadsRibbon({super.key});

  static const double height = 34;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadManagerBloc, DownloadManagerState>(
      builder: (context, state) {
        if (!state.hasActiveDownloads) {
          return const SizedBox.shrink();
        }
        return _DownloadsRibbonBanner(state: state);
      },
    );
  }
}

class _DownloadsRibbonBanner extends StatelessWidget {
  const _DownloadsRibbonBanner({required this.state});
  final DownloadManagerState state;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final currentLocation = GoRouterState.of(context).uri.toString();
        if (currentLocation != AppRoutes.downloads) {
          context.push(AppRoutes.downloads);
        }
      },
      child: Container(
        width: double.infinity,
        height: DownloadsRibbon.height,
        color: ColorConstants.primaryColor.withOpacity(.85),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                value: state.aggregateProgress,
                color: Colors.white,
                backgroundColor: Colors.white.withOpacity(.25),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.general.textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AppIcon(
              IconlyLight.arrowRightCircle,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
