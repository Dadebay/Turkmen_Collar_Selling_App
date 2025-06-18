// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/product/constants/index.dart';

class ProfilButton extends StatelessWidget {
  final String name;
  final Function() onTap;
  final IconData icon;
  final Widget? langIcon;
  final bool? langIconStatus;
  const ProfilButton({
    required this.name,
    required this.onTap,
    required this.icon,
    this.langIcon,
    this.langIconStatus,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      // tileColor: ColorConstants.whiteColor,
      minVerticalPadding: 23,
      title: Text(
        name.tr,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(
          color: ColorConstants.blackColor,
        ),
      ),
      leading: langIconStatus!
          ? langIcon
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: ColorConstants.primaryColor.withOpacity(0.8), borderRadius: context.border.normalBorderRadius),
              child: Icon(
                icon,
                color: ColorConstants.whiteColor,
              ),
            ),
      trailing: const Icon(
        IconlyLight.arrowRightCircle,
        color: ColorConstants.primaryColor,
      ),
    );
  }
}
