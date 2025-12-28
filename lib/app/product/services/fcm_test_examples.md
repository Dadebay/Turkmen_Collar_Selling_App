/*
FCM Deep Link Test Examples

Bu dosya FCM notification test örneklerini içeriyor.
Firebase Console veya sunucu tarafından aşağıdaki gibi payload gönderebilirsiniz.

═══════════════════════════════════════════════════════════════════════════════

1. ANDROID APP LINK (Android cihazlarda app store'a yönlendir)
═══════════════════════════════════════════════════════════════════════════════

{
  "to": "FCM_TOKEN_HERE",
  "notification": {
    "title": "Yeni Versiyon Çıktı!",
    "body": "Uygulamanın yeni versiyonu Google Play Store'da mevcut."
  },
  "data": {
    "android_link": "https://play.google.com/store/apps/details?id=com.example.yaka2"
  }
}

═══════════════════════════════════════════════════════════════════════════════

2. iOS APP LINK (iOS cihazlarda app store'a yönlendir)
═══════════════════════════════════════════════════════════════════════════════

{
  "to": "FCM_TOKEN_HERE",
  "notification": {
    "title": "Yeni Versiyon Çıktı!",
    "body": "Uygulamanın yeni versiyonu App Store'da mevcut."
  },
  "data": {
    "ios_link": "https://apps.apple.com/app/yaka/id1234567890"
  }
}

═══════════════════════════════════════════════════════════════════════════════

3. HER İKİ PLATFORM LINK (Cihaz tipine göre otomatik yönlendir)
═══════════════════════════════════════════════════════════════════════════════

{
  "to": "FCM_TOKEN_HERE",
  "notification": {
    "title": "Yeni Versiyon Çıktı!",
    "body": "Uygulamanın yeni versiyonu mevcut."
  },
  "data": {
    "android_link": "https://play.google.com/store/apps/details?id=com.example.yaka2",
    "ios_link": "https://apps.apple.com/app/yaka/id1234567890"
  }
}

═══════════════════════════════════════════════════════════════════════════════

4. PRODUCT DETAIL (Belirli ürün sayfasına yönlendir)
═══════════════════════════════════════════════════════════════════════════════

{
  "to": "FCM_TOKEN_HERE",
  "notification": {
    "title": "Yeni Ürün!",
    "body": "Bu harika ürünü kaçırma!"
  },
  "data": {
    "product_id": "123"
  }
}

═══════════════════════════════════════════════════════════════════════════════

5. KOMBİNE EXAMPLE (Hem product hem de app link)
═══════════════════════════════════════════════════════════════════════════════

{
  "to": "FCM_TOKEN_HERE",
  "notification": {
    "title": "Özel Kampanya!",
    "body": "Bu ürüne özel %50 indirim!"
  },
  "data": {
    "product_id": "456",
    "android_link": "https://play.google.com/store/apps/details?id=com.example.yaka2",
    "ios_link": "https://apps.apple.com/app/yaka/id1234567890"
  }
}

Not: Bu durumda product_id öncelikli olur, app link'ler sadece product bulunamazsa kullanılır.

═══════════════════════════════════════════════════════════════════════════════

CURL COMMAND EXAMPLE (Firebase REST API ile test):
═══════════════════════════════════════════════════════════════════════════════

curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: Bearer YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN_HERE",
    "notification": {
      "title": "Test Notification",
      "body": "Bu bir test bildirimi"
    },
    "data": {
      "product_id": "123"
    }
  }'

═══════════════════════════════════════════════════════════════════════════════

FIREBASE CONSOLE'DA TEST:
═══════════════════════════════════════════════════════════════════════════════

1. Firebase Console > Cloud Messaging sekmesine git
2. "Send your first message" butonuna tıkla
3. Notification title ve body'yi doldur
4. "Additional options" > "Custom data" kısmına aşağıdakileri ekle:
   Key: product_id, Value: 123
   veya
   Key: android_link, Value: https://play.google.com/store/apps/details?id=com.example.yaka2

═══════════════════════════════════════════════════════════════════════════════

LOG ÇIKTILARI:
═══════════════════════════════════════════════════════════════════════════════

Uygulama çalışırken aşağıdaki gibi detaylı log'lar göreceksiniz:

🔑 FCM TOKEN (Test için bu token'ı kullanın):
dxyz...

📱 FCM NOTIFICATION RECEIVED
═══════════════════════════════════════════════════════════════════════════════
📋 Title: Test Notification
📝 Body: Bu bir test bildirimi  
📊 Platform: Android
📦 Data payload:
   product_id: 123
🛍️ Product ID detected: 123
═══════════════════════════════════════════════════════════════════════════════

🔗 [DEEP LINK] Handling notification data: {product_id: 123}
🔗 [DEEP LINK] Navigating to product ID: 123
✅ [DEEP LINK] Successfully navigated to product: Ürün Adı

═══════════════════════════════════════════════════════════════════════════════

ERROR HANDLING:
═══════════════════════════════════════════════════════════════════════════════

Eğer ürün bulunamazsa:
❌ [DEEP LINK] Product not found with ID: 999
+ Snackbar gösterilir: "Ürün Bulunamadı"

Eğer link açılamazsa:
❌ [DEEP LINK] Cannot launch URL: invalid-url

*/