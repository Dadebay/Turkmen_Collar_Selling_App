import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import 'package:flutter/services.dart';

import '../constants/border_radius_constants.dart';
import '../l10n/app_translations.dart';
import '../theme/color_constants.dart';
import '../theme/context_extensions.dart';

class PhoneNumberTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool? disabled;
  final FocusNode mineFocus;
  final FocusNode requestFocus;
  final EdgeInsetsGeometry? outerPadding;
  final ValueChanged<String>? onChanged;

  const PhoneNumberTextField({
    required this.mineFocus,
    required this.controller,
    required this.requestFocus,
    this.disabled,
    this.outerPadding,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: outerPadding ?? context.padding.verticalNormal,
      child: TextFormField(
        enabled: disabled ?? true,
        style: context.general.textTheme.titleLarge!.copyWith(
          color: AppPalette.of(context).text,
        ),
        cursorColor: AppPalette.of(context).text,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.number,
        focusNode: mineFocus,
        controller: controller,
        onChanged: onChanged,
        validator: (value) {
          if (value!.isEmpty) {
            return 'errorEmpty'.tr;
          } else if (value.length != 8) {
            return 'errorPhoneCount'.tr;
          }
          return null;
        },
        inputFormatters: [LengthLimitingTextInputFormatter(8)],
        onEditingComplete: () {
          requestFocus.requestFocus();
        },
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(
          errorMaxLines: 2,
          errorStyle: context.general.textTheme.titleLarge!.copyWith(
            color: ColorConstants.redColor,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              '+ 993',
              style: context.general.textTheme.titleLarge!.copyWith(
                color: AppPalette.of(context).muted.withOpacity(.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          contentPadding: context.padding.normal,
          prefixIconConstraints: const BoxConstraints(minWidth: 80),
          hintText: ' ',
          fillColor: ColorConstants.primaryColor,
          alignLabelWithHint: true,
          hintStyle: context.general.textTheme.titleLarge!.copyWith(
            color: AppPalette.of(context).muted.withOpacity(.5),
            fontWeight: FontWeight.w500,
          ),
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
