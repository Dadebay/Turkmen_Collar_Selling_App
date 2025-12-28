import UIKit
import Flutter
import FirebaseCore
import flutter_local_notifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      // Firebase'i yapılandır
      FirebaseApp.configure()
      
      // Local notifications için callback
      FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
          GeneratedPluginRegistrant.register(with: registry)
      }

      // iOS 10+ için notification delegate
      if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
      }
      
      // FCM delegate
      Messaging.messaging().delegate = self
      
      // Plugin'leri kaydet
      GeneratedPluginRegistrant.register(with: self)
      
      // Notification izni iste
      if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
              print("iOS Notification Permission: \(granted)")
          }
      }
      
      application.registerForRemoteNotifications()
      
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  // FCM Token alındığında
  override func application(_ application: UIApplication, 
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      Messaging.messaging().apnsToken = deviceToken
      print("📱 APNS Token registered")
  }
    
  // FCM Token alınamadığında
  override func application(_ application: UIApplication, 
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
      print("❌ Failed to register for remote notifications: \(error)")
  }
}

// FCM Messaging Delegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔑 FCM Token: \(fcmToken ?? "nil")")
        // Token'ı backend'e gönderebilirsiniz
    }
}