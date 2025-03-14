import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/cart/models/downloads_model.dart';

import '../../auth/services/auth_service.dart';

class DownloadsService {
  Future<List<DownloadsModel>> getDownloadedProducts() async {
    final token = await Auth().getToken();

    final List<DownloadsModel> downoadPorducts = [];
    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/users/me/downloads',
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
        downoadPorducts.add(DownloadsModel.fromJson(product));
      }
      return downoadPorducts;
    } else {
      return [];
    }
  }
}
