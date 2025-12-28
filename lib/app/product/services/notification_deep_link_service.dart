import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/services/dresses_service.dart';
import 'package:yaka2/app/feature/home/services/collars_service.dart';
import 'package:yaka2/app/feature/product_profil/views/product_profil_view.dart';

class NotificationDeepLinkService {
  static final NotificationDeepLinkService _instance = NotificationDeepLinkService._internal();
  factory NotificationDeepLinkService() => _instance;
  NotificationDeepLinkService._internal();

  /// Handle FCM notification data and navigate accordingly
  static Future<void> handleNotificationData(Map<String, dynamic> data) async {
    try {
      log('🔗 [DEEP LINK] Handling notification data: $data');

      // Check for android_link
      if (data.containsKey('android_link') && Platform.isAndroid) {
        final androidLink = data['android_link'] as String?;
        if (androidLink != null && androidLink.isNotEmpty) {
          await _openExternalLink(androidLink);
          return;
        }
      }

      // Check for ios_link
      if (data.containsKey('ios_link') && Platform.isIOS) {
        final iosLink = data['ios_link'] as String?;
        if (iosLink != null && iosLink.isNotEmpty) {
          await _openExternalLink(iosLink);
          return;
        }
      }

      // Check for product_id
      if (data.containsKey('product_id')) {
        final productId = data['product_id'];
        if (productId != null) {
          await _navigateToProduct(productId.toString());
          return;
        }
      }

      log('🔗 [DEEP LINK] No matching deep link data found');
    } catch (e) {
      log('❌ [DEEP LINK ERROR] Error handling notification data: $e');
    }
  }

  /// Open external link (App Store, Google Play, etc.)
  static Future<void> _openExternalLink(String url) async {
    try {
      log('🔗 [DEEP LINK] Opening external link: $url');

      final Uri uri = Uri.parse(url);

      if (Platform.isIOS) {
        // iOS için özel YouTube URL handling
        if (url.contains('youtube.com') || url.contains('youtu.be')) {
          // YouTube app URL'si oluştur
          String videoId = '';
          if (url.contains('watch?v=')) {
            videoId = url.split('watch?v=').last.split('&').first;
          } else if (url.contains('youtu.be/')) {
            videoId = url.split('youtu.be/').last.split('?').first;
          }

          if (videoId.isNotEmpty) {
            // Önce YouTube app'i dene
            final youtubeAppUri = Uri.parse('youtube://watch?v=$videoId');
            try {
              if (await canLaunchUrl(youtubeAppUri)) {
                await launchUrl(youtubeAppUri, mode: LaunchMode.externalApplication);
                log('✅ [DEEP LINK] Opened in YouTube app');
                return;
              }
            } catch (e) {
              log('⚠️ YouTube app not available, opening in browser');
            }
          }
        }

        // YouTube app yoksa veya başka bir link ise tarayıcıda aç
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          log('✅ [DEEP LINK] Successfully opened external link');
          return;
        } catch (e) {
          log('❌ [DEEP LINK] Failed to open link: $e');
        }
      } else if (Platform.isAndroid) {
        // Android için doğrudan aç
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          log('✅ [DEEP LINK] Successfully opened external link');
          return;
        } catch (e) {
          log('⚠️ First attempt failed, trying platformDefault: $e');
          try {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
            log('✅ [DEEP LINK] Successfully opened with platformDefault');
            return;
          } catch (e2) {
            log('❌ [DEEP LINK] All attempts failed: $e2');
          }
        }
      }

      // Hata durumu
      Get.snackbar(
        'Link Açılamadı',
        'Bu linki açmak için gerekli uygulama bulunamadı.',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      log('❌ [DEEP LINK ERROR] Error opening external link: $e');
      Get.snackbar(
        'Hata',
        'Link açılırken bir hata oluştu.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Navigate to product detail page by product ID
  static Future<void> _navigateToProduct(String productId) async {
    try {
      log('🔗 [DEEP LINK] Navigating to product ID: $productId');

      // First try to get product as dress
      ProductModel? product = await _getProductById(productId, false);

      // If not found as dress, try as collar
      product ??= await _getProductById(productId, true);

      if (product != null) {
        // Navigate to product detail page
        Get.to(() => ProductProfilView(product: product!));
        log('✅ [DEEP LINK] Successfully navigated to product: ${product.name}');
      } else {
        log('❌ [DEEP LINK] Product not found with ID: $productId');
        // Optionally show a snackbar or dialog
        Get.snackbar(
          'Ürün Bulunamadı',
          'Belirtilen ürün bulunamadı.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      log('❌ [DEEP LINK ERROR] Error navigating to product: $e');
    }
  }

  /// Get product by ID from either dresses or collars service
  static Future<ProductModel?> _getProductById(String productId, bool isCollar) async {
    try {
      if (isCollar) {
        // Try to get collar by ID
        final collar = await CollarService().getCollarsByID(int.parse(productId));
        if (collar.id != null && collar.id! > 0) {
          // Convert images list to List<String>
          List<String> imagesList = [];
          if (collar.images != null) {
            imagesList = collar.images!.map((e) => e.toString()).toList();
          }

          // Convert collar to ProductModel
          return ProductModel(
            id: collar.id!,
            name: collar.name ?? '',
            createdAt: collar.createdAt ?? DateTime.now().toString(),
            image: imagesList.isNotEmpty ? imagesList.first : '',
            price: (collar.price ?? 0).toString(),
            categoryName: collar.tag ?? '',
            downloadable: true,
            videoURL: null,
            images: imagesList,
            description: collar.desc,
          );
        }
      } else {
        // Try to get dress by ID
        final dress = await DressesService().getDressesByID(int.parse(productId));
        if (dress.id > 0) {
          return dress;
        }
      }
      return null;
    } catch (e) {
      log('❌ [DEEP LINK ERROR] Error getting product by ID: $e');
      return null;
    }
  }

  /// Print detailed FCM notification information
  static void printNotificationDetails(Map<String, dynamic> data, {String? title, String? body}) {
    log('═══════════════════════════════════════════════════════════');
    log('📱 FCM NOTIFICATION RECEIVED');
    log('═══════════════════════════════════════════════════════════');

    if (title != null) {
      log('📋 Title: $title');
    }

    if (body != null) {
      log('📝 Body: $body');
    }

    log('📊 Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Unknown"}');

    if (data.isNotEmpty) {
      log('📦 Data payload:');
      data.forEach((key, value) {
        log('   $key: $value');
      });

      // Check for deep link data
      if (data.containsKey('android_link')) {
        log('🔗 Android link detected: ${data['android_link']}');
      }

      if (data.containsKey('ios_link')) {
        log('🍎 iOS link detected: ${data['ios_link']}');
      }

      if (data.containsKey('product_id')) {
        log('🛍️ Product ID detected: ${data['product_id']}');
      }
    } else {
      log('📦 No data payload received');
    }

    log('═══════════════════════════════════════════════════════════');
  }
}
