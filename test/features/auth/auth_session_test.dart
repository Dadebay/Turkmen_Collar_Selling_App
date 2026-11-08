import 'package:flutter_test/flutter_test.dart';
import 'package:yaka2/core/models/user_me_model.dart';
import 'package:yaka2/core/result/result.dart';
import 'package:yaka2/core/services/account_remote_data_source.dart';
import 'package:yaka2/core/storage/local_storage.dart';
import 'package:yaka2/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:yaka2/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:yaka2/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:yaka2/features/auth/domain/repositories/auth_repository.dart';
import 'package:yaka2/features/auth/domain/usecases/logout_usecase.dart';
import 'package:yaka2/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:yaka2/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:yaka2/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  test('token validation preserves network failures', () async {
    final storage = _TokenStorage();
    final repository = AuthRepositoryImpl(
      local: AuthLocalDataSource(storage),
      remote: const AuthRemoteDataSource(baseUrl: 'https://example.com'),
      account: _OfflineAccount(storage),
    );

    final result = await repository.validateToken();
    expect(result, isA<Failure<bool>>());
    expect((result as Failure<bool>).failure, isA<NetworkFailure>());
  });

  test('startup keeps the session on a temporary network failure', () async {
    final repository = _AuthRepository(const Failure(NetworkFailure()));
    final bloc = _createBloc(repository);
    final states = expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
    );

    bloc.add(const AuthCheckRequested(platform: 'android', version: '1.0.0'));
    await states;
    expect(repository.logoutCount, 0);
    await bloc.close();
  });

  test('startup clears a session rejected by the server', () async {
    final repository = _AuthRepository(const Failure(AuthFailure()));
    final bloc = _createBloc(repository);
    final states = expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
    );

    bloc.add(const AuthCheckRequested(platform: 'android', version: '1.0.0'));
    await states;
    expect(repository.logoutCount, 1);
    await bloc.close();
  });
}

AuthBloc _createBloc(AuthRepository repository) => AuthBloc(
  repository: repository,
  sendOtp: SendOtpUseCase(repository),
  verifyOtp: VerifyOtpUseCase(repository),
  logout: LogoutUseCase(repository),
);

class _TokenStorage extends LocalStorage {
  @override
  String? get token => 'saved-token';
}

class _OfflineAccount extends AccountRemoteDataSource {
  _OfflineAccount(LocalStorage storage)
    : super(baseUrl: 'https://example.com', localStorage: storage);

  @override
  Future<Result<UserMeModel>> getCurrentUser({
    bool forceRefresh = false,
  }) async => const Failure(NetworkFailure());
}

class _AuthRepository implements AuthRepository {
  _AuthRepository(this.result);

  final Result<bool> result;
  int logoutCount = 0;

  @override
  Future<int> checkAppVersion({
    required String platform,
    required String version,
  }) async => 1;

  @override
  Future<bool> hasValidToken() async => true;

  @override
  Future<Result<bool>> validateToken() async => result;

  @override
  Future<void> logout() async => logoutCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
