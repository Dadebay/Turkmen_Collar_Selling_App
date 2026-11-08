sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);
  final AppFailure failure;
}

extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get dataOrThrow => (this as Success<T>).data;

  AppFailure get failureOrThrow => (this as Failure<T>).failure;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      final Success<T> s => success(s.data),
      final Failure<T> f => failure(f.failure),
    };
  }
}

sealed class AppFailure {
  const AppFailure(this.message);
  final String message;
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Cache error']);
}

final class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Unauthorized']);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Unknown error']);
}
