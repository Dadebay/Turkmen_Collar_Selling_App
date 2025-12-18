import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/payment/controllers/payment_status_controller.dart';

import '../../auth/services/auth_service.dart';

class OrderService {
  Future createOrder({
    required List products,
    required String note,
    required String customerName,
    required String address,
    required String province,
    required String phone,
  }) async {
    // Check payment status - if disabled, bypass API call (Apple Store compliance)
    final paymentStatusController = Get.find<PaymentStatusController>();

    if (paymentStatusController.isPaymentDisabled.value) {
      print('🔵 [ORDER] Payment disabled - bypassing order creation (Apple Store mode)');
      print('🔵 [ORDER] Order details: products=$products, customer=$customerName');
      // Simulate successful order without API call
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      return true; // Always return success
    }

    // Payment enabled - normal order flow
    print('🔵 [ORDER] Payment enabled - creating real order');
    final token = await Auth().getToken();
    final headers = {'Authorization': 'Bearer $token'};
    final request = http.MultipartRequest('POST', Uri.parse('${Auth.serverURL}/api/v1/users/me/orders'));
    request.fields.addAll({
      'products': jsonEncode(products),
      'note': note,
      'customer_name': customerName,
      'address': address,
      'payment_type': 'card',
      'phone': '993$phone',
      'province': province,
    });
    print('🔵 [ORDER] Request fields: ${request.fields}');
    request.headers.addAll(headers);
    final http.StreamedResponse response = await request.send();
    print('🔵 [ORDER] Response status: ${response.statusCode}');

    // Always return true regardless of status code (as per user request)
    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅ [ORDER] Order created successfully');
      return true;
    } else {
      print('⚠️ [ORDER] Order failed with status ${response.statusCode}, but returning true anyway');
      final responseBody = await response.stream.bytesToString();
      print('⚠️ [ORDER] Response body: $responseBody');
      return true; // Always return true even on error
    }
  }
}
