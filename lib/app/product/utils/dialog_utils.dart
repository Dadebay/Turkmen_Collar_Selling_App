// ignore_for_file: always_declare_return_types

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/auth/models/auth_model.dart';
import 'package:yaka2/app/feature/auth/views/user_login_view.dart';
import 'package:yaka2/app/feature/home/views/bottom_nav_bar_view.dart';
import 'package:yaka2/app/feature/product_profil/controllers/product_profil_controller.dart';
import 'package:yaka2/app/feature/user_profil/controllers/user_profil_controller.dart';
import 'package:yaka2/app/product/constants/index.dart';

class DialogUtils {
  static void defaultBottomSheet({required String name, required Widget child, required BuildContext context}) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(color: ColorConstants.whiteColor),
        child: Wrap(
          children: [
            Padding(
              padding: context.padding.low,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  Text(
                    name.tr,
                    style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, fontSize: 22, color: ColorConstants.blackColor),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(CupertinoIcons.xmark_circle, color: ColorConstants.blackColor),
                  ),
                ],
              ),
            ),
            const Divider(
              color: ColorConstants.blackColor,
              thickness: 1,
            ),
            child,
          ],
        ),
      ),
    );
  }

  dynamic showLoginDialogMine(BuildContext context) {
    return DialogUtils.showLoginDialog(
      context: context,
      title: 'loginError',
      agreeButton: 'login',
      subtitle: 'loginSubtitle',
      image: IconConstants.loginLottie,
      onRetry: () => Get.to(() => UserLoginView()),
      onCancel: () => Get.back(),
    );
  }

  static showLoginDialog({required BuildContext context, required VoidCallback onRetry, required VoidCallback onCancel, required String title, required String agreeButton, required String subtitle, required String image}) {
    Get.dialog(
      Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          Center(
            child: Container(
              padding: context.padding.normal,
              margin: context.padding.normal,
              decoration: BoxDecoration(
                color: ColorConstants.whiteColor,
                borderRadius: context.border.normalBorderRadius,
                border: Border.all(color: ColorConstants.primaryColor, width: 2),
              ),
              child: Material(
                color: ColorConstants.whiteColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      image,
                      width: WidgetSizes.size256.value,
                      height: WidgetSizes.size256.value,
                      fit: BoxFit.cover,
                    ),
                    Text(
                      title.tr,
                      textAlign: TextAlign.center,
                      style: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: context.padding.verticalNormal,
                      child: Text(
                        subtitle.tr,
                        style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: onCancel,
                            child: Text('no'.tr),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstants.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: onRetry,
                            child: Text(
                              agreeButton.tr,
                              style: context.general.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static void showNoConnectionDialog({required VoidCallback onRetry, required BuildContext context}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: context.border.normalBorderRadius),
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Container(
              padding: context.padding.onlyTopNormal,
              child: Container(
                padding: const EdgeInsets.only(top: 100, left: 15, right: 15),
                decoration: BoxDecoration(color: ColorConstants.whiteColor, borderRadius: context.border.normalBorderRadius),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      StringConstants.noConnectionTitle.tr,
                      style: context.general.textTheme.bodyLarge,
                    ),
                    Padding(
                      padding: context.padding.normal,
                      child: Text(
                        'noConnection2'.tr,
                        textAlign: TextAlign.center,
                        style: context.general.textTheme.bodyMedium,
                      ),
                    ),
                    AgreeButton(
                      onTap: () {},
                      text: StringConstants.onRetry,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: CircleAvatar(
                backgroundColor: ColorConstants.whiteColor,
                maxRadius: WidgetSizes.size64.value,
                child: ClipOval(
                  child: Image.asset(IconConstants.noConnection, fit: BoxFit.fill),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void changeLanguage() {
    final UserProfilController userProfilController = Get.put(UserProfilController());

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(color: ColorConstants.whiteColor),
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  Text(
                    'select_language'.tr,
                    style: const TextStyle(
                      color: ColorConstants.blackColor, //fontFamily: normProBold,
                      fontSize: 18,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(CupertinoIcons.xmark_circle, size: 25, color: ColorConstants.blackColor),
                    ),
                  ),
                ],
              ),
            ),
            divider(),
            ListTile(
              onTap: () {
                userProfilController.switchLang('tr');
                Get.back();
              },
              leading: const CircleAvatar(
                backgroundImage: AssetImage(
                  IconConstants.tmIcon,
                ),
                backgroundColor: ColorConstants.blackColor,
                radius: 20,
              ),
              title: const Text(
                'Türkmen',
                style: TextStyle(color: ColorConstants.blackColor),
              ),
            ),
            divider(),
            ListTile(
              onTap: () {
                userProfilController.switchLang('ru');
                Get.back();
              },
              leading: const CircleAvatar(
                backgroundImage: AssetImage(
                  IconConstants.ruIcon,
                ),
                radius: 20,
                backgroundColor: ColorConstants.blackColor,
              ),
              title: const Text(
                'Русский',
                style: TextStyle(color: ColorConstants.blackColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void logOut() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(color: ColorConstants.whiteColor),
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 15,
                right: 15,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const SizedBox.shrink(),
                  Text(
                    'log_out'.tr,
                    style: const TextStyle(
                      color: ColorConstants.blackColor, //fontFamily: normProBold,
                      fontSize: 18,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: const Icon(CupertinoIcons.xmark_circle, size: 22, color: ColorConstants.blackColor),
                  ),
                ],
              ),
            ),
            divider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: Text(
                'log_out_title'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorConstants.greyColor,
                  //fontFamily: normsProMedium,
                  fontSize: 16,
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                Get.find<UserProfilController>().userLogin.value = false;
                await Auth().logout();
                await Get.offAll(() => BottomNavBar());
              },
              child: Container(
                width: Get.size.width,
                margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: ColorConstants.greyColor, borderRadius: CustomBorderRadius.lowBorderRadius),
                child: Text(
                  'yes'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ColorConstants.whiteColor, fontSize: 16),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                Get.back();
              },
              child: Container(
                width: Get.size.width,
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: ColorConstants.redColor, borderRadius: CustomBorderRadius.lowBorderRadius),
                child: Text(
                  'no'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ColorConstants.whiteColor, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static downloadDialog(BuildContext context) {
    final ProductProfilController productProfilController = Get.find();

    Get.dialog(
      Center(
        child: Container(
          width: WidgetSizes.size220.value,
          height: WidgetSizes.size220.value,
          padding: context.padding.normal,
          decoration: BoxDecoration(color: ColorConstants.whiteColor, borderRadius: context.border.normalBorderRadius, boxShadow: [BoxShadow(color: ColorConstants.greyColor, spreadRadius: 3, blurRadius: 4)]),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: ColorConstants.primaryColor),
                const SizedBox(height: 25),
                Obx(
                  () => Text(
                    'downloadedYakalar'.tr + '${productProfilController.sany.value}/${productProfilController.totalSum.value}',
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    style: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<dynamic> askToDownloadYaka({required int index, required BuildContext context, required Function() downloadYaka}) {
    return Get.defaultDialog(
      title: 'Üns ber',
      contentPadding: context.padding.normal,
      titlePadding: context.padding.onlyTopNormal,
      titleStyle: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: context.padding.normal.copyWith(top: 0),
            child: Text(
              'wantToBuyCollar'.tr,
              textAlign: TextAlign.center,
              style: context.general.textTheme.bodyLarge!.copyWith(fontSize: 20),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: context.padding.low,
                  child: ElevatedButton(
                    onPressed: downloadYaka,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: context.border.lowBorderRadius),
                      padding: context.padding.low,
                    ),
                    child: Text(
                      'agree'.tr,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: context.general.textTheme.bodyLarge!.copyWith(fontSize: 20, color: ColorConstants.whiteColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: context.padding.low,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.greyColor.withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: context.border.lowBorderRadius),
                      padding: context.padding.low,
                    ),
                    child: Text(
                      'no'.tr,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: context.general.textTheme.bodyLarge!.copyWith(fontSize: 18, color: ColorConstants.blackColor),
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

  static void showDownloadSuccessDialog({required BuildContext context}) {
    Get.dialog(
      Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          Center(
            child: Container(
              padding: context.padding.normal,
              margin: context.padding.normal,
              decoration: BoxDecoration(
                color: ColorConstants.whiteColor,
                borderRadius: context.border.normalBorderRadius,
                border: Border.all(color: ColorConstants.primaryColor, width: 2),
              ),
              child: Material(
                color: ColorConstants.whiteColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'downloadSuccessTitle'.tr,
                      textAlign: TextAlign.center,
                      style: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: context.padding.verticalNormal,
                      child: Text(
                        'downloadSuccessSubtitle'.tr,
                        style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: Text('close'.tr),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
