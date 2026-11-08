import 'package:flutter/material.dart';

import '../../constants/border_radius_constants.dart';
import '../../constants/widget_sizes.dart';
import '../../l10n/app_translations.dart';
import '../../theme/color_constants.dart';
import '../../theme/context_extensions.dart';

class AgreeButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? text;
  final bool isLoading;
  final double? fontSize;

  const AgreeButton({
    required this.onTap,
    this.text,
    this.isLoading = false,
    this.fontSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        decoration: BoxDecoration(
          borderRadius: CustomBorderRadius.normalBorderRadius,
          color: ColorConstants.primaryColor,
        ),
        padding: EdgeInsets.symmetric(horizontal: isLoading ? 0 : 8),
        width: isLoading ? 60 : MediaQuery.sizeOf(context).width,
        duration: const Duration(milliseconds: 1000),
        height: WidgetSizes.size50.value,
        alignment: Alignment.center,
        child: isLoading
            ? _loading(context)
            : Text(
                text?.tr ?? 'agree'.tr,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: context.general.textTheme.titleLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                ),
              ),
      ),
    );
  }

  Center _loading(BuildContext context) {
    return Center(
      child: SizedBox(
        width: WidgetSizes.size32.value,
        height: WidgetSizes.size32.value,
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
