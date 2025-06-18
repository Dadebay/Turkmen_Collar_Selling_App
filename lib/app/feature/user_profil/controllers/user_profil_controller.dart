import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/auth/services/auth_service.dart';

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

  Future<String?> sendTransactionSMS({
    required String sender,
    required String amount,
  }) async {
    print(sender);
    print(amount);
    print('${Auth.serverURL}/api/v1/online-transactions');
    final response = await http.post(
      Uri.parse('${Auth.serverURL}/api/v1/online-transactions'),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'phone': '$sender',
        'amount': amount,
        'token': 'BYAhDQAAAIOyop/ximLMMwI=',
      }),
    );
    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['formUrl']; // burayı döndürüyoruz
    } else {
      return null;
    }
  }
}
