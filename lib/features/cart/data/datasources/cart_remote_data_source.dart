import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';

class CartRemoteDataSource {
  const CartRemoteDataSource({
    required this.baseUrl,
    required this.tokenProvider,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  Future<Result<void>> placeOrder({
    required List<Map<String, dynamic>> products,
    required String customerName,
    required String address,
    required String province,
    required String phone,
    required String note,
  }) async {
    try {
      final token = await tokenProvider();
      if (token == null) {
        return const Failure(AuthFailure());
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/users/me/orders'),
      );
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      request.fields.addAll({
        'products': jsonEncode(products),
        'note': note,
        'customer_name': customerName,
        'address': address,
        'payment_type': 'card',
        'phone': '993$phone',
        'province': province,
      });
      final response = await http.send(request);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Success(null);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }
}
