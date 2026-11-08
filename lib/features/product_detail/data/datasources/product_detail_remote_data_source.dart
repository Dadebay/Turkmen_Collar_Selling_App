import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';
import '../../../home/data/models/collar_model.dart';
import '../../../home/data/models/product_model.dart';

class ProductDetailRemoteDataSource {
  const ProductDetailRemoteDataSource({
    required this.baseUrl,
    required this.tokenProvider,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    return {
      HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  Future<Result<ProductModel>> getProductById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/products/$id'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(
          utf8.decode(response.bodyBytes),
        ) as Map<dynamic, dynamic>;
        return Success(ProductModel.fromJson(json));
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<Result<CollarModel>> getCollarById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/collars/$id'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(
          utf8.decode(response.bodyBytes),
        ) as Map<dynamic, dynamic>;
        return Success(CollarModel.fromJson(json));
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }
}
