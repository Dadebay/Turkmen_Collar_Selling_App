import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpParams {
  const VerifyOtpParams({
    required this.phone,
    required this.otp,
    this.deviceToken,
  });
  final String phone;
  final String otp;
  final String? deviceToken;
}

class VerifyOtpUseCase implements UseCase<UserEntity, VerifyOtpParams> {
  const VerifyOtpUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<UserEntity>> call(VerifyOtpParams params) =>
      _repository.verifyOtp(
        phone: params.phone,
        otp: params.otp,
        deviceToken: params.deviceToken,
      );
}
