import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import '../constants/border_radius_constants.dart';
import '../l10n/app_translations.dart';
import '../theme/color_constants.dart';
import '../theme/context_extensions.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool? isLabel;
  final bool isNumber;
  final String labelName;
  final int? maxline;
  final Widget? prefixIcon;
  final Function(String value)? onChanged;
  final FocusNode requestfocusNode;

  const CustomTextField({
    required this.labelName,
    required this.controller,
    required this.focusNode,
    required this.requestfocusNode,
    required this.isNumber,
    this.isLabel = false,
    this.maxline,
    this.onChanged,
    this.prefixIcon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.padding.verticalNormal,
      child: TextFormField(
        style: context.general.textTheme.titleLarge!.copyWith(
          color: AppPalette.of(context).text,
        ),
        cursorColor: AppPalette.of(context).text,
        controller: controller,
        validator: (value) {
          if (value!.isEmpty) {
            return 'errorEmpty'.tr;
          }
          return null;
        },
        onEditingComplete: () {
          requestfocusNode.requestFocus();
        },
        onChanged: onChanged,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxline ?? 1,
        focusNode: focusNode,
        decoration: InputDecoration(
          errorMaxLines: 2,
          errorStyle: context.general.textTheme.titleLarge!.copyWith(
            color: ColorConstants.redColor,
          ),
          hintMaxLines: 5,
          helperMaxLines: 5,
          hintText: isLabel! ? labelName.tr : '',
          hintStyle: context.general.textTheme.titleLarge!.copyWith(
            color: AppPalette.of(context).muted.withOpacity(.5),
            fontWeight: FontWeight.w500,
          ),
          label: isLabel!
              ? null
              : Text(
                  labelName.tr,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
          prefixIcon: prefixIcon,
          labelStyle: context.general.textTheme.titleLarge!.copyWith(
            color: AppPalette.of(context).muted.withOpacity(.5),
            fontWeight: FontWeight.w500,
          ),
          contentPadding: context.padding.normal,
          border: OutlineInputBorder(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            borderSide: BorderSide(
              color: AppPalette.of(context).muted,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            borderSide: BorderSide(
              color: AppPalette.of(context).muted.withOpacity(.3),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            borderSide: const BorderSide(
              color: ColorConstants.primaryColor,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            borderSide: const BorderSide(
              color: ColorConstants.primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            borderSide: const BorderSide(
              color: ColorConstants.redColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
