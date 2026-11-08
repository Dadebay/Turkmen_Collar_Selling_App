import '../../../../core/result/result.dart';
import '../../../../core/services/account_remote_data_source.dart';
import '../../../ai_chat/data/datasources/chat_socket_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthLocalDataSource local,
    required AuthRemoteDataSource remote,
    required AccountRemoteDataSource account,
  }) : _local = local,
       _remote = remote,
       _account = account;

  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;
  final AccountRemoteDataSource _account;

  @override
  Future<String?> getToken() async => _local.token;

  @override
  Future<int?> getCustomerId() async => _local.customerId;

  @override
  Future<String?> getPhone() async => _local.phone;

  @override
  Future<bool> hasValidToken() async {
    final t = _local.token;
    return t != null && t.isNotEmpty;
  }

  @override
  Future<Result<bool>> validateToken() async {
    final t = _local.token;
    if (t == null || t.isEmpty) {
      return const Success(false);
    }
    // A successful `users/me` fetch both proves the token is valid and warms
    // the shared cache (incl. wallet balance) for the home screen.
    final result = await _account.getCurrentUser(forceRefresh: true);
    return switch (result) {
      Success() => const Success(true),
      Failure(:final failure) => Failure(failure),
    };
  }

  @override
  Future<Result<void>> sendOtp({required String phone, String? deviceToken}) =>
      _remote.sendOtp(phone: phone, deviceToken: deviceToken);

  @override
  Future<Result<UserEntity>> verifyOtp({
    required String phone,
    required String otp,
    String? deviceToken,
  }) async {
    final result = await _remote.verifyOtp(
      phone: phone,
      otp: otp,
      deviceToken: deviceToken,
    );
    return result.when(
      success: (model) async {
        await _local.saveToken(model.token);
        await _local.saveCustomerId(model.id);
        await _local.savePhone(phone);
        _account.invalidate();
        return Success(model.toEntity());
      },
      failure: Failure.new,
    );
  }

  @override
  Future<void> logout() async {
    _account.invalidate();
    ChatSocketService().disconnect();
    await _local.clearAuth();
  }

  @override
  Future<int> checkAppVersion({
    required String platform,
    required String version,
  }) => _remote.checkAppVersion(platform: platform, version: version);
}
