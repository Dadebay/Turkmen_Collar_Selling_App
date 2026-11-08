import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import 'package:go_router/go_router.dart';

import '../l10n/app_translations.dart';
import '../router/go_router_extensions.dart';
import '../theme/color_constants.dart';
import '../constants/icon_constants.dart';
import '../constants/widget_sizes.dart';

class DialogUtils {
  static Future<void> showLoginDialog({
    required BuildContext context,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
    required String title,
    required String agreeButton,
    required String subtitle,
    required String image,
  }) {
    // Don't prompt to log in when the user is already on the login/otp flow —
    // stacking the dialog over those screens is redundant and confusing.
    // `GoRouter.location` resolves the real top route (login/otp are pushed
    // above the ShellRoute callers, so context-scoped state reads `/home`).
    final location = GoRouter.of(context).location;
    if (location.contains('login') || location.contains('otp')) {
      return Future<void>.value();
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.of(context).surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ColorConstants.primaryColor,
                  width: 2,
                ),
              ),
              child: Material(
                color: AppPalette.of(context).surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      image,
                      width: WidgetSizes.size256.value,
                      height: WidgetSizes.size256.value,
                      fit: BoxFit.cover,
                    ),
                    Text(
                      title.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.titleLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        subtitle.tr,
                        style: Theme.of(ctx).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.of(context)
                                  .surfaceAlt,
                              foregroundColor: AppPalette.of(context).text,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: onCancel,
                            child: Text('no'.tr),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstants.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: onRetry,
                            child: Text(
                              agreeButton.tr,
                              style: Theme.of(ctx).textTheme.bodyMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown once a purchased collar finishes downloading, replacing the old
  /// success snackbar with a clearer confirmation the user must dismiss.
  static Future<void> showDownloadSuccessDialog({
    required BuildContext context,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.of(context).surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ColorConstants.primaryColor,
                  width: 2,
                ),
              ),
              child: Material(
                color: AppPalette.of(context).surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'downloadSuccessTitle'.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.titleLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'downloadSuccessSubtitle'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(ctx).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('close'.tr),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmation shown before a paid collar file is downloaded — the user must
  /// agree to spend from their wallet first. Mirrors the old GetX
  /// `askToDownloadYaka`; [onAgree] runs after the dialog is dismissed.
  static Future<void> showBuyCollarDialog({
    required BuildContext context,
    required VoidCallback onAgree,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.of(context).surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ColorConstants.primaryColor,
                  width: 2,
                ),
              ),
              child: Material(
                color: AppPalette.of(context).surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'amountTooLowTitle'.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.titleLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'wantToBuyCollar'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(ctx).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstants.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              onAgree();
                            },
                            child: Text(
                              'agree'.tr,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(ctx).textTheme.bodyMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.of(context)
                                  .surfaceAlt,
                              foregroundColor: AppPalette.of(context).text,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(
                              'no'.tr,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showNoConnectionDialog({
    required VoidCallback onRetry,
    required BuildContext context,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.only(
                  top: 100,
                  left: 15,
                  right: 15,
                  bottom: 10,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.of(context).surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      'noConnection1'.tr,
                      style: Theme.of(ctx).textTheme.bodyLarge,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'noConnection2'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: onRetry,
                      child: Text('noConnection3'.tr),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: CircleAvatar(
                backgroundColor: AppPalette.of(context).surface,
                maxRadius: WidgetSizes.size64.value,
                child: ClipOval(
                  child: Image.asset(
                    IconConstants.noConnection,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showCustomUpdateDialog({
    required BuildContext context,
    required VoidCallback onUpdate,
    required VoidCallback onLater,
    required String releaseNotes,
    required String currentVersion,
    required String newVersion,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          Center(
            child: Container(
              width: screenWidth * 0.85,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.of(context).surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Material(
                color: AppPalette.of(context).surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        IconConstants.logo,
                        width: 80,
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'newVersion'.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppPalette.of(context).text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${'updateAvailableSubtitle'.tr} (v$currentVersion)',
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.bodyMedium
                          ?.copyWith(color: AppPalette.of(context).muted),
                    ),
                    if (releaseNotes.isNotEmpty && releaseNotes != 'null') ...[
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'whatsNew'.tr,
                          style: Theme.of(ctx).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: SingleChildScrollView(
                          child: Text(
                            releaseNotes,
                            style: Theme.of(ctx).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (!Platform.isIOS)
                      TextButton(
                        onPressed: onLater,
                        child: Text(
                          'noUpdate'.tr,
                          style: TextStyle(color: AppPalette.of(context).muted),
                        ),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: onUpdate,
                      child: Text('yesUpdate'.tr),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
