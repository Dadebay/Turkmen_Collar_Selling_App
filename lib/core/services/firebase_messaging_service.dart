import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:yaka2/core/services/local_notifications_service.dart';
import 'package:yaka2/core/services/notification_deep_link_service.dart';
import 'package:yaka2/core/services/payment_gate_service.dart';
import 'package:yaka2/features/payment/presentation/widgets/low_payment_dialog.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._internal();

  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService.instance() => _instance;

  LocalNotificationsService? _localNotificationsService;

  Future<void> init({
    required LocalNotificationsService localNotificationsService,
  }) async {
    _localNotificationsService = localNotificationsService;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    try {
      await _requestPermission();
    } catch (error) {
      debugPrint('Push permission unavailable: $error');
    }
    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _onMessageOpenedApp(initialMessage);
      }
    } catch (error) {
      debugPrint('Initial push message unavailable: $error');
    }
  }

  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      // The device token is optional for login and OTP verification.
      return null;
    }
  }

  Future<void> _requestPermission() async {
    final result = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${result.authorizationStatus}');
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('📱 FOREGROUND - Uygulama açıkken bildirim geldi');

    final status = PaymentGateService.statusOf(message.data);
    // The payment gate speaks through its dialog, not the notification tray —
    // a banner alongside it would just duplicate the message.
    if (PaymentGateService.isGateStatus(status)) {
      debugPrint('🚫 $status - suppressing foreground notification');
      handleGateMessage(message.data);
      return;
    }

    final notificationData = message.notification;
    if (notificationData != null) {
      _localNotificationsService?.showNotification(
        notificationData.title,
        notificationData.body,
        json.encode(message.data),
      );
      debugPrint('✅ Local notification gösterildi');
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 BİLDİRİME TIKLANDI - Uygulama bildirimden açıldı');

    final status = PaymentGateService.statusOf(message.data);
    if (PaymentGateService.isGateStatus(status)) {
      handleGateMessage(message.data);
      return;
    }

    NotificationDeepLinkService.handleNotificationData(message.data);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '🔔 BACKGROUND/TERMINATED - Uygulama kapalı/arka planda bildirim geldi',
  );

  // Payment-gate statuses only mutate persisted state here; the dialog is
  // raised by the shell on the next launch or resume. No notification is
  // posted for them, so the gate cannot be dismissed by swiping a banner away.
  final status = PaymentGateService.statusOf(message.data);
  if (status == PaymentGateService.statusAmountTooLow) {
    debugPrint('🚨 [BACKGROUND] AMOUNT_TOO_LOW - saving state');
    await PaymentGateService.save(message.data);
    return;
  }
  if (status == PaymentGateService.statusCompleted) {
    debugPrint('✅ [BACKGROUND] COMPLETED - clearing state');
    await PaymentGateService.clear();
    return;
  }

  final localNotificationsService = LocalNotificationsService.instance();
  await localNotificationsService.init();

  final notificationData = message.notification;
  if (notificationData != null) {
    await localNotificationsService.showNotification(
      notificationData.title,
      notificationData.body,
      json.encode(message.data),
    );
    debugPrint('✅ Local notification gösterildi (background/terminated)');
  }
}
