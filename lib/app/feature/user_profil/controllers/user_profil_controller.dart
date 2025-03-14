import 'dart:ui';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UserProfilController extends GetxController {
  final RxBool userLogin = false.obs;
  final RxString phoneNumber = '+99364030911'.obs;

  final storage = GetStorage();

  var tm = const Locale(
    'tr',
  );
  var ru = const Locale(
    'ru',
  );
  var en = const Locale(
    'en',
  );

  dynamic switchLang(String value) {
    if (value == 'en') {
      Get.updateLocale(en);
      storage.write('langCode', 'en');
    } else if (value == 'ru') {
      Get.updateLocale(ru);
      storage.write('langCode', 'ru');
    } else {
      Get.updateLocale(tm);
      storage.write('langCode', 'tr');
    }
    update();
  }
}
