import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yaka2/app/product/initialize/notification_service.dart';
import 'package:yaka2/firebase_options.dart';

Future<void> backgroundNotificationHandler(RemoteMessage message) async {
  await FCMConfig().sendNotification(body: message.notification!.body!, title: message.notification!.title!);
  return;
}

@immutable
class AppStartInit {
  const AppStartInit._();

  static Future<void> getNotification() async {
    // print token
    await FirebaseMessaging.instance.getToken().then((value) {
      print('Token: $value');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage: ${message.notification}');
      print('onMessage: ${message.data}');
      print('onMessage: ${message.notification!.title}');
      print('onMessage: ${message.notification!.body}');
      FCMConfig().sendNotification(body: message.notification!.body!, title: message.notification!.title!);
    });
  }

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await GetStorage.init();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FCMConfig().requestPermission();
    await FCMConfig().initAwesomeNotification();
    await FirebaseMessaging.instance.subscribeToTopic('EVENT');
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.logEvent(
      name: 'prog_girdim',
      parameters: {
        'debug_test': 'true',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    FirebaseMessaging.onBackgroundMessage(backgroundNotificationHandler);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
