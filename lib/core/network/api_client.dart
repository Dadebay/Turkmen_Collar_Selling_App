import 'dart:io';

import 'package:dio/dio.dart';

import 'api_logger.dart';
import '../result/result.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required Future<String?> Function() tokenProvider,
  }) : _tokenProvider = tokenProvider {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        },
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          ApiLogger.request(options.method, options.uri);
          final token = await _tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          ApiLogger.response(
            response.requestOptions.method,
            response.requestOptions.uri,
            response.statusCode ?? 0,
          );
          handler.next(response);
        },
        onError: (error, handler) {
          if (error.response case final response?) {
            ApiLogger.response(
              error.requestOptions.method,
              error.requestOptions.uri,
              response.statusCode ?? 0,
            );
          } else {
            ApiLogger.error(
              error.requestOptions.method,
              error.requestOptions.uri,
              error,
            );
          }
          if (error.response?.statusCode == 401) {
            _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  final Future<String?> Function() _tokenProvider;
  void Function()? _onUnauthorized;

  void setUnauthorizedHandler(void Function() handler) {
    _onUnauthorized = handler;
  }

  Future<Result<T>> get<T>(
    String path,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final response = await _dio.get<dynamic>(path);
      return Success(fromJson(response.data));
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownFailure(e.toString()));
    }
  }

  Future<Result<T>> post<T>(
    String path,
    T Function(dynamic json) fromJson, {
    Object? data,
    bool requiresAuth = true,
  }) async {
    try {
      final options = requiresAuth
          ? null
          : Options(headers: {HttpHeaders.authorizationHeader: ''});
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        options: options,
      );
      return Success(fromJson(response.data));
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownFailure(e.toString()));
    }
  }

  Future<Result<T>> delete<T>(
    String path,
    T Function(dynamic json) fromJson, {
    Object? data,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(path, data: data);
      return Success(fromJson(response.data));
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownFailure(e.toString()));
    }
  }

  Future<Result<T>> multipart<T>(
    String path,
    T Function(dynamic json) fromJson, {
    required FormData formData,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Success(fromJson(response.data));
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownFailure(e.toString()));
    }
  }

  AppFailure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkFailure();
    }
    final status = e.response?.statusCode;
    if (status == 401) {
      return const AuthFailure();
    }
    return ServerFailure(e.message ?? 'Server error', statusCode: status);
  }
}
