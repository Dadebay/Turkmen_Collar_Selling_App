// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/index.dart';

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
        style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.blackColor),
        cursorColor: ColorConstants.blackColor,
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
          errorStyle: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.redColor),
          hintMaxLines: 5,
          helperMaxLines: 5,
          hintText: isLabel! ? labelName.tr : '',
          hintStyle: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.greyColor.withOpacity(.5), fontWeight: FontWeight.w500),
          label: isLabel!
              ? null
              : Text(
                  labelName.tr,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
          prefixIcon: prefixIcon,
          labelStyle: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.greyColor.withOpacity(.5), fontWeight: FontWeight.w500),
          contentPadding: context.padding.normal,
          border: OutlineInputBorder(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            borderSide: BorderSide(color: ColorConstants.greyColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            borderSide: BorderSide(color: ColorConstants.greyColor.withOpacity(.3), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            borderSide: const BorderSide(color: ColorConstants.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            borderSide: const BorderSide(color: ColorConstants.redColor, width: 2),
          ),
        ),
      ),
    );
  }
}
