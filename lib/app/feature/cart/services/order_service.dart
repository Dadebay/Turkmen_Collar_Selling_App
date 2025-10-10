import 'dart:convert';

import 'package:http/http.dart' as http;

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
    request.headers.addAll(headers);
    final http.StreamedResponse response = await request.send();


    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }
}
