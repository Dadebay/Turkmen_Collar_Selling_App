import '../../../../core/storage/local_storage.dart';

class AuthLocalDataSource {
  const AuthLocalDataSource(this._storage);
  final LocalStorage _storage;

  String? get token => _storage.token;
  int? get customerId => _storage.customerId;
  String? get phone => _storage.phone;

  Future<void> saveToken(String token) => _storage.saveToken(token);
  Future<void> saveCustomerId(int id) => _storage.saveCustomerId(id);
  Future<void> savePhone(String phone) => _storage.savePhone(phone);
  Future<void> clearAuth() => _storage.clearAuth();
}
