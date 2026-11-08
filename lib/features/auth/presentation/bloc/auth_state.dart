part of 'auth_bloc.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthForceUpdate extends AuthState {
  const AuthForceUpdate();
}

final class AuthOptionalUpdate extends AuthState {
  const AuthOptionalUpdate();
}

final class AuthOtpSent extends AuthState {
  const AuthOtpSent({required this.phone});
  final String phone;
}

final class AuthOtpVerified extends AuthState {
  const AuthOtpVerified();
}

final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
