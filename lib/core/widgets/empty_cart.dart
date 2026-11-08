import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import 'package:lottie/lottie.dart';

import '../constants/icon_constants.dart';
import '../constants/widget_sizes.dart';
import '../l10n/app_translations.dart';
import '../theme/context_extensions.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: context.padding.normal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              IconConstants.emptyCart,
              width: WidgetSizes.size300.value,
              height: WidgetSizes.size300.value,
            ),
            Text(
              'cartEmpty'.tr,
              textAlign: TextAlign.center,
              style: context.general.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'cartEmptySubtitle'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppPalette.of(context).text,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
