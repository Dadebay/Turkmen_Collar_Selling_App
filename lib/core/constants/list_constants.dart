import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ListConstants {
  static String appVersion = '3.2.2';

  static Future<void> initAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    } catch (_) {}
  }

  static const List<String> pageNames = [
    'home',
    'favorites',
    'cart',
    'settings',
  ];

  static const List<IconlyLight> mainIcons = [
    IconlyLight.home,
    IconlyLight.heart,
    IconlyLight.bag2,
    IconlyLight.profile,
  ];

  static const List<IconlyBold> selectedIcons = [
    IconlyBold.home,
    IconlyBold.heart,
    IconlyBold.bag2,
    IconlyBold.profile,
  ];

  static List sortData = [
    {'id': 1, 'name': 'sortDefault', 'sort_column': ''},
    {'id': 2, 'name': 'sortPriceLowToHigh', 'sort_column': 'expensive'},
    {'id': 3, 'name': 'sortPriceHighToLow', 'sort_column': 'cheap'},
    {'id': 4, 'name': 'sortCreatedAtHighToLow', 'sort_column': 'latest'},
    {'id': 5, 'name': 'sortCreatedAtLowToHigh', 'sort_column': 'oldest'},
    {'id': 6, 'name': 'sortViews', 'sort_column': 'views'},
  ];

  static const List<String> cities = [
    'Aşgabat',
    'Ahal',
    'Mary',
    'Lebap',
    'Daşoguz',
    'Balkan',
  ];
}
