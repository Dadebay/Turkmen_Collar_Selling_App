import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';
import '../models/meta_models.dart';

class ProfileMetaRemoteDataSource {
  const ProfileMetaRemoteDataSource({
    required this.baseUrl,
    required this.tokenProvider,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
    };
    if (auth) {
      final token = await tokenProvider();
      if (token != null && token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Result<AboutUsModel>> getAboutUs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/about/'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        return Success(AboutUsModel.fromJson(json));
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<Result<List<FAQModel>>> getFaq() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/faqs'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        return Success(
          data.whereType<Map>().map((e) => FAQModel.fromJson(e)).toList(),
        );
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<Result<ConfigModel>> getConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/config'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        return Success(ConfigModel.fromJson(json));
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<Result<List<FilterElementModel>>> getFilterElements() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/tags'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        return Success(
          data
              .whereType<Map>()
              .map((e) => FilterElementModel.fromJson(e))
              .toList(),
        );
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }
}
