// ignore_for_file: always_put_control_body_on_new_line
import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  static const String _settingsBox = 'settings';
  static const String _authBox = 'auth';
  static const String _cartBox = 'cart';
  static const String _favoritesBox = 'favorites';
  static const String _downloadsBox = 'downloads';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_settingsBox);
    await Hive.openBox<dynamic>(_authBox);
    await Hive.openBox<dynamic>(_cartBox);
    await Hive.openBox<dynamic>(_favoritesBox);
    await Hive.openBox<dynamic>(_downloadsBox);
    await _migrateFromGetStorage();
  }

  static Future<void> _migrateFromGetStorage() async {
    final storage = LocalStorage();
    if (storage._settings.get('gs_migrated') == true) {
      return;
    }

    try {
      final dir = Platform.isIOS
          ? await getLibraryDirectory()
          : await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/GetStorage.gs');
      if (file.existsSync()) {
        final data =
            json.decode(await file.readAsString()) as Map<String, dynamic>;

        final token = data['AccessToken'] as String?;
        if (token != null) {
          await storage.saveToken(token);
        }

        final customerId = data['customerId'];
        if (customerId != null) {
          final parsedId = int.tryParse(customerId.toString());
          if (parsedId != null) {
            await storage.saveCustomerId(parsedId);
          }
        }

        final phone = data['phoneNumber'] as String?;
        if (phone != null) {
          await storage.savePhone(phone);
        }

        final favCollarListIds = data['favCollarListIds'];
        if (favCollarListIds != null) {
          await storage.saveFavCollarIds(
            favCollarListIds is String
                ? favCollarListIds
                : jsonEncode(favCollarListIds),
          );
        }

        final favProductIds = data['favProductIds'];
        if (favProductIds != null) {
          await storage.saveFavProductIds(
            favProductIds is String ? favProductIds : jsonEncode(favProductIds),
          );
        }

        final locale = data['langCode'] as String?;
        if (locale != null) {
          await storage.saveLocale(locale);
        }

        await file.delete();
      }
      await storage._settings.put('gs_migrated', true);
    } catch (error) {
      print(error);
    }
  }

  // --- Auth ---
  Box<dynamic> get _auth => Hive.box<dynamic>(_authBox);

  Future<void> saveToken(String token) => _auth.put('access_token', token);
  String? get token => _auth.get('access_token') as String?;
  Future<void> saveCustomerId(int id) => _auth.put('customer_id', id);
  int? get customerId => _auth.get('customer_id') as int?;
  Future<void> savePhone(String phone) => _auth.put('phone', phone);
  String? get phone => _auth.get('phone') as String?;

  /// Last known wallet balance (raw, in cents) — cached so the wallet can
  /// render instantly on a cold start before `users/me` returns.
  Future<void> saveBalance(int raw) => _auth.put('balance', raw);
  int? get balanceRaw => _auth.get('balance') as int?;

  Future<void> clearAuth() async {
    await _auth.delete('access_token');
    await _auth.delete('customer_id');
    await _auth.delete('phone');
    await _auth.delete('balance');
  }

  // --- Settings ---
  Box<dynamic> get _settings => Hive.box<dynamic>(_settingsBox);

  Future<void> saveLocale(String code) => _settings.put('lang_code', code);
  String get locale => (_settings.get('lang_code') as String?) ?? 'tk';

  Future<void> saveThemeMode(String mode) => _settings.put('theme_mode', mode);
  String get themeMode => (_settings.get('theme_mode') as String?) ?? 'system';

  Future<void> setTutorialSeen() => _settings.put('seen_fab_tutorial', true);
  bool get tutorialSeen =>
      (_settings.get('seen_fab_tutorial') as bool?) ?? false;

  Future<void> setNotificationPermissionRequested() =>
      _settings.put('notification_permission_requested', true);
  bool get notificationPermissionRequested =>
      (_settings.get('notification_permission_requested') as bool?) ?? false;

  Future<void> savePaymentDisabled(bool value) =>
      _settings.put('payment_status_disabled', value);
  bool? get paymentDisabled =>
      _settings.get('payment_status_disabled') as bool?;

  Future<void> saveLastSeenMessageId(int id) =>
      _settings.put('last_seen_message_id', id);
  int get lastSeenMessageId =>
      (_settings.get('last_seen_message_id') as int?) ?? 0;

  Future<void> setLegacyCacheCleared() =>
      _settings.put('legacy_yaka_cleanup_v324', true);
  bool get legacyCacheCleared =>
      (_settings.get('legacy_yaka_cleanup_v324') as bool?) ?? false;

  // --- Cart ---
  Box<dynamic> get _cart => Hive.box<dynamic>(_cartBox);

  Future<void> saveCartJson(String json) => _cart.put('cart_list', json);
  String? get cartJson => _cart.get('cart_list') as String?;

  // --- Favorites ---
  Box<dynamic> get _favorites => Hive.box<dynamic>(_favoritesBox);

  Future<void> saveFavProductIds(String json) =>
      _favorites.put('fav_product_ids', json);
  String? get favProductIds => _favorites.get('fav_product_ids') as String?;

  Future<void> saveFavCollarIds(String json) =>
      _favorites.put('fav_collar_ids', json);
  String? get favCollarIds => _favorites.get('fav_collar_ids') as String?;

  // --- Downloads ---
  Box<dynamic> get _downloads => Hive.box<dynamic>(_downloadsBox);

  static const String _downloadStatesKey = 'download_manager_items';
  static const String _downloadCacheKey = 'download_manager_cached_items';

  Map<String, Map<String, dynamic>> get downloadStates {
    final raw = _downloads.get(_downloadStatesKey);
    if (raw is! Map) return {};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{},
      ),
    );
  }

  Future<void> saveDownloadStates(Map<String, Map<String, dynamic>> states) =>
      _downloads.put(_downloadStatesKey, states);

  List<Map<String, dynamic>> get downloadCache {
    final raw = _downloads.get(_downloadCacheKey);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> saveDownloadCache(List<Map<String, dynamic>> items) =>
      _downloads.put(_downloadCacheKey, items);
}
