import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/auth/views/connection_check_view.dart';
import 'package:yaka2/app/feature/auth/views/otp_code_check_view.dart';
import 'package:yaka2/app/feature/home/controllers/home_controller.dart';
import 'package:yaka2/app/feature/user_profil/controllers/user_profil_controller.dart';

import '../../../product/constants/index.dart';
import 'auth_service.dart';

class SignInService {
  final UserProfilController userProfilController = Get.put(UserProfilController());

  final HomeController homeController = Get.find<HomeController>();
  final GetStorage storage = GetStorage();
  Future otpCheck({String? otp, String? phoneNumber}) async {
    final response = await http.post(
      Uri.parse('${Auth.serverURL}/api/v1/login/verify'),
      headers: <String, String>{HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, dynamic>{'phone': phoneNumber, 'otp': otp}),
    );
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      await Auth().setToken(responseJson['data']['api_token']);
      await storage.write('phoneNumber', phoneNumber);
      userProfilController.userLogin.value = true;
      showSnackBar('loginSuccess', 'loginSuccesSubtitle', ColorConstants.greenColor);
      await Get.offAll(() => ConnectionCheckpage());
      return true;
    } else {
      showSnackBar('otpErrorTitle', 'otpErrorSubtitle', ColorConstants.redColor);
      return response.statusCode;
    }
  }

  Future login({required String phone}) async {
    final response = await http.post(
      Uri.parse('${Auth.serverURL}/api/v1/login'),
      headers: <String, String>{HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{'phone': phone}),
    );
    if (phone == '+9962990344') {
      showSnackBar('OTP', response.body, ColorConstants.greenColor);
    }

    if (response.statusCode == 200) {
      homeController.agreeButton.value = false;
      await Get.to(() => OTPCodeCheckView(phoneNumber: phone));
    } else if (response.statusCode == 409) {
      showSnackBar('noConnection3', 'alreadyExist', ColorConstants.redColor);
    } else if (response.statusCode == 429) {
      showSnackBar('wait10MinTitle ', 'wait10Min', ColorConstants.redColor);
    } else {
      showSnackBar('noConnection3', 'errorData', ColorConstants.redColor);
    }
    return response.statusCode;
  }
}
