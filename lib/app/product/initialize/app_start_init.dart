import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yaka2/app/product/constants/color_constants.dart';
import 'package:yaka2/app/product/constants/notification_service.dart';
import 'package:yaka2/firebase_options.dart';

@immutable
class AppStartInit {
  const AppStartInit._();
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    await flutterLocalNotificationsPlugin.show(
      message.data.hashCode,
      message.data['body'],
      message.data['title'],
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          color: ColorConstants.whiteColor,
          styleInformation: const BigTextStyleInformation(''),
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await GetStorage.init();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await NotificationService().askPermission();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
