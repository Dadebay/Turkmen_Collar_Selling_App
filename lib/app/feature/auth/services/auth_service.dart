// ignore_for_file: file_names, require_trailing_commas, avoid_void_async, avoid_bool_literals_in_conditional_expressions

import 'package:get_storage/get_storage.dart';

class Auth {
  final storage = GetStorage();
  // static String serverURL = 'http://216.250.14.111';
  static String serverURL = 'https://yashelektrik.com';

  void login(String? data) async {
    await storage.write('data', data);
  }

  Future<bool> logout() async {
    await storage.remove('AccessToken');
    await storage.remove('RefreshToken');
    return storage.read('AccessToken') == null ? true : false;
  }

  /////////////////////////////////////////User Token///////////////////////////////////
  Future<bool> setToken(String token) async {
    await storage.write('AccessToken', token);
    return storage.read('AccessToken') == null ? false : true;
  }

  Future<String?> getToken() async {
    return storage.read('AccessToken');
  }

  Future<bool> removeToken() async {
    await storage.remove('AccessToken');
    return storage.read('AccessToken') == null ? true : false;
  }
}
