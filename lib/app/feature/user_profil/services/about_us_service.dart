import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/user_profil/controllers/user_profil_controller.dart';
import 'package:yaka2/app/feature/user_profil/models/about_us_model.dart';

import '../../auth/services/auth_service.dart';

class AboutUsService {
  Future<AboutUsModel> getAboutUs() async {
    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/about/',
      ),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final responseJson = json.decode(decoded);
      parsePhoneNumber(response.body);
      return AboutUsModel.fromJson(responseJson);
    } else {
      return AboutUsModel();
    }
  }

  void parsePhoneNumber(String responseBody) {
    final decoded = utf8.decode(responseBody.codeUnits);
    final responseJson = json.decode(decoded);
    final UserProfilController controller = Get.put(UserProfilController());
    //   "body" anahtarını kontrol et ve telefon numaralarını ayır
    if (responseJson['body'] != null) {
      final body = responseJson['body'];
      final phoneNumbers = body.split('\r\n');

      final phoneNumber1 = phoneNumbers.length > 0 ? phoneNumbers[0] : '';
      controller.phoneNumber.value = phoneNumber1;
    }
  }

  Future<List<FAQModel>> getFAQ() async {
    final List<FAQModel> faqList = [];

    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/faqs',
      ),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final responseJson = json.decode(decoded);
      for (final Map product in responseJson['data']) {
        faqList.add(FAQModel.fromJson(product));
      }
      return faqList;
    } else {
      return [];
    }
  }

  Future<UserMeModel> getuserData() async {
    final token = await Auth().getToken();
    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/users/me',
      ),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      try {
        final decoded = utf8.decode(response.bodyBytes);

        // Check if response starts with HTML
        if (decoded.trim().startsWith('<!DOCTYPE') || decoded.trim().startsWith('<html')) {
          log('Error: API returned HTML instead of JSON. Response: ${decoded.substring(0, 100)}...');
          return UserMeModel();
        }

        final responseJson = json.decode(decoded);
        return UserMeModel.fromJson(responseJson);
      } catch (e) {
        log('Error parsing JSON in getuserData: $e');
        log('Response body: ${response.body}');
        return UserMeModel();
      }
    } else {
      log('API call failed with status code: ${response.statusCode}');
      log('Response body: ${response.body}');
      return UserMeModel();
    }
  }

  Future<List<GetFilterElements>> getFilterElements() async {
    final List<GetFilterElements> machinesList = [];

    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/tags',
      ),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final responseJson = json.decode(decoded);
      for (final Map product in responseJson['data']) {
        machinesList.add(GetFilterElements.fromJson(product));
      }
      return machinesList;
    } else {
      return [];
    }
  }
}
