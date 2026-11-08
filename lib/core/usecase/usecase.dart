import '../result/result.dart';

abstract interface class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

abstract interface class UseCaseNoParams<Type> {
  Future<Result<Type>> call();
}

class NoParams {
  const NoParams();
}
