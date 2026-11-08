import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';
import '../models/history_order_model.dart';

class HistoryOrdersRemoteDataSource {
  const HistoryOrdersRemoteDataSource({
    required this.baseUrl,
    required this.tokenProvider,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  Future<Map<String, String>> _authHeaders() async {
    final token = await tokenProvider();
    return {
      HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  Future<Result<List<HistoryOrderModel>>> getHistoryOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/users/me/orders'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        return Success(
          data
              .whereType<Map>()
              .map((e) => HistoryOrderModel.fromJson(e))
              .toList(),
        );
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<Result<List<ProductsModelMini>>> getHistoryOrderById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/users/me/orders/$id'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final products = json['products'] as List? ?? [];
        return Success(
          products
              .whereType<Map>()
              .map((e) => ProductsModelMini.fromJson(e))
              .toList(),
        );
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }
}
