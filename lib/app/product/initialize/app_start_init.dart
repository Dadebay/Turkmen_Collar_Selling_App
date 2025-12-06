import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yaka2/app/product/initialize/firebase_messaging_service.dart';
import 'package:yaka2/app/product/initialize/local_notifications_service.dart';
import 'package:yaka2/firebase_options.dart';

@immutable
class AppStartInit {
  const AppStartInit._();

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await GetStorage.init();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('[MAIN LOG] 4/9 - Firebase başarıyla başlatıldı.', name: 'AkbulutApp');

    final localNotificationsService = LocalNotificationsService.instance();
    await localNotificationsService.init();

    final firebaseMessagingService = FirebaseMessagingService.instance();
    await firebaseMessagingService.init(localNotificationsService: localNotificationsService);

    await FirebaseMessaging.instance.subscribeToTopic('EVENT');
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.logEvent(
      name: 'prog_girdim',
      parameters: {
        'debug_test': 'true',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
