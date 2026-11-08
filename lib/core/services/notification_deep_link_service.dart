import 'dart:developer';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class NotificationDeepLinkService {
  static final NotificationDeepLinkService _instance =
      NotificationDeepLinkService._internal();
  factory NotificationDeepLinkService() => _instance;
  NotificationDeepLinkService._internal();

  static Future<void> handleNotificationData(Map<String, dynamic> data) async {
    try {
      log('🔗 [DEEP LINK] Handling notification data: $data');

      if (data.containsKey('android_link') && Platform.isAndroid) {
        final link = data['android_link'] as String?;
        if (link != null && link.isNotEmpty) {
          await _openExternalLink(link);
          return;
        }
      }

      if (data.containsKey('ios_link') && Platform.isIOS) {
        final link = data['ios_link'] as String?;
        if (link != null && link.isNotEmpty) {
          await _openExternalLink(link);
          return;
        }
      }

      if (data.containsKey('product_id')) {
        log(
          '🔗 [DEEP LINK] Product ID: ${data['product_id']} (navigation not yet wired)',
        );
        return;
      }

      log('🔗 [DEEP LINK] No matching deep link data found');
    } catch (e) {
      log('❌ [DEEP LINK ERROR] Error handling notification data: $e');
    }
  }

  static Future<void> _openExternalLink(String url) async {
    try {
      log('🔗 [DEEP LINK] Opening: $url');
      final uri = Uri.parse(url);

      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        String videoId = '';
        if (url.contains('watch?v=')) {
          videoId = url.split('watch?v=').last.split('&').first;
        } else if (url.contains('youtu.be/')) {
          videoId = url.split('youtu.be/').last.split('?').first;
        }
        if (videoId.isNotEmpty) {
          final ytUri = Uri.parse('youtube://watch?v=$videoId');
          if (await canLaunchUrl(ytUri)) {
            await launchUrl(ytUri, mode: LaunchMode.externalApplication);
            return;
          }
        }
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      log('❌ [DEEP LINK ERROR] Error opening link: $e');
    }
  }
}
