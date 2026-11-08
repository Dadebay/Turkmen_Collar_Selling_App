import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';
import '../models/downloaded_product_model.dart';

class DownloadsRemoteDataSource {
  const DownloadsRemoteDataSource({
    required this.baseUrl,
    required this.tokenProvider,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  Future<Map<String, String>> _authHeaders() async {
    final token = await tokenProvider();
    return {
      HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  Future<Result<List<DownloadedProductModel>>> getDownloadedProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/users/me/downloads'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        final list = data
            .whereType<Map>()
            .map((e) => DownloadedProductModel.fromJson(e))
            .toList();
        return Success(list);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<Result<List<String>>> requestDownloadUrls({
    required int fileId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/users/me/downloads'),
        headers: await _authHeaders(),
        body: jsonEncode(<String, dynamic>{'file_id': fileId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final files = json['data']?['files'];
        if (files is! List) {
          return const Failure(ServerFailure('files missing'));
        }
        final urls = files
            .whereType<String>()
            .where((url) => url.trim().isNotEmpty)
            .toList();
        return Success(urls);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }
}
