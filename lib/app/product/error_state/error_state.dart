import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';

import '../constants/index.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({required this.onTap, super.key});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'noConnection2'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColorConstants.blackColor, //fontFamily: normProBold,
              fontSize: 18,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: context.border.lowBorderRadius),
                backgroundColor: ColorConstants.primaryColor,
              ),
              child: Text(
                'noConnection3'.tr,
                style: const TextStyle(color: ColorConstants.blackColor, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
