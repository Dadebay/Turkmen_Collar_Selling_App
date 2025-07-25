import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/home/models/product_model.dart';

import '../../auth/services/auth_service.dart';

class FavService {
  Future<List<ProductModel>> getProductFavList() async {
    final token = await Auth().getToken();

    final List<ProductModel> favListProducts = [];
    final response = await http.get(
      Uri.parse('${Auth.serverURL}/api/v1/users/me/favorite-products'),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      if (token == null) {
        return favListProducts;
      } else {
        final responseJson = json.decode(response.body);
        for (final Map<dynamic, dynamic> product in responseJson['data']) {
          favListProducts.add(ProductModel.fromJson(product));
        }
        return favListProducts;
      }
    } else {
      return [];
    }
  }

  Future<List<ProductModel>> getCollarFavList() async {
    final token = await Auth().getToken();
    final List<ProductModel> favListCollar = [];
    final response = await http.get(
      Uri.parse('${Auth.serverURL}/api/v1/users/me/favorites'),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    print('__________________________________________________________________________________________________________');
    print(response.body);
    if (response.statusCode == 200) {
      if (token == null) {
        return favListCollar;
      } else {
        final responseJson = json.decode(response.body);
        for (final Map product in responseJson['data']) {
          favListCollar.add(ProductModel.fromJson(product)..downloadable = true);
        }
        return favListCollar;
      }
    } else {
      return [];
    }
  }

  Future addProductToFav({required int id}) async {
    final token = await Auth().getToken();
    final headers = {
      'Authorization': 'Bearer $token',
    };
    final request = http.MultipartRequest('POST', Uri.parse('${Auth.serverURL}/api/v1/users/me/favorite-products'));
    request.fields.addAll({'product_id': '$id'});
    request.headers.addAll(headers);
    final http.StreamedResponse response = await request.send();
    return response.statusCode;
  }

  Future deleteProductToFav({required int id}) async {
    final token = await Auth().getToken();
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final request = http.Request('DELETE', Uri.parse('${Auth.serverURL}/api/v1/users/me/favorite-products'));
    request.bodyFields = {'product_id': '$id'};
    request.headers.addAll(headers);
    final http.StreamedResponse response = await request.send();
    return response.statusCode;
  }

  Future addCollarToFav({required int id}) async {
    final token = await Auth().getToken();
    final headers = {
      'Authorization': 'Bearer $token',
    };
    final request = http.MultipartRequest('POST', Uri.parse('${Auth.serverURL}/api/v1/users/me/favorites'));
    request.fields.addAll({'collar_id': '$id'});
    request.headers.addAll(headers);
    final http.StreamedResponse response = await request.send();
    return response.statusCode;
  }

  Future deleteCollarToFav({required int id}) async {
    final token = await Auth().getToken();
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final request = http.Request('DELETE', Uri.parse('${Auth.serverURL}/api/v1/users/me/favorites'));
    request.bodyFields = {'collar_id': '$id'};
    request.headers.addAll(headers);
    final http.StreamedResponse response = await request.send();
    return response.statusCode;
  }
}
