// ignore_for_file: file_names, strict_raw_type
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FCMConfig {
  Future initAwesomeNotification() async {
    await AwesomeNotifications()
        .initialize(
          null,
          [
            NotificationChannel(
              channelGroupKey: 'basic_channel_group',
              channelKey: 'basic_channel',
              channelName: 'Basic notifications',
              channelDescription: 'Notification channel for basic tests',
              defaultColor: Color(0xFF9D50DD),
              ledColor: Colors.white,
              importance: NotificationImportance.Max,
              channelShowBadge: true,
              locked: true,
              defaultRingtoneType: DefaultRingtoneType.Ringtone,
            ),
          ],
          channelGroups: [
            NotificationChannelGroup(
              channelGroupKey: 'basic_channel_group',
              channelGroupName: 'Basic group',
            ),
          ],
          debug: false,
        )
        .then((a) {});
    ;
  }

  Future<void> requestPermission() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
    } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {}
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  int a = 0;
  Future sendNotification({required String title, required String body}) async {
    a++;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: a,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: true,
      ),
    );
  }
}
