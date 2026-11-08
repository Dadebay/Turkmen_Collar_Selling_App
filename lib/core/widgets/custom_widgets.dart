import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../constants/border_radius_constants.dart';
import '../constants/icon_constants.dart';
import '../l10n/app_translations.dart';
import '../router/app_router.dart';
import '../services/error_report_screenshot.dart';
import '../theme/color_constants.dart';
import '../theme/context_extensions.dart';
import 'custom_functions.dart';
import 'loading.dart';
import 'no_image.dart';
import '../icons/app_icon.dart';
import 'error_report_dialog.dart';

class CustomWidgets {
  static Widget customImageView({
    required String image,
    required bool cover,
    required BorderRadius borderRadius,
  }) {
    return CachedNetworkImage(
      fadeInCurve: Curves.ease,
      imageUrl: image,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          image: DecorationImage(
            image: imageProvider,
            alignment: Alignment.topCenter,
            fit: cover ? BoxFit.cover : null,
          ),
        ),
      ),
      placeholder: (context, url) => const Loading(),
      errorWidget: (context, url, error) => const NoImage(),
    );
  }

  static Widget appLogoMini() {
    return Image.asset(IconConstants.logo1, width: 50, height: 20);
  }

  static Widget productCardNameAndPrice({
    required BuildContext context,
    required String name,
    required String price,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        showProductsPrice(context: context, makeBigger: false, price: price),
        Padding(
          padding: context.padding.onlyBottomLow,
          child: Text(
            name,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.general.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: AppPalette.of(context).text,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  static Widget showProductsPrice({
    required BuildContext context,
    required bool makeBigger,
    required String price,
    Color? color,
  }) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: CustomFunctions.findPrice(price),
            style: context.general.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? ColorConstants.primaryColor,
              fontSize: makeBigger ? 22 : 18,
            ),
          ),
          TextSpan(
            text: ' TMT',
            style: context.general.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? ColorConstants.primaryColor,
              fontSize: makeBigger ? 14 : 11,
            ),
          ),
        ],
      ),
    );
  }

  static Widget listViewBuilderName({
    required String text,
    required BuildContext context,
    required bool showIcon,
    required Function() onTap,
  }) {
    return Padding(
      padding: context.padding.normal,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text.tr,
              style: context.general.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showIcon)
              AppIcon(
                IconlyLight.arrowRightCircle,
                color: AppPalette.of(context).text,
              ),
          ],
        ),
      ),
    );
  }
}

void showSnackBar(
  BuildContext context,
  String title,
  String subtitle,
  Color color,
) {
  final offerReport = shouldOfferErrorReport(title, subtitle, color);
  var openingReport = false;
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.all(8),
      duration: offerReport
          ? const Duration(seconds: 12)
          : const Duration(milliseconds: 2500),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          Text(
            subtitle.tr,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          if (offerReport)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  if (openingReport) {
                    return;
                  }
                  openingReport = true;
                  final screenshot = await ErrorReportScreenshot.capture();
                  messenger.hideCurrentSnackBar();
                  final reportContext =
                      rootNavigatorKey.currentContext ?? context;
                  if (!reportContext.mounted) {
                    await screenshot?.delete();
                    return;
                  }
                  await showDialog<void>(
                    context: reportContext,
                    barrierDismissible: false,
                    builder: (_) => ErrorReportDialog(
                      title: title.tr,
                      details: subtitle.tr,
                      screenshot: screenshot,
                    ),
                  );
                },
                icon: const Icon(Icons.send_outlined, color: Colors.white),
                label: Text(
                  'reportErrorAction'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

bool shouldOfferErrorReport(String title, String subtitle, Color color) {
  if (color != ColorConstants.redColor && color != Colors.red) {
    return false;
  }
  if (subtitle.isEmpty) {
    return false;
  }

  const expectedStates = {
    'loginError',
    'noConnection3',
    'notWork',
    'money_error_title',
    'emptyCart',
    'exportNoFiles',
  };
  const expectedMessages = {
    'errorEmpty',
    'downloadFailedNetwork',
    'downloadFailedTimeout',
    'downloadFailedNoFiles',
    'downloadFailedStoragePermissionSettings',
  };
  if (expectedStates.contains(title) || expectedMessages.contains(subtitle)) {
    return false;
  }

  final message = subtitle.tr.toLowerCase();
  return !message.contains('no internet') &&
      !message.contains('internet birikmesi ýok') &&
      !message.contains('нет подключения к интернету') &&
      !message.contains('failed host lookup') &&
      !message.contains('network is unreachable') &&
      !message.contains('socketexception');
}

CustomFooter footer() {
  return CustomFooter(
    builder: (BuildContext context, LoadStatus? mode) {
      Widget body;
      if (mode == LoadStatus.idle) {
        body = Text('waiting'.tr);
      } else if (mode == LoadStatus.loading) {
        body = const CircularProgressIndicator(
          color: ColorConstants.primaryColor,
        );
      } else if (mode == LoadStatus.failed) {
        body = Text('noData'.tr);
      } else if (mode == LoadStatus.canLoading) {
        body = Text('waiting'.tr);
      } else {
        body = Text('noData1'.tr);
      }

      return SizedBox(height: 55.0, child: Center(child: body));
    },
  );
}

Container customIcon(BuildContext context, String iconName) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: ColorConstants.primaryColor.withOpacity(0.8),
      borderRadius: CustomBorderRadius.normalBorderRadius,
    ),
    child: Image.asset(iconName, width: 24, height: 24, color: Colors.white),
  );
}

Padding textpart(BuildContext context, String name, bool value) {
  return Padding(
    padding: EdgeInsets.only(left: 8, top: value ? 15 : 30),
    child: Text(
      name.tr,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(fontSize: 18, color: AppPalette.of(context).text),
    ),
  );
}

Container divider() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Divider(
      color: ColorConstants.primaryColor.withOpacity(0.4),
      thickness: 2,
    ),
  );
}
