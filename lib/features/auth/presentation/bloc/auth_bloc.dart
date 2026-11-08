import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required SendOtpUseCase sendOtp,
    required VerifyOtpUseCase verifyOtp,
    required LogoutUseCase logout,
  }) : _repository = repository,
       _sendOtp = sendOtp,
       _verifyOtp = verifyOtp,
       _logout = logout,
       super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSendOtpRequested>(_onSendOtp);
    on<AuthVerifyOtpRequested>(_onVerifyOtp);
    on<AuthLogoutRequested>(_onLogout);
  }

  final AuthRepository _repository;
  final SendOtpUseCase _sendOtp;
  final VerifyOtpUseCase _verifyOtp;
  final LogoutUseCase _logout;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final capabilityType = await _repository.checkAppVersion(
      platform: event.platform,
      version: event.version,
    );

    if (capabilityType == 3) {
      emit(const AuthForceUpdate());
      return;
    }

    final hasToken = await _repository.hasValidToken();
    if (hasToken) {
      final result = await _repository.validateToken();
      switch (result) {
        case Success(data: true):
          emit(
            capabilityType == 2
                ? const AuthOptionalUpdate()
                : const AuthAuthenticated(),
          );
        case Success() || Failure(failure: AuthFailure()):
          await _repository.logout();
          emit(const AuthUnauthenticated());
        case Failure(:final failure):
          // A network or server outage does not invalidate the saved token.
          emit(AuthError(failure.message));
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSendOtp(
    AuthSendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _sendOtp(
      SendOtpParams(phone: event.phone, deviceToken: event.deviceToken),
    );
    result.when(
      success: (_) => emit(AuthOtpSent(phone: event.phone)),
      failure: (f) => emit(AuthError(f.message)),
    );
  }

  Future<void> _onVerifyOtp(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _verifyOtp(
      VerifyOtpParams(
        phone: event.phone,
        otp: event.otp,
        deviceToken: event.deviceToken,
      ),
    );
    result.when(
      success: (_) => emit(const AuthOtpVerified()),
      failure: (f) => emit(AuthError(f.message)),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout();
    emit(const AuthUnauthenticated());
  }
}
