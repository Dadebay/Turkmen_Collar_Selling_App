import 'dart:convert';
import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yaka2/app/product/services/notification_deep_link_service.dart';

class LocalNotificationsService {
  // Private constructor for singleton pattern
  LocalNotificationsService._internal();

  //Singleton instance
  static final LocalNotificationsService _instance = LocalNotificationsService._internal();

  //Factory constructor to return singleton instance
  factory LocalNotificationsService.instance() => _instance;

  //Main plugin instance for handling notifications
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  //Android-specific initialization settings using app launcher icon
  final _androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');

  //iOS-specific initialization settings with permission requests
  final _iosInitializationSettings = const DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  //Android notification channel configuration
  final _androidChannel = const AndroidNotificationChannel(
    'channel_id',
    'Channel name',
    description: 'Android push notification channel',
    importance: Importance.max,
  );

  //Flag to track initialization status
  bool _isFlutterLocalNotificationInitialized = false;

  //Counter for generating unique notification IDs
  int _notificationIdCounter = 0;

  /// Initializes the local notifications plugin for Android and iOS.
  Future<void> init() async {
    // Check if already initialized to prevent redundant setup
    if (_isFlutterLocalNotificationInitialized) {
      return;
    }

    // Create plugin instance
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Combine platform-specific settings
    final initializationSettings = InitializationSettings(
      android: _androidInitializationSettings,
      iOS: _iosInitializationSettings,
    );

    // Initialize plugin with settings and callback for notification taps
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_androidChannel);

    // Mark initialization as complete
    _isFlutterLocalNotificationInitialized = true;
  }

  /// Handle notification tap events
  void _onNotificationTapped(NotificationResponse response) {
    try {
      log('🔔 Local notification tapped with payload: ${response.payload}');

      if (response.payload != null && response.payload!.isNotEmpty) {
        // Try to parse the payload as JSON
        try {
          final Map<String, dynamic> data = json.decode(response.payload!);

          // Handle deep links from local notification tap
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

  /// Show a local notification with the given title, body, and payload.
  Future<void> showNotification(
    String? title,
    String? body,
    String? payload,
  ) async {
    // Android-specific notification details
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
    );

    // iOS-specific notification details
    const iosDetails = DarwinNotificationDetails();

    // Combine platform-specific details
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Display the notification
    await _flutterLocalNotificationsPlugin.show(
      _notificationIdCounter++,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
