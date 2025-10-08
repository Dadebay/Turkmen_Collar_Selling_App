import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/user_profil/views/add_money.dart';

import '../constants/index.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool? showWallet;
  final Widget? actionButton;
  final Widget? leadingButton;

  CustomAppBar({required this.title, required this.showBackButton, this.showWallet, this.leadingButton, this.actionButton});
  final BalanceController balanceController = Get.find();
  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ColorConstants.primaryColor,
      scrolledUnderElevation: 0.0,
      leadingWidth: 80,
      elevation: 0.0,
      leading: showBackButton
          ? IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                IconlyLight.arrowLeftCircle,
                color: ColorConstants.whiteColor,
              ),
            )
          : Center(child: leadingButton ?? const SizedBox.shrink()),
      title: Text(
        title.tr,
        style: context.general.textTheme.headlineMedium!.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      actions: [
        showWallet == true ? _walletIcon(context) : SizedBox.shrink(),
        actionButton ?? const SizedBox.shrink(),
      ],
    );
  }

  GestureDetector _walletIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => const AddCash());
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Obx(
            () => Text(
              '${balanceController.balance}',
              style: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800, color: ColorConstants.whiteColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 8, top: 4),
            child: Text(
              ' TMT',
              style: context.general.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: ColorConstants.whiteColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
