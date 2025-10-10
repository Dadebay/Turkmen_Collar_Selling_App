// ignore_for_file: avoid_slow_async_io

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/cart/views/cart_view.dart';
import 'package:yaka2/app/feature/favorites/views/favorites_view.dart';
import 'package:yaka2/app/feature/user_profil/views/about_us_view.dart';
import 'package:yaka2/app/feature/user_profil/views/add_money.dart';
import 'package:yaka2/app/feature/user_profil/views/history_order.dart';
import 'package:yaka2/app/feature/user_profil/views/user_profil_view.dart';

import '../../feature/auth/views/user_login_view.dart';
import '../../feature/home/views/home_view.dart';
import '../../feature/user_profil/views/downloaded_view.dart';
import '../utils/dialog_utils.dart';
import 'index.dart';

@immutable
class ListConstants {
  static List profilePageIcons = [
    {
      'name': Get.locale!.toLanguageTag() == 'tr' ? 'Türkmen dili' : 'Rus dili',
      'langIconsStatus': true,
      'langIcon': Container(
        width: 35,
        height: 35,
        margin: const EdgeInsets.only(top: 3),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: ColorConstants.redColor),
        child: ClipRRect(
          borderRadius: CustomBorderRadius.normalBorderRadius,
          child: Image.asset(
            Get.locale!.toLanguageTag() == 'tr' ? IconConstants.tmIcon : IconConstants.ruIcon,
            fit: BoxFit.cover,
          ),
        ),
      ),
      'showOnLogin': false,
      'icon': Icons.usb,
      'onTap': () async {
        DialogUtils.changeLanguage();
      },
    },
    {
      'name': 'open_folder',
      'langIconsStatus': false,
      'langIcon': customIcon(IconConstants.usbIcon),
      'showOnLogin': true,
      'icon': Icons.folder_open,
      'onTap': () async {
        // const downloadsPath = '/storage/emulated/0/Download';
        final bool success = await openDownloadFolder();
        if (success) {
        } else {
        }
      },
    },
    {
      'name': 'addMoney',
      'langIconsStatus': false,
      'icon': IconlyLight.wallet,
      'langIcon': null,
      'showOnLogin': true,
      'onTap': () async {
        await Get.to(() => const AddCash());
      },
    },
    {
      'name': 'orders',
      'langIconsStatus': false,
      'icon': CupertinoIcons.cube_box,
      'langIcon': null,
      'showOnLogin': true,
      'onTap': () {
        Get.to(() => const HistoryOrders());
      },
    },
    {
      'name': 'downloaded',
      'langIconsStatus': false,
      'icon': IconlyLight.download,
      'langIcon': null,
      'showOnLogin': true,
      'onTap': () async {
        await Get.to(() => const DownloadedView());
      },
    },
    // {
    //   'name': 'questions',
    //   'langIconsStatus': false,
    //   'icon': IconlyLight.document,
    //   'langIcon': null,
    //   'showOnLogin': false,
    //   'onTap': () {
    //     Get.to(() => const FAQ());
    //   },
    // },
    {
      'name': 'aboutUs',
      'langIconsStatus': false,
      'icon': IconlyLight.user3,
      'langIcon': null,
      'showOnLogin': false,
      'onTap': () {
        Get.to(() => const AboutUsView());
      },
    },
    {
      'name': 'deleteAccount',
      'langIconsStatus': false,
      'icon': IconlyLight.delete,
      'langIcon': null,
      'showOnLogin': true,
      'onTap': () async {
        DialogUtils.logOut();
      },
    },
    {
      'name': 'signUp',
      'langIconsStatus': false,
      'icon': IconlyLight.login,
      'langIcon': null,
      'showOnLogin': false,
      'onTap': () async {
        await Get.to(() => UserLoginView());
      },
    },
  ];
  static List sortData = [
    {
      'id': 1,
      'name': 'sortDefault',
      'sort_column': '',
    },
    {
      'id': 2,
      'name': 'sortPriceLowToHigh',
      'sort_column': 'expensive',
    },
    {
      'id': 3,
      'name': 'sortPriceHighToLow',
      'sort_column': 'cheap',
    },
    {
      'id': 4,
      'name': 'sortCreatedAtHighToLow',
      'sort_column': 'latest',
    },
    {
      'id': 5,
      'name': 'sortCreatedAtLowToHigh',
      'sort_column': 'oldest',
    },
    {
      'id': 6,
      'name': 'sortViews',
      'sort_column': 'views',
    },
  ];
  static List cities = [
    'Aşgabat',
    'Ahal',
    'Mary',
    'Lebap',
    'Daşoguz',
    'Balkan',
  ];
  static List pageNames = [
    'home',
    'favorites',
    'cart',
    'settings',
  ];
  static List<IconData> mainIcons = [IconlyLight.home, IconlyLight.heart, IconlyLight.bag2, IconlyLight.profile];
  static List<IconData> selectedIcons = [IconlyBold.home, IconlyBold.heart, IconlyBold.bag2, IconlyBold.profile];
  static List<Widget> pages = [HomeView(), FavoritesView(), CartView(), UserProfilView()];
}
