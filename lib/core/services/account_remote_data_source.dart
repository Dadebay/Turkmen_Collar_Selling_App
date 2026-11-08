import 'dart:convert';
import 'dart:io';

import 'package:yaka2/core/network/logged_http.dart' as http;

import '../models/user_me_model.dart';
import '../result/result.dart';
import '../storage/local_storage.dart';

/// Single source of truth for `GET /api/v1/users/me`.
///
/// Previously three call sites hit this endpoint independently (auth token
/// validation, wallet balance, profile). They now all route through
/// [getCurrentUser], which:
///   * coalesces concurrent requests into one in-flight HTTP call, and
///   * serves a short-lived in-memory cache so near-simultaneous callers
///     (e.g. splash token-validation followed by the balance fetch on home)
///     reuse a single network round-trip.
///
/// On every success the balance is also persisted to [LocalStorage] so the
/// wallet can render the last known value instantly on a cold start.
class AccountRemoteDataSource {
  AccountRemoteDataSource({required this.baseUrl, required this.localStorage});

  final String baseUrl;
  final LocalStorage localStorage;

  /// How long a fetched user is reused before a refresh hits the network.
  static const Duration _ttl = Duration(seconds: 10);
  static const Duration _notFoundCooldown = Duration(minutes: 5);

  UserMeModel? _cached;
  DateTime? _cachedAt;
  DateTime? _notFoundAt;
  Future<Result<UserMeModel>>? _inFlight;

  /// Fetches the current user, reusing a recent result when possible.
  ///
  /// Pass [forceRefresh] to bypass the TTL cache (the periodic wallet refresh
  /// uses this so the balance can never go stale for more than its interval).
  Future<Result<UserMeModel>> getCurrentUser({
    bool forceRefresh = false,
  }) async {
    if (localStorage.token?.isNotEmpty != true) {
      return const Failure(AuthFailure('No session'));
    }
    if (_notFoundAt != null &&
        DateTime.now().difference(_notFoundAt!) < _notFoundCooldown) {
      return const Failure(ServerFailure('Not found', statusCode: 404));
    }
    if (!forceRefresh && _cached != null && _cachedAt != null) {
      if (DateTime.now().difference(_cachedAt!) < _ttl) {
        return Success(_cached!);
      }
    }
    // Coalesce concurrent callers onto the same request.
    final existing = _inFlight;
    if (existing != null) {
      return existing;
    }
    final future = _fetch();
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  /// Drops the cached user (e.g. on logout).
  void invalidate() {
    _cached = null;
    _cachedAt = null;
    _notFoundAt = null;
  }

  Future<Result<UserMeModel>> _fetch({int retry = 1}) async {
    try {
      final token = localStorage.token;
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/users/me'),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
              if (token != null && token.isNotEmpty)
                HttpHeaders.authorizationHeader: 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        if (decoded.trim().startsWith('<')) {
          return const Failure(ServerFailure('html response'));
        }
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final model = UserMeModel.fromJson(json);
        _cached = model;
        _cachedAt = DateTime.now();
        _notFoundAt = null;
        await localStorage.saveBalance(model.balance ?? 0);
        return Success(model);
      } else if (response.statusCode == 401) {
        return const Failure(AuthFailure('Unauthorized'));
      } else if (response.statusCode == 404) {
        _notFoundAt = DateTime.now();
        return const Failure(ServerFailure('Not found', statusCode: 404));
      } else {
        // Only transient server failures are worth retrying. A missing route
        // will still be missing one second later.
        if (retry <= 0 || response.statusCode < 500) {
          return Failure(
            ServerFailure('error', statusCode: response.statusCode),
          );
        }
        await Future.delayed(const Duration(seconds: 1));
        return await _fetch(retry: retry - 1);
      }
    } catch (_) {
      // Transient failure (e.g. flaky network on cold start): back off and
      // retry instead of surfacing a hard failure. Because this call also
      // backs token validation, retrying keeps a valid session from being
      // logged out on launch. A 401 already returned above without retry, so
      // only network-level exceptions land here.
      if (retry <= 0) {
        return const Failure(NetworkFailure());
      }
      await Future.delayed(const Duration(seconds: 1));
      return await _fetch(retry: retry - 1);
    }
  }
}
