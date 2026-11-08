import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';

class PaymentStatusRemoteDataSource {
  const PaymentStatusRemoteDataSource({required this.baseUrl});

  final String baseUrl;

  /// `true` means payments are disabled (matches the backend field name).
  Future<Result<bool>> fetchPaymentDisabled() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/payment-status'),
            headers: const {
              HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Success(json['payment_status'] == true);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }
}
