import 'dart:convert';
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yaka2/core/services/notification_deep_link_service.dart';

class LocalNotificationsService {
  LocalNotificationsService._internal();

  static final LocalNotificationsService _instance =
      LocalNotificationsService._internal();

  factory LocalNotificationsService.instance() => _instance;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  final _androidInitializationSettings = const AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  final _iosInitializationSettings = const DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final _androidChannel = const AndroidNotificationChannel(
    'channel_id',
    'Channel name',
    description: 'Android push notification channel',
    importance: Importance.max,
  );

  bool _isFlutterLocalNotificationInitialized = false;

  int _notificationIdCounter = 0;

  Future<void> init() async {
    if (_isFlutterLocalNotificationInitialized) {
      return;
    }

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final initializationSettings = InitializationSettings(
      android: _androidInitializationSettings,
      iOS: _iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    _isFlutterLocalNotificationInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    try {
      log('🔔 Local notification tapped with payload: ${response.payload}');

      if (response.payload != null && response.payload!.isNotEmpty) {
        try {
          final Map<String, dynamic> data = json.decode(response.payload!);
          NotificationDeepLinkService.handleNotificationData(data);
        } catch (e) {
          log('❌ Error parsing notification payload as JSON: $e');
          log('Raw payload: ${response.payload}');
        }
      }
    } catch (e) {
      log('❌ Error handling local notification tap: $e');
    }
  }

  Future<void> showNotification(
    String? title,
    String? body,
    String? payload,
  ) async {
    if (!_isFlutterLocalNotificationInitialized) {
      return;
    }
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        );

    const iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: _notificationIdCounter++,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
