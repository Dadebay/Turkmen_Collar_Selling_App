import 'dart:convert';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/auth/services/auth_service.dart';

class PaymentStatusService {
  final storage = GetStorage();
  static const String _cacheKey = 'payment_status';
  static const String _endpoint = '/api/v1/payment-status';

  /// Fetches payment status from API
  /// Returns true if payments should be disabled, false otherwise
  /// On error, returns false (payments enabled by default for safety)
  Future<bool> fetchPaymentStatus() async {
    try {
      print('🔵 [PAYMENT_STATUS] Fetching payment status from API...');

      final response = await http.get(
        Uri.parse('${Auth.serverURL}$_endpoint'),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ [PAYMENT_STATUS] Request timeout, using cached value or default');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        final bool paymentStatus = responseJson['payment_status'] ?? false;

        print('✅ [PAYMENT_STATUS] API Response: payment_status = $paymentStatus');

        // Cache the result
        await _cachePaymentStatus(paymentStatus);

        return paymentStatus;
      } else {
        print('⚠️ [PAYMENT_STATUS] API returned status code: ${response.statusCode}');
        return await _getCachedPaymentStatus();
      }
    } catch (e) {
      print('❌ [PAYMENT_STATUS] Error fetching payment status: $e');
      return await _getCachedPaymentStatus();
    }
  }

  /// Cache payment status locally
  Future<void> _cachePaymentStatus(bool status) async {
    await storage.write(_cacheKey, status);
    print('💾 [PAYMENT_STATUS] Cached payment status: $status');
  }

  /// Get cached payment status
  /// Returns false (payments enabled) if no cached value exists
  Future<bool> _getCachedPaymentStatus() async {
    final cachedValue = storage.read(_cacheKey);
    if (cachedValue != null) {
      print('📦 [PAYMENT_STATUS] Using cached value: $cachedValue');
      return cachedValue as bool;
    }
    print('📦 [PAYMENT_STATUS] No cached value, defaulting to false (payments enabled)');
    return false; // Default: payments enabled
  }

  /// Get payment status (from cache first, then API if needed)
  Future<bool> getPaymentStatus() async {
    final cachedValue = storage.read(_cacheKey);
    if (cachedValue != null) {
      print('📦 [PAYMENT_STATUS] Returning cached value: $cachedValue');
      return cachedValue as bool;
    }

    // If no cache, fetch from API
    return await fetchPaymentStatus();
  }

  /// Clear cached payment status (useful for testing)
  Future<void> clearCache() async {
    await storage.remove(_cacheKey);
    print('🗑️ [PAYMENT_STATUS] Cache cleared');
  }
}
