import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';
import '../../../home/data/models/product_model.dart';

class FavoritesRemoteDataSource {
  const FavoritesRemoteDataSource({
    required this.baseUrl,
    required this.tokenProvider,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    return {
      HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  Future<Map<String, String>> _authHeader() async {
    final token = await tokenProvider();
    return {
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  Future<Result<List<ProductModel>>> fetchFavProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/users/me/favorite-products'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        return Success(
          data
              .map((e) => ProductModel.fromJson(e as Map<dynamic, dynamic>))
              .toList(),
        );
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<Result<List<ProductModel>>> fetchFavCollars() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/users/me/favorites'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        return Success(
          data
              .map(
                (e) => ProductModel.fromJson({
                  ...e as Map<dynamic, dynamic>,
                  'downloadable': true,
                }),
              )
              .toList(),
        );
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<Result<void>> addFavorite({
    required int id,
    required bool isCollar,
  }) async {
    try {
      final path = isCollar
          ? '/api/v1/users/me/favorites'
          : '/api/v1/users/me/favorite-products';
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers.addAll(await _authHeader())
        ..fields[isCollar ? 'collar_id' : 'product_id'] = '$id';
      final response = await http.send(request);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Success(null);
      }
      return Failure(
        ServerFailure('favoriteAddFailed', statusCode: response.statusCode),
      );
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }

  Future<Result<void>> removeFavorite({
    required int id,
    required bool isCollar,
  }) async {
    try {
      final path = isCollar
          ? '/api/v1/users/me/favorites'
          : '/api/v1/users/me/favorite-products';
      final request = http.Request('DELETE', Uri.parse('$baseUrl$path'))
        ..headers.addAll(await _authHeader())
        ..headers[HttpHeaders.contentTypeHeader] =
            'application/x-www-form-urlencoded'
        ..bodyFields = {isCollar ? 'collar_id' : 'product_id': '$id'};
      final response = await http.send(request);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return Failure(
        ServerFailure('favoriteRemoveFailed', statusCode: response.statusCode),
      );
    } catch (_) {
      return const Failure(NetworkFailure());
    }
  }
}
