import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';

class PaymentTransactionRemoteDataSource {
  const PaymentTransactionRemoteDataSource({required this.baseUrl});

  final String baseUrl;

  /// Initiates an online card payment. Returns the form URL the user is
  /// redirected to in the embedded webview, or a failure on any error.
  Future<Result<String>> sendTransactionSMS({
    required String sender,
    required String amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/online-transactions'),
        headers: const {
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'phone': sender,
          'amount': amount,
          'token': 'BYAhDQAAAIOyop/ximLMMwI=',
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final formUrl = data['formUrl']?.toString();
        if (formUrl == null || formUrl.isEmpty) {
          return const Failure(ServerFailure('formUrl missing'));
        }
        return Success(formUrl);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }
}
