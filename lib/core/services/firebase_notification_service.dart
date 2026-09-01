import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/estimation_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/estimation_screen.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/upcoming_appointment_details_screen.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/main.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🌙 Handling background/killed message: ${message.messageId}, Data: ${message.data}');

  try {
    final title = message.notification?.title ??
        message.data['title'] ??
        'New Quotation Received!';
    final body = message.notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        'Your technician has generated your vehicle estimate.';

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
    );

    final FlutterLocalNotificationsPlugin backgroundLocalNotifications =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await backgroundLocalNotifications.initialize(settings: initializationSettings);

    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await backgroundLocalNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            htmlFormatBigText: true,
            htmlFormatContentTitle: true,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  } catch (e) {
    debugPrint('Error in background message notification display: $e');
  }
}

class FirebaseNotificationService {
  static String? fcmToken;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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

    final String resIdStr = (message.data['res_id'] ?? message.data['order_id'] ?? message.data['sale_order_id'] ?? message.data['id'] ?? '').toString();
    final int? resId = int.tryParse(resIdStr);

    final String typeStr = (message.data['type'] ?? message.data['model'] ?? message.data['notification_type'] ?? '').toString().toLowerCase();
    final String titleStr = (message.notification?.title ?? message.data['title'] ?? '').toString().toLowerCase();
    final bool isDownPaymentOrInvoice = typeStr.contains('down') || typeStr.contains('invoice') || typeStr.contains('account.move') || titleStr.contains('down payment') || titleStr.contains('invoice');

    if (isDownPaymentOrInvoice && resId != null && odooService != null) {
      debugPrint('🔵 Fetching invoice details for res_id=$resId via account.move/web_read...');
      odooService.getInvoiceDetails(resId).then((invoiceData) {
        final currentCtx = navigatorKey.currentContext;
        if (invoiceData != null && currentCtx != null) {
          final booking = Booking.fromInvoiceJson(invoiceData);
          Navigator.push(
            currentCtx,
            MaterialPageRoute(
              builder: (context) => UpcomingAppointmentDetailsScreen(
                booking: booking,
                isDownPaymentInvoice: true,
              ),
            ),
          );
        } else if (currentCtx != null) {
          _navigateToDefaultInvoiceScreen(currentCtx, resIdStr);
        }
      });
      return;
    } else if (isDownPaymentOrInvoice) {
      _navigateToDefaultInvoiceScreen(context, resIdStr);
      return;
    }

    if (resId != null && odooService != null) {
      odooService.getQuotationDetails(resId).then((quotationData) {
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

  static void _navigateToDefaultInvoiceScreen(BuildContext context, String resIdStr) {
    final fallbackBooking = Booking(
      id: resIdStr.isNotEmpty ? resIdStr : '101',
      service: const DetailService(
        id: '1',
        name: 'Ceramic Coating',
        description: '',
        price: 2242.5,
        durationHours: 2.0,
        imageUrl: '',
        category: 'Detailing',
        whatsIncluded: [],
      ),
      vehicleName: 'accept test test',
      vehicleLicensePlate: 'gfhj',
      bookingDateTime: DateTime.now(),
      status: BookingStatus.confirmed,
      currentStep: 1,
      totalPrice: 2242.5,
      notes: 'Down payment invoice',
      beforeImages: const [],
      afterImages: const [],
      technicianName: 'Master Detailer',
      technicianAvatar: '',
      isDownPaymentInvoice: true,
      percentageAmountPaid: 60.0,
      amountPaid: 1345.5,
      amountPaidOn: '2026-09-01',
      pendingAmount: 897.0,
      carDropOffStatus: 'Pending',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpcomingAppointmentDetailsScreen(
          booking: fallbackBooking,
          isDownPaymentInvoice: true,
        ),
      ),
    );
  }

  static Future<void> initialize({BaseOdooService? odooService}) async {
    try {
      await Firebase.initializeApp();

      // Background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Create Android high-importance notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
      );

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('🔔 System notification tapped! Payload: ${response.payload}');
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final Map<String, dynamic> data = Map<String, dynamic>.from(jsonDecode(response.payload!));
              final message = RemoteMessage(data: data);
              handleNotificationNavigation(message, odooService);
            } catch (e) {
              debugPrint('Error parsing notification payload: $e');
            }
          }
        },
      );

      // Create high-importance channel on Android
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
      }

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

      // Foreground message listener - Triggers native top status bar heads-up banner
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

        final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        _localNotifications.show(
          id: notificationId,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
              playSound: true,
              styleInformation: BigTextStyleInformation(
                body,
                contentTitle: title,
                htmlFormatBigText: true,
                htmlFormatContentTitle: true,
              ),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      });
    } catch (e, stack) {
      debugPrint('Error initializing Firebase / FCM: $e');
      debugPrint('$stack');
    }
  }
}
