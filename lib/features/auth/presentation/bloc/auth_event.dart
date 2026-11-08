part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested({required this.platform, required this.version});
  final String platform;
  final String version;
}

final class AuthSendOtpRequested extends AuthEvent {
  const AuthSendOtpRequested({required this.phone, this.deviceToken});
  final String phone;
  final String? deviceToken;
}

final class AuthVerifyOtpRequested extends AuthEvent {
  const AuthVerifyOtpRequested({
    required this.phone,
    required this.otp,
    this.deviceToken,
  });
  final String phone;
  final String otp;
  final String? deviceToken;
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
