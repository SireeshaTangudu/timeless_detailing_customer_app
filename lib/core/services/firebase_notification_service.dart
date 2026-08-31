import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/estimation_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/estimation_screen.dart';
import 'package:timeless_detailing_customer_app/main.dart';

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

  static void handleNotificationNavigation(RemoteMessage message, BaseOdooService? odooService) {
    debugPrint('🔵 Handling notification navigation for message payload: ${message.data}');
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final orderIdStr = message.data['order_id'] ?? message.data['sale_order_id'] ?? message.data['id'];
    final orderId = int.tryParse(orderIdStr?.toString() ?? '');

    if (orderId != null && odooService != null) {
      odooService.getQuotationDetails(orderId).then((quotationData) {
        final currentCtx = navigatorKey.currentContext;
        if (quotationData != null && currentCtx != null) {
          final est = EstimationModel.fromOdooJson(quotationData);
          Navigator.push(
            currentCtx,
            MaterialPageRoute(
              builder: (context) => EstimationScreen(estimation: est),
            ),
          );
        } else if (currentCtx != null) {
          Navigator.push(
            currentCtx,
            MaterialPageRoute(
              builder: (context) => const EstimationScreen(),
            ),
          );
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EstimationScreen(),
        ),
      );
    }
  }

  static Future<void> initialize({BaseOdooService? odooService}) async {
    try {
      await Firebase.initializeApp();

      // Background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Foreground presentation options for iOS / Android
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

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

      // Handle App opened from Notification Tap when in Background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 App opened from notification tap!');
        handleNotificationNavigation(message, odooService);
      });

      // Handle App opened from Terminated state via Notification Tap
      messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('🔔 App launched from terminated state via notification tap!');
          handleNotificationNavigation(message, odooService);
        }
      });

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🟢 [FCM] Got a message whilst in the foreground! Data: ${message.data}');

        final title = message.notification?.title ??
            message.data['title'] ??
            'New Quotation Received!';
        final body = message.notification?.body ??
            message.data['body'] ??
            message.data['message'] ??
            'Your technician has generated your vehicle estimate. Tap to view and sign.';

        debugPrint('Title: $title, Body: $body');

        final context = navigatorKey.currentContext;
        if (context != null) {
          showDialog(
            context: context,
            builder: (dialogCtx) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1D1813),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFC4913F), width: 1),
                ),
                title: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFFC4913F),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  body,
                  style: GoogleFonts.montserrat(
                    fontSize: 13.5,
                    color: const Color(0xFFC5B7A1),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(
                      'DISMISS',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8C8273),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      handleNotificationNavigation(message, odooService);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4913F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'VIEW ESTIMATE',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      });
    } catch (e, stack) {
      debugPrint('Error initializing Firebase / FCM: $e');
      debugPrint('$stack');
    }
  }
}
