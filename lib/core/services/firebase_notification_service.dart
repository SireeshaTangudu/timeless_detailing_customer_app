import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}

class FirebaseNotificationService {
  static String? fcmToken;

  static Future<String?> fetchFcmToken({bool forceRefresh = false}) async {
    if (!forceRefresh && fcmToken != null && fcmToken!.isNotEmpty) {
      return fcmToken;
    }
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        debugPrint('\n======================================================');
        debugPrint('🔥 FCM TOKEN 🔥:');
        debugPrint('$fcmToken');
        debugPrint('======================================================\n');
      } else {
        debugPrint('⚠️ FCM Token returned null.');
      }
      return fcmToken;
    } catch (e) {
      debugPrint('⚠️ Error fetching FCM token: $e');
      return null;
    }
  }

  static Future<void> syncFcmTokenToOdoo(BaseOdooService odooService) async {
    final token = await fetchFcmToken();
    if (token != null && token.isNotEmpty) {
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      debugPrint('Syncing FCM token ($token) to Odoo device token ($platform)...');
      await odooService.registerDeviceToken(token: token, platform: platform);
    }
  }

  static Future<void> initialize({BaseOdooService? odooService}) async {
    try {
      await Firebase.initializeApp();

      // Background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission for iOS / Android 13+
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission status: ${settings.authorizationStatus}');

      // Get FCM Token with retry handling
      final token = await fetchFcmToken();
      if (odooService != null && token != null) {
        final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
        await odooService.registerDeviceToken(token: token, platform: platform);
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) async {
        fcmToken = newToken;
        debugPrint('FCM Token Refreshed: $newToken');
        if (odooService != null) {
          final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
          await odooService.registerDeviceToken(token: newToken, platform: platform);
        }
      });

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        if (message.notification != null) {
          debugPrint('Message Title: ${message.notification?.title}');
          debugPrint('Message Body: ${message.notification?.body}');
        }
      });
    } catch (e, stack) {
      debugPrint('Error initializing Firebase / FCM: $e');
      debugPrint('$stack');
    }
  }
}
