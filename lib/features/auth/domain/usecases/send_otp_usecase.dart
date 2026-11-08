import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SendOtpParams {
  const SendOtpParams({required this.phone, this.deviceToken});
  final String phone;
  final String? deviceToken;
}

class SendOtpUseCase implements UseCase<void, SendOtpParams> {
  const SendOtpUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(SendOtpParams params) =>
      _repository.sendOtp(phone: params.phone, deviceToken: params.deviceToken);
}
