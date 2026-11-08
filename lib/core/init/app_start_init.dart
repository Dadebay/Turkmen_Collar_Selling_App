import 'dart:async';
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaka2/features/ai_chat/data/datasources/chat_socket_service.dart';
import 'package:yaka2/core/services/local_notifications_service.dart';
import 'package:yaka2/core/services/firebase_messaging_service.dart';
import 'package:yaka2/core/constants/api_constants.dart';
import 'package:yaka2/core/constants/list_constants.dart';
import 'package:yaka2/core/storage/local_storage.dart';
import 'package:yaka2/features/downloads/data/services/download_manager_service.dart';
import 'package:yaka2/firebase_options.dart';
import 'package:yaka2/injection_container.dart';

@immutable
class AppStartInit {
  const AppStartInit._();

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await LocalStorage.init();
    await ListConstants.initAppVersion();
    final storage = LocalStorage();
    if (storage.locale == 'tr') {
      await storage.saveLocale('tk');
    }
    var firebaseReady = false;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseReady = true;
      log('[MAIN LOG] Firebase initialized.', name: 'YakaApp');
    } catch (error) {
      log('[MAIN LOG] Firebase unavailable: $error', name: 'YakaApp');
    }
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await initDependencies();
    await _clearLegacyDownloadCacheOnce();
    _initChatSocket();
    // Push permission and token retrieval can wait for the user or network.
    // They must never prevent the storefront from opening.
    unawaited(_initOptionalServices(firebaseReady));
  }

  static Future<void> _initOptionalServices(bool firebaseReady) async {
    final notifications = LocalNotificationsService.instance();
    try {
      await notifications.init();
    } catch (error) {
      log(
        '[MAIN LOG] Local notifications unavailable: $error',
        name: 'YakaApp',
      );
    }
    if (!firebaseReady) {
      return;
    }

    try {
      await FirebaseMessagingService.instance().init(
        localNotificationsService: notifications,
      );
    } catch (error) {
      log('[MAIN LOG] Push notifications unavailable: $error', name: 'YakaApp');
    }
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'prog_girdim',
        parameters: {
          'debug_test': 'true',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (error) {
      log('[MAIN LOG] Analytics unavailable: $error', name: 'YakaApp');
    }
  }

  /// One-time wipe of the legacy `YAKA` source cache left by pre-3.2.4 builds
  /// (wrong-case folders and `name(N).ext` duplicates). Guarded by a persisted
  /// run-once flag; on failure the flag stays unset so it retries next launch.
  static Future<void> _clearLegacyDownloadCacheOnce() async {
    final storage = LocalStorage();
    if (storage.legacyCacheCleared) {
      return;
    }
    try {
      await sl<DownloadManagerService>().clearAllSourceFiles();
      await storage.setLegacyCacheCleared();
      log('[MAIN LOG] Legacy YAKA cache cleared.', name: 'YakaApp');
    } catch (e) {
      log('[MAIN LOG] Legacy cache cleanup deferred: $e', name: 'YakaApp');
    }
  }

  static void _initChatSocket() {
    final storage = LocalStorage();
    final token = storage.token;
    final customerId = storage.customerId;

    if (token != null && customerId != null) {
      log('[ChatSocket] Initializing on app start...', name: 'YakaApp');
      ChatSocketService().initSocket(
        ApiConstants.baseUrl,
        customerId.toString(),
        token: token,
      );
    }
  }
}
