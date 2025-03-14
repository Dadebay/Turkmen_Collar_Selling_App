import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/product/constants/index.dart';

Widget twoTextEditingField({required TextEditingController controller1, required TextEditingController controller2, required BuildContext context}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 20),
          child: Text(
            'priceRange'.tr,
            style: const TextStyle(
              //fontFamily: normProBold,
              fontSize: 19, color: ColorConstants.blackColor,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                style: const TextStyle(
                  //fontFamily: normsProMedium,
                  fontSize: 18,
                ),
                cursorColor: ColorConstants.primaryColor,
                controller: controller1,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: InputDecoration(
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'TMT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        //fontFamily: normProBold,
                        fontSize: 14, color: ColorConstants.greyColor,
                      ),
                    ),
                  ),
                  suffixIconConstraints: const BoxConstraints(minHeight: 15),
                  isDense: true,
                  hintText: 'minPrice'.tr,
                  hintStyle: TextStyle(
                    //fontFamily: normsProMedium
                    fontSize: 16, color: ColorConstants.greyColor,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: context.border.normalBorderRadius,
                    borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: context.border.normalBorderRadius,
                    borderSide: BorderSide(color: ColorConstants.greyColor, width: 2),
                  ),
                ),
              ),
            ),
            Container(
              width: 15,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              height: 2,
              color: ColorConstants.greyColor,
            ),
            Expanded(
              child: TextFormField(
                style: const TextStyle(
                  //fontFamily: normsProMedium,
                  fontSize: 18,
                ),
                cursorColor: ColorConstants.primaryColor,
                controller: controller2,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  // LengthLimitingTextInputFormatter(9),
                ],
                decoration: InputDecoration(
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'TMT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        //fontFamily: normProBold,
                        fontSize: 14, color: ColorConstants.greyColor,
                      ),
                    ),
                  ),
                  suffixIconConstraints: const BoxConstraints(minHeight: 15),
                  isDense: true,
                  hintText: 'maxPrice'.tr,
                  hintStyle: TextStyle(
                    //fontFamily: normsProMedium,
                    fontSize: 16, color: ColorConstants.greyColor,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: context.border.normalBorderRadius,
                    borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: context.border.normalBorderRadius,
                    borderSide: BorderSide(color: ColorConstants.greyColor, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
