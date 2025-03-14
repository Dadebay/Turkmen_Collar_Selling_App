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
      log('Categories Response: $responseJson');

      for (final Map product in responseJson['data']) {
        categoryList.add(CategoryModel.fromJson(product));
      }

      return categoryList;
    } else {
      return [];
    }
  }

  Future<List<ProductModel>> getCategoryByID({
    required int id,
    required Map<String, String> parametrs,
  }) async {
    final token = await Auth().getToken();
    final List<ProductModel> categoryList = [];
    final List<ProductModel> productList = [];

    final response = await http.get(
      Uri.parse('${Auth.serverURL}/api/v1/categories/$id').replace(queryParameters: parametrs),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    if (response.statusCode == 200) {
      final responseJson = json.decode(decodedBody);
      if (ProductModel.fromJson(responseJson).name == 'Ýakalar') {
        for (final Map product in responseJson['collars']['data']) {
          categoryList.add(ProductModel.fromJson(product));
        }
        return categoryList;
      } else {
        for (final Map product in responseJson['products']['data']) {
          productList.add(ProductModel.fromJson(product));
        }
        return productList;
      }
    } else {
      return [];
    }
  }
}
