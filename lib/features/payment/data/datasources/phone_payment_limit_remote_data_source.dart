import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../domain/entities/phone_payment_limit_result.dart';

class PhonePaymentLimitRemoteDataSource {
  const PhonePaymentLimitRemoteDataSource({
    required this.baseUrl,
    required this.tokenProvider,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  /// Unknown availability is distinct from a real daily limit. The UI should
  /// not claim a reset time when the availability request fails.
  Future<PhonePaymentLimitResult> checkAvailability({
    required int amount,
  }) async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      return PhonePaymentLimitResult.empty();
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/phone'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
      );
      if (response.statusCode != 200 || response.body.isEmpty) {
        return PhonePaymentLimitResult.empty();
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        return PhonePaymentLimitResult.empty();
      }
      // Response shape:
      // {"data":["+99361697838"],"phone_type":{"name":"50+","slug":"50-plus"}}
      final phoneType = decoded['phone_type'];
      if (phoneType is! Map) {
        return PhonePaymentLimitResult.empty();
      }
      final slug = phoneType['slug']?.toString().toLowerCase();
      final name = phoneType['name']?.toString().toLowerCase();
      final is20Plus = slug == '20-plus' || name == '20+';
      final phoneList = decoded['data'];
      final phoneNumber = (phoneList is List && phoneList.isNotEmpty)
          ? phoneList.first?.toString() ?? ''
          : '';

      if (is20Plus) {
        return PhonePaymentLimitResult.available(
          availableAmounts: const {20, 30, 40, 50},
          phoneNumber: phoneNumber,
        );
      }
      const availableAmounts = <int>{50};
      if (availableAmounts.contains(amount)) {
        return PhonePaymentLimitResult.available(
          availableAmounts: availableAmounts,
          phoneNumber: phoneNumber,
        );
      }
      return PhonePaymentLimitResult.blocked(
        _nextResetAt(),
        availableAmounts: availableAmounts,
      );
    } catch (_) {
      return PhonePaymentLimitResult.empty();
    }
  }

  static DateTime _nextResetAt() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0);
  }
}
