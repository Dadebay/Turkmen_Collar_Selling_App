import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:yaka2/app/feature/home/models/product_model.dart';

import '../../auth/services/auth_service.dart';

class MachineService {
  Future<List<ProductModel>> getMachines() async {
    final token = await Auth().getToken();

    final List<ProductModel> machineList = [];
    final response = await http.get(
      Uri.parse('${Auth.serverURL}/api/v1/machines'),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      for (final Map product in responseJson['data']) {
        machineList.add(ProductModel.fromJson(product));
      }
      return machineList;
    } else {
      return [];
    }
  }

  Future<ProductModel> getMachineByID(int id) async {
    final token = await Auth().getToken();
    final response = await http.get(
      Uri.parse(
        '${Auth.serverURL}/api/v1/products/$id',
      ),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
    log(response.body.toString());
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      return ProductModel.fromJson(responseJson);
    } else {
      return ProductModel(id: 0, name: '', createdAt: '', image: '', price: '', categoryName: '', downloadable: false);
    }
  }
}
