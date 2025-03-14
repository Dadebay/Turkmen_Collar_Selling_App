import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/home/models/collar_model.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';

import '../../auth/services/auth_service.dart';

class CollarService {
  Future<List<ProductModel>> getCollars({required Map<String, dynamic> parametrs}) async {
    final token = await Auth().getToken();

    final List<ProductModel> collarList = [];
    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/collars',
      ).replace(queryParameters: parametrs),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      for (final Map<dynamic, dynamic> product in responseJson['data']) {
        collarList.add(
          ProductModel.fromJson({
            ...product,
            'downloadable': true,
          }),
        );
      }
      return collarList;
    } else {
      return [];
    }
  }

  Future<CollarByIDModel> getCollarsByID(int id) async {
    final token = await Auth().getToken();
    final fcmToken = await FirebaseMessaging.instance.getToken(); // FCM token'ını almak için
    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/collars/$id?fcm_token=$fcmToken',
      ),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      return CollarByIDModel.fromJson(responseJson);
    } else {
      return CollarByIDModel();
    }
  }
}
