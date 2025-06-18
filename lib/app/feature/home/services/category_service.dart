import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/home/models/category_model.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';

import '../../auth/services/auth_service.dart';

class CategoryService {
  Future<List<CategoryModel>> getCategories() async {
    final token = await Auth().getToken();
    final List<CategoryModel> categoryList = [];

    final response = await http.get(
      Uri.parse('${Auth.serverURL}/api/v1/categories'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );

    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final responseJson = json.decode(decodedBody);
      for (final Map<String, dynamic> product in responseJson['data']) {
        categoryList.add(CategoryModel.fromJson(product));
      }
      return categoryList;
    } else {
      return [];
    }
  }

  Future<List<ProductModel>> getCategoryByID({
    required int id,
    required Map<String, String> parameters,
  }) async {
    final token = await Auth().getToken();
    final uri = Uri.parse('${Auth.serverURL}/api/v1/categories/$id').replace(queryParameters: parameters);

    log(uri.toString());
    log(parameters.toString());
    final response = await http.get(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> responseJson = json.decode(decodedBody);

    List<ProductModel> categoryList = [];
    if (responseJson['collars'] != null && responseJson['collars']['data'] != null && responseJson['collars']['data'].isNotEmpty) {
      categoryList = (responseJson['collars']['data'] as List).map((product) => ProductModel.fromJson(product)).toList();
    } else if (responseJson['products'] != null && responseJson['products']['data'] != null) {
      categoryList = (responseJson['products']['data'] as List).map((product) => ProductModel.fromJson(product)).toList();
    }

    return categoryList;
  }

  static Future<List<ProductModel>> searchCollars({required String query}) async {
    final token = await Auth().getToken();
    final uri = Uri.parse('${Auth.serverURL}/api/v1/collars?q=$query');

    final response = await http.get(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> responseJson = json.decode(decodedBody);
    log(responseJson.toString());

    final List<ProductModel> categoryList = (responseJson['data'] as List)
        .map(
          (product) => ProductModel.fromJson({...product, 'downloadable': true}),
        )
        .toList();

    return categoryList;
  }
}
