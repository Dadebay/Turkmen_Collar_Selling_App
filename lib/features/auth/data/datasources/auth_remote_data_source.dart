import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';
import '../models/auth_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource({required this.baseUrl});
  final String baseUrl;

  Future<Result<void>> sendOtp({
    required String phone,
    String? deviceToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/login'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'phone': phone,
          if (deviceToken != null) 'device_token': deviceToken,
        }),
      );
      if (response.statusCode == 200) {
        return const Success(null);
      }
      if (response.statusCode == 429) {
        return const Failure(ServerFailure('wait10Min', statusCode: 429));
      }
      if (response.statusCode == 409) {
        return const Failure(ServerFailure('alreadyExist', statusCode: 409));
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<Result<AuthModel>> verifyOtp({
    required String phone,
    required String otp,
    String? deviceToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/login/verify'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
          if (deviceToken != null) 'device_token': deviceToken,
        }),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Success(AuthModel.fromJson(json, phone: phone));
      }
      return Failure(
        ServerFailure('otpErrorTitle', statusCode: response.statusCode),
      );
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<int> checkAppVersion({
    required String platform,
    required String version,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/check-version'),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
            },
            body: jsonEncode({'platform': platform, 'version': version}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = decoded['capability_type'];
        return raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 1;
      }
      return 1;
    } catch (_) {
      return 1;
    }
  }
}
