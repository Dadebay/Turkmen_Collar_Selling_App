import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../../../../core/result/result.dart';
import '../../../../core/network/api_logger.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/collar_model.dart';
import '../models/photo_model.dart';
import '../models/product_model.dart';
import '../models/video_model.dart';

class HomeRemoteDataSource {
  const HomeRemoteDataSource({
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

  Future<http.Response> _get(Uri uri) async => http
      .get(uri, headers: await _authHeaders())
      .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          final error = TimeoutException('15-second API timeout');
          ApiLogger.error('GET', uri, error);
          throw error;
        },
      );

  Result<T> _requestFailure<T>(Object error, String path) {
    if (error is TimeoutException ||
        error is SocketException ||
        error is http.ClientException) {
      return const Failure(NetworkFailure());
    }
    ApiLogger.error('HOME', Uri.parse('$baseUrl$path'), error);
    return Failure(UnknownFailure(error.toString()));
  }

  Future<Result<List<BannerModel>>> getBanners() async {
    try {
      final response = await _get(Uri.parse('$baseUrl/api/v1/banners'));
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final list = (json['data'] as List)
            .map((e) => BannerModel.fromJson(e as Map<dynamic, dynamic>))
            .toList();
        return Success(list);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (error) {
      return _requestFailure(error, '/api/v1/banners');
    }
  }

  Future<Result<List<CategoryModel>>> getCategories() async {
    try {
      final response = await _get(Uri.parse('$baseUrl/api/v1/categories'));
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final list = (json['data'] as List)
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Success(list);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (error) {
      return _requestFailure(error, '/api/v1/categories');
    }
  }

  Future<Result<List<ProductModel>>> _getProducts(
    String path, {
    Map<String, String> queryParameters = const {},
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
      final response = await _get(uri);
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        final list = data
            .map((e) => ProductModel.fromJson(e as Map<dynamic, dynamic>))
            .toList();
        return Success(list);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (error) {
      return _requestFailure(error, path);
    }
  }

  Future<Result<List<ProductModel>>> getMachines() =>
      _getProducts('/api/v1/machines');

  // Clothes are served by the generic /products endpoint with `home=1` flag.
  Future<Result<List<ProductModel>>> getClothes() => _getProducts(
    '/api/v1/products',
    queryParameters: const {'page': '1', 'limit': '10', 'home': '1'},
  );

  // Goods live under sewing-products, not /goods.
  Future<Result<List<ProductModel>>> getGoods() => _getProducts(
    '/api/v1/sewing-products',
    queryParameters: const {'page': '1', 'limit': '10'},
  );

  Future<Result<List<CollarModel>>> getCollars() async {
    try {
      final response = await _get(Uri.parse('$baseUrl/api/v1/collars'));
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        final list = data
            .map((e) => CollarModel.fromJson(e as Map<dynamic, dynamic>))
            .toList();
        return Success(list);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (error) {
      return _requestFailure(error, '/api/v1/collars');
    }
  }

  Future<Result<List<ProductModel>>> getCategoryProducts({
    required int categoryId,
    required Map<String, String> params,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/categories/$categoryId')
          .replace(queryParameters: params);
      final response = await _get(uri);
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        List<ProductModel> list = [];
        final collarsData = json['collars']?['data'] as List?;
        final productsData = json['products']?['data'] as List?;
        if (collarsData != null && collarsData.isNotEmpty) {
          list = collarsData
              .map((e) => ProductModel.fromJson(e as Map<dynamic, dynamic>))
              .toList();
        } else if (productsData != null) {
          list = productsData
              .map((e) => ProductModel.fromJson(e as Map<dynamic, dynamic>))
              .toList();
        }
        return Success(list);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (error) {
      return _requestFailure(error, '/api/v1/categories/$categoryId');
    }
  }

  Future<Result<List<ProductModel>>> searchCollars({
    required String query,
  }) async {
    try {
      final response = await _get(
        Uri.parse('$baseUrl/api/v1/collars')
            .replace(queryParameters: {'q': query}),
      );
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        final list = data
            .map(
              (e) => ProductModel.fromJson({
                ...e as Map<dynamic, dynamic>,
                'downloadable': true,
              }),
            )
            .toList();
        return Success(list);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (error) {
      return _requestFailure(error, '/api/v1/collars?q=$query');
    }
  }

  Future<Result<List<VideoModel>>> getVideos() async {
    try {
      final response = await _get(Uri.parse('$baseUrl/api/v1/videos'));
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        final list =
            data
                .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
        return Success(list);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (error) {
      return _requestFailure(error, '/api/v1/videos');
    }
  }

  Future<Result<List<PhotoModel>>> getPhotos() async {
    try {
      final response = await _get(Uri.parse('$baseUrl/api/v1/photos'));
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        final list = data
            .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Success(list);
      }
      return Failure(ServerFailure('error', statusCode: response.statusCode));
    } catch (error) {
      return _requestFailure(error, '/api/v1/photos');
    }
  }
}
