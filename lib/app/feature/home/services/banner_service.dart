import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/home/models/banner_model.dart';

import '../../auth/services/auth_service.dart';

class BannerService {
  Future<List<BannerModel>> getBanners() async {
    final token = await Auth().getToken();
    final List<BannerModel> bannerList = [];
    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/banners',
      ),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final responseJson = json.decode(decoded);
      for (final Map product in responseJson['data']) {
        bannerList.add(BannerModel.fromJson(product));
      }
      return bannerList;
    } else {
      return [];
    }
  }
}

Future<BannerModel> getBannerByID(int id) async {
  final token = await Auth().getToken();

  final response = await http.get(
    Uri.parse(
      '${Auth.serverURL}/api/v1/banners/$id',
    ),
    headers: <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      HttpHeaders.authorizationHeader: 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    final decoded = utf8.decode(response.bodyBytes);
    final responseJson = json.decode(decoded);
    return BannerModel.fromJson(responseJson);
  } else {
    return BannerModel();
  }
}
