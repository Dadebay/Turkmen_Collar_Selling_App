import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/cart/models/history_order_model.dart';

import '../../auth/services/auth_service.dart';

class HistoryOrderService {
  Future<List<HistoryOrderModel>> getHistoryOrders() async {
    final token = await Auth().getToken();

    final List<HistoryOrderModel> products = [];
    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/users/me/orders',
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
        products.add(HistoryOrderModel.fromJson(product));
      }
      return products;
    } else {
      return [];
    }
  }

  Future<List<ProductsModelMini>> getHistoryOrderByID(int id) async {
    final token = await Auth().getToken();
    final List<ProductsModelMini> products = [];

    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/users/me/orders/$id',
      ),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final responseJson = json.decode(decoded);
      for (final Map product in responseJson['products']) {
        products.add(ProductsModelMini.fromJson(product));
      }
      return products;
    } else {
      return [];
    }
  }
}
