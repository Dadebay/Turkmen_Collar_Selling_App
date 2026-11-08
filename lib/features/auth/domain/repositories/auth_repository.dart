import '../../../../core/result/result.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<String?> getToken();
  Future<int?> getCustomerId();
  Future<String?> getPhone();
  Future<bool> hasValidToken();
  Future<Result<bool>> validateToken();
  Future<Result<void>> sendOtp({required String phone, String? deviceToken});
  Future<Result<UserEntity>> verifyOtp({
    required String phone,
    required String otp,
    String? deviceToken,
  });
  Future<void> logout();
  Future<int> checkAppVersion({
    required String platform,
    required String version,
  });
}
