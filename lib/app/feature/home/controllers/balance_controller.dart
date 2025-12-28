import 'dart:developer';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yaka2/app/feature/auth/services/auth_service.dart';
import 'package:yaka2/app/feature/user_profil/controllers/user_profil_controller.dart';
import 'package:yaka2/app/feature/user_profil/services/about_us_service.dart';

class BalanceController extends GetxController {
  RxString balance = '0'.obs;
  final storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    userMoney();
  }

  Future<String> returnPhoneNumber() async {
    String number = '';
    if (await storage.read('phoneNumber') == null) {
      number = 'belginiz yok';
    } else {
      number = await storage.read('phoneNumber');
    }
    return number;
  }

  dynamic userMoney() async {
    final token = await Auth().getToken();

    final UserProfilController controller = Get.put(UserProfilController());
    if (token == null) {
      balance.value = '0';
      controller.userLogin.value = false;
    } else {
      try {
        await AboutUsService().getuserData().then((value) {
          // Check if balance is not null before dividing
          if (value.balance != null) {
            balance.value = '${value.balance! / 100}';
          } else {
            balance.value = '0';
          }
        });
        controller.userLogin.value = true;
      } catch (e) {
        // If there's any error, set balance to 0 and user as not logged in
        balance.value = '0';
        controller.userLogin.value = false;
        print('Error getting user data: $e');
      }
    }
  }
}
