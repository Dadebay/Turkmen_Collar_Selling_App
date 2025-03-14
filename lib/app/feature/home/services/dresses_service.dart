import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/home/controllers/clothes_controller.dart';
import 'package:yaka2/app/feature/home/models/clothes_model.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';

import '../../auth/services/auth_service.dart';

class DressesService {
  final ClothesController clothesController = Get.put(ClothesController());
  Future<List<ProductModel>> getDresses({required Map<String, dynamic> parametrs}) async {
    final token = await Auth().getToken();
    final List<ProductModel> collarList = [];
    final response = await http.get(
      Uri.parse('${Auth.serverURL}/api/v1/products').replace(queryParameters: parametrs),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      clothesController.clothesLoading.value = 2;
      final responseJson = json.decode(response.body);
      for (final Map product in responseJson['data']) {
        collarList.add(ProductModel.fromJson(product));
      }
      clothesController.clothesLoading.value = 3;
      return collarList;
    } else {
      clothesController.clothesLoading.value = 1;
      return [];
    }
  }

  Future<List<ProductModel>> getGoods({required Map<String, dynamic> parametrs}) async {
    final token = await Auth().getToken();
    final List<ProductModel> collarList = [];
    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/sewing-products',
      ).replace(queryParameters: parametrs),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      for (final Map product in responseJson['data']) {
        collarList.add(ProductModel.fromJson(product));
      }
      return collarList;
    } else {
      return [];
    }
  }

  Future<DressesModelByID> getDressesByID(int id) async {
    final token = await Auth().getToken();
    final fcmToken = await FirebaseMessaging.instance.getToken(); // FCM token'ını almak için

    final response = await http.get(
      Uri.parse('${Auth.serverURL}/api/v1/products/$id?fcm_token=$fcmToken'), // fcm_token'ı query parameter olarak ekledik
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    log('Get Dresses By ID Response: ${response.body}');
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      return DressesModelByID.fromJson(responseJson);
    } else {
      return DressesModelByID();
    }
  }
}
