import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/estimation_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/estimation_screen.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/upcoming_appointment_details_screen.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/bookings_history_screen.dart';
import 'package:timeless_detailing_customer_app/features/invoices/views/invoices_screen.dart';
import 'package:timeless_detailing_customer_app/features/warranties/views/warranties_screen.dart';
import 'package:timeless_detailing_customer_app/features/subscriptions/views/subscriptions_screen.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/notifications/views/notification_detail_screen.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';
import 'package:timeless_detailing_customer_app/features/tracking/views/project_details_screen.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/main_navigation_scaffold.dart';
import 'package:timeless_detailing_customer_app/main.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🌙 Handling background/killed message: ${message.messageId}, Data: ${message.data}');

  try {
    final title = message.notification?.title ??
        message.data['title'] ??
        'New Notification Received!';
    final body = message.notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        'You have received an update on your service.';

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

  static void resetTokenState() {
    debugPrint('🧹 Resetting cached FCM token state on logout...');
    fcmToken = null;
  }

  static Future<void> syncFcmTokenToOdoo(BaseOdooService odooService) async {
    final token = await fetchFcmToken(forceRefresh: true);
    if (token != null && token.isNotEmpty) {
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      debugPrint('Syncing FCM token ($token) to Odoo device token ($platform)...');
      await odooService.registerDeviceToken(token: token, platform: platform);
    }
  }

  static void _navigateToScreenFromNotification(
    BuildContext context,
    Widget screen, {
    bool resetToHome = false,
  }) {
    if (resetToHome) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScaffold()),
        (route) => false,
      );
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  static void handleNotificationNavigation(RemoteMessage message, BaseOdooService? odooService) {
    debugPrint('🔵 Handling notification navigation for message payload: ${message.data}');
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final notifMap = Map<String, dynamic>.from(message.data);
    if (message.notification?.title != null && notifMap['title'] == null) {
      notifMap['title'] = message.notification!.title;
    }
    if (message.notification?.body != null && notifMap['body'] == null) {
      notifMap['body'] = message.notification!.body;
    }

    handleNotificationMapNavigation(context, notifMap, odooService, resetToHome: true);
  }

  static Future<void> handleNotificationMapNavigation(
    BuildContext context,
    Map<String, dynamic> notif,
    BaseOdooService? odooService, {
    bool resetToHome = false,
  }) async {
    int? extractId(dynamic raw) {
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw);
      if (raw is List && raw.isNotEmpty) {
        if (raw.first is int) return raw.first as int;
        if (raw.first is String) return int.tryParse(raw.first as String);
      }
      if (raw is Map) {
        if (raw['id'] is int) return raw['id'] as int;
        if (raw['id'] is String) return int.tryParse(raw['id'] as String);
      }
      return null;
    }

    final int? notifPartnerId = extractId(notif['partner_id'] ?? notif['partnerId'] ?? notif['partner']);
    if (notifPartnerId != null && odooService?.currentPartnerId != null) {
      if (notifPartnerId != odooService!.currentPartnerId) {
        debugPrint(
          '⚠️ Notification partner_id ($notifPartnerId) does not match logged-in partner (${odooService.currentPartnerId}).',
        );
      }
    }

    final String notifType = (notif['notification_type'] ?? notif['type'] ?? '').toString().toLowerCase();
    final String resModel = (notif['res_model'] ?? notif['model'] ?? '').toString().toLowerCase();
    final String titleStr = (notif['title'] ?? notif['name'] ?? notif['subject'] ?? '').toString().toLowerCase();
    final String bodyStr = (notif['body'] ?? notif['message'] ?? notif['description'] ?? '').toString().toLowerCase();

    final int? resId = extractId(notif['res_id'] ?? notif['order_id'] ?? notif['sale_order_id'] ?? notif['id']);
    final int? saleOrderId = extractId(notif['sale_order_id']);

    // 1. Warranty Notifications (warranty_created, warranty_expiring, warranty_expired)
    final bool isWarrantyNotif = notifType.startsWith('warranty_') ||
        resModel == 'sale.warranty' ||
        titleStr.contains('warranty') ||
        bodyStr.contains('warranty');

    if (isWarrantyNotif) {
      if (context.mounted) {
        _navigateToScreenFromNotification(
          context,
          const WarrantiesScreen(),
          resetToHome: resetToHome,
        );
      }
      return;
    }

    // 2. Subscription Notifications (subscription_started, subscription_closed)
    final bool isSubscriptionNotif = notifType.startsWith('subscription_') ||
        titleStr.contains('subscription') ||
        bodyStr.contains('subscription');

    if (isSubscriptionNotif) {
      if (context.mounted) {
        _navigateToScreenFromNotification(
          context,
          const SubscriptionsScreen(),
          resetToHome: resetToHome,
        );
      }
      return;
    }

    // 3. Invoice Cancelled Notification (invoice_cancelled)
    final bool isInvoiceCancelled = notifType == 'invoice_cancelled' ||
        (notifType.contains('invoice') && (notifType.contains('cancel') || titleStr.contains('invoice cancel')));

    if (isInvoiceCancelled) {
      if (context.mounted) {
        _navigateToScreenFromNotification(
          context,
          const InvoicesScreen(),
          resetToHome: resetToHome,
        );
      }
      return;
    }

    // 4. Appointment Notifications (appointment_cancelled, appointment_rescheduled)
    final bool isAppointmentCancelled = notifType == 'appointment_cancelled' ||
        (resModel == 'calendar.event' && (titleStr.contains('cancel') || bodyStr.contains('cancel')));

    if (isAppointmentCancelled) {
      if (context.mounted) {
        _navigateToScreenFromNotification(
          context,
          const BookingsHistoryScreen(),
          resetToHome: resetToHome,
        );
      }
      return;
    }

    final bool isAppointmentRescheduled = notifType == 'appointment_rescheduled' ||
        (resModel == 'calendar.event' && (titleStr.contains('resched') || bodyStr.contains('resched') || notifType.contains('resched')));

    if (isAppointmentRescheduled) {
      if (resId != null && odooService != null) {
        try {
          final appointmentData = await odooService.getBookingDetails(resId);
          if (context.mounted && appointmentData != null) {
            final booking = Booking.fromOdooJson(
              appointmentData,
              const DetailService(
                id: '',
                name: '',
                description: '',
                price: 0,
                durationHours: 0,
                imageUrl: '',
                category: '',
                whatsIncluded: [],
              ),
            );
            _navigateToScreenFromNotification(
              context,
              UpcomingAppointmentDetailsScreen(booking: booking),
              resetToHome: resetToHome,
            );
            return;
          }
        } catch (_) {}
      }
      if (context.mounted) {
        _navigateToScreenFromNotification(
          context,
          const BookingsHistoryScreen(),
          resetToHome: resetToHome,
        );
      }
      return;
    }

    // 5. Quotation / Order Cancelled & Expired (quotation_cancelled, order_cancelled, quotation_expired)
    final bool isQuotationOrOrderCancelledOrExpired = notifType == 'quotation_cancelled' ||
        notifType == 'order_cancelled' ||
        notifType == 'quotation_expired';

    if (isQuotationOrOrderCancelledOrExpired) {
      final targetId = saleOrderId ?? resId;
      if (targetId != null && odooService != null && notifType != 'order_cancelled') {
        try {
          final quotationData = await odooService.getQuotationDetails(targetId);
          if (context.mounted && quotationData != null) {
            final est = EstimationModel.fromOdooJson(quotationData);
            _navigateToScreenFromNotification(
              context,
              EstimationScreen(estimation: est),
              resetToHome: resetToHome,
            );
            return;
          }
        } catch (_) {}
      }
      if (context.mounted) {
        _navigateToScreenFromNotification(
          context,
          const BookingsHistoryScreen(),
          resetToHome: resetToHome,
        );
      }
      return;
    }

    // 6. Active Invoices / Down Payment Notifications
    final bool isDownPaymentOrInvoice = notifType.contains('down') ||
        notifType.contains('invoice') ||
        resModel.contains('account.move') ||
        titleStr.contains('down payment') ||
        titleStr.contains('invoice');

    if (isDownPaymentOrInvoice) {
      final targetInvoiceId = resId ?? saleOrderId;
      if (targetInvoiceId != null && odooService != null) {
        try {
          final invoiceData = await odooService.getInvoiceDetails(targetInvoiceId);
          if (context.mounted && invoiceData != null) {
            final booking = Booking.fromInvoiceJson(invoiceData);
            _navigateToScreenFromNotification(
              context,
              UpcomingAppointmentDetailsScreen(
                booking: booking,
                isDownPaymentInvoice: true,
              ),
              resetToHome: resetToHome,
            );
            return;
          }
        } catch (_) {}
      }
      if (context.mounted) {
        _navigateToDefaultInvoiceScreen(
          context,
          (targetInvoiceId ?? 101).toString(),
          resetToHome: resetToHome,
        );
      }
      return;
    }

    // 7. Live Project / Task Updates
    final bool isProjectOrTaskUpdate = notifType == 'project_update' ||
        notifType == 'task_update' ||
        notifType.contains('pipeline') ||
        notifType.contains('live_track') ||
        notifType.contains('tracking') ||
        resModel == 'crm.lead' ||
        resModel == 'project.project' ||
        resModel == 'project.task' ||
        titleStr.contains('status update') ||
        titleStr.contains('pipeline update') ||
        titleStr.contains('live track') ||
        bodyStr.contains('status has been updated') ||
        bodyStr.contains("vehicle's status has been updated");

    if (isProjectOrTaskUpdate) {
      int? projId = extractId(notif['project_id']);
      int? taskId;

      if (notifType == 'task_update' || resModel == 'project.task') {
        taskId = resId;
        projId = projId ?? resId;
      } else {
        projId = resId ?? projId;
      }

      final targetProjId = projId ?? taskId ?? 36;
      final String projectTitle = (notif['title'] ?? notif['name'] ?? '').toString();
      final String cleanTitle = projectTitle.isNotEmpty ? projectTitle : 'Project #$targetProjId';

      if (odooService != null) {
        try {
          final projects = await odooService.getProjects(projectId: targetProjId);
          if (context.mounted) {
            ProjectModel? matchedProject;
            for (final p in projects) {
              if (p.id == targetProjId) {
                matchedProject = p;
                break;
              }
            }

            final targetProject = matchedProject ??
                ProjectModel(
                  id: targetProjId,
                  name: cleanTitle,
                  taskCount: 1,
                  labelTasks: 'Tasks',
                );

            _navigateToScreenFromNotification(
              context,
              ProjectDetailsScreen(
                project: targetProject,
                initialTaskId: taskId,
              ),
              resetToHome: resetToHome,
            );
            return;
          }
        } catch (_) {}
      }

      if (context.mounted) {
        final fallbackProject = ProjectModel(
          id: targetProjId,
          name: cleanTitle,
          taskCount: 1,
          labelTasks: 'Tasks',
        );
        _navigateToScreenFromNotification(
          context,
          ProjectDetailsScreen(
            project: fallbackProject,
            initialTaskId: taskId,
          ),
          resetToHome: resetToHome,
        );
      }
      return;
    }

    // 8. Quotation Sent
    final bool isQuotationSent = notifType == 'quotation_sent' ||
        resModel == 'sale.order' ||
        (saleOrderId != null && saleOrderId > 0) ||
        titleStr.contains('quotation') ||
        titleStr.contains('estimation');

    final targetId = saleOrderId ?? resId;

    if (isQuotationSent && targetId != null && odooService != null) {
      try {
        final quotationData = await odooService.getQuotationDetails(targetId);
        if (context.mounted) {
          final est = quotationData != null
              ? EstimationModel.fromOdooJson(quotationData)
              : EstimationModel.fromNotificationJson(notif);
          _navigateToScreenFromNotification(
            context,
            EstimationScreen(estimation: est),
            resetToHome: resetToHome,
          );
          return;
        }
      } catch (_) {}
    } else if (isQuotationSent) {
      if (context.mounted) {
        final est = EstimationModel.fromNotificationJson(notif);
        _navigateToScreenFromNotification(
          context,
          EstimationScreen(estimation: est),
          resetToHome: resetToHome,
        );
      }
      return;
    }

    // Default fallback: open NotificationDetailScreen
    if (context.mounted) {
      _navigateToScreenFromNotification(
        context,
        NotificationDetailScreen(notification: notif),
        resetToHome: resetToHome,
      );
    }
  }

  static void _navigateToDefaultInvoiceScreen(
    BuildContext context,
    String resIdStr, {
    bool resetToHome = false,
  }) {
    _navigateToScreenFromNotification(
      context,
      const InvoicesScreen(),
      resetToHome: resetToHome,
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
        String? oldToken = fcmToken;
        if (oldToken == null || oldToken.isEmpty) {
          try {
            final prefs = await SharedPreferences.getInstance();
            oldToken = prefs.getString('cached_fcm_token');
          } catch (_) {}
        }
        fcmToken = newToken;
        debugPrint('🔥 FCM Token Refreshed: old=$oldToken -> new=$newToken');
        if (odooService != null) {
          final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
          await odooService.registerDeviceToken(
            token: newToken,
            platform: platform,
            previousToken: (oldToken != null && oldToken != newToken) ? oldToken : null,
          );
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
