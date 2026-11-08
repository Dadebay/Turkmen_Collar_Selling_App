import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase implements UseCaseNoParams<void> {
  const LogoutUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call() async {
    await _repository.logout();
    return const Success(null);
  }
}
