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
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/notifications/views/notifications_screen.dart';
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

  static void _navigateToScreenFromNotification(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScaffold()),
      (route) => false,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  static void handleNotificationNavigation(RemoteMessage message, BaseOdooService? odooService) {
    debugPrint('🔵 Handling notification navigation for message payload: ${message.data}');
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final String notifType = (message.data['notification_type'] ?? message.data['type'] ?? '').toString().toLowerCase();
    final String resModel = (message.data['res_model'] ?? message.data['model'] ?? '').toString().toLowerCase();
    final String resIdStr = (message.data['res_id'] ?? message.data['order_id'] ?? message.data['sale_order_id'] ?? message.data['id'] ?? '').toString();
    final int? resId = int.tryParse(resIdStr);
    final dynamic rawSaleOrderId = message.data['sale_order_id'];

    int? saleOrderId;
    if (rawSaleOrderId is List && rawSaleOrderId.isNotEmpty && rawSaleOrderId.first is int) {
      saleOrderId = rawSaleOrderId.first as int;
    } else if (rawSaleOrderId is int) {
      saleOrderId = rawSaleOrderId;
    } else if (rawSaleOrderId is String) {
      saleOrderId = int.tryParse(rawSaleOrderId);
    }

    final String titleStr = (message.notification?.title ?? message.data['title'] ?? '').toString().toLowerCase();
    final String bodyStr = (message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '').toString().toLowerCase();

    final bool isDownPaymentOrInvoice = notifType.contains('down') || notifType.contains('invoice') || resModel.contains('account.move') || titleStr.contains('down payment') || titleStr.contains('invoice');

    if (isDownPaymentOrInvoice && resId != null && odooService != null) {
      debugPrint('🔵 Fetching invoice details for res_id=$resId via account.move/web_read...');
      odooService.getInvoiceDetails(resId).then((invoiceData) {
        final currentCtx = navigatorKey.currentContext;
        if (invoiceData != null && currentCtx != null) {
          final booking = Booking.fromInvoiceJson(invoiceData);
          _navigateToScreenFromNotification(
            currentCtx,
            UpcomingAppointmentDetailsScreen(
              booking: booking,
              isDownPaymentInvoice: true,
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

    final bool isBookingConfirmed = notifType.contains('booking') ||
        notifType.contains('appointment') ||
        resModel == 'calendar.event' ||
        resModel == 'appointment.booking' ||
        titleStr.contains('booking confirmed') ||
        titleStr.contains('booking confirmation') ||
        titleStr.contains('appointment confirmed') ||
        titleStr.contains('booking received') ||
        bodyStr.contains('booking confirmed') ||
        bodyStr.contains('booking confirmation') ||
        bodyStr.contains('appointment confirmed') ||
        bodyStr.contains('successfully booked') ||
        bodyStr.contains('has been confirmed');

    if (isBookingConfirmed) {
      debugPrint('🔵 Booking confirmed notification tapped -> Navigating to NotificationsScreen');
      _navigateToScreenFromNotification(context, const NotificationsScreen());
      return;
    }

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
        bodyStr.contains('vehicle\'s status has been updated');

    if (isProjectOrTaskUpdate) {
      int? projectIdFromData;
      final rawProjId = message.data['project_id'];
      if (rawProjId is Map) {
        projectIdFromData = int.tryParse(rawProjId['id']?.toString() ?? '');
      } else if (rawProjId is List && rawProjId.isNotEmpty) {
        projectIdFromData = int.tryParse(rawProjId.first.toString());
      } else if (rawProjId is int) {
        projectIdFromData = rawProjId;
      } else if (rawProjId is String && rawProjId.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawProjId);
          if (decoded is Map) {
            projectIdFromData = int.tryParse(decoded['id']?.toString() ?? '');
          } else if (decoded is int) {
            projectIdFromData = decoded;
          }
        } catch (_) {
          projectIdFromData = int.tryParse(rawProjId);
        }
      }

      int targetProjectId;
      int? targetTaskId;

      if (notifType == 'task_update' || resModel == 'project.task') {
        targetTaskId = resId;
        targetProjectId = projectIdFromData ?? resId ?? 37;
      } else {
        targetProjectId = resId ?? projectIdFromData ?? 36;
      }

      debugPrint('🔵 Project/Task update notification tapped -> Navigating to ProjectDetailsScreen for project ID=$targetProjectId, task ID=$targetTaskId');

      final String projectTitle = (message.data['title'] ?? message.notification?.title ?? '').toString();
      final String cleanTitle = projectTitle.isNotEmpty ? projectTitle : 'Project #$targetProjectId';

      if (odooService != null) {
        odooService.getProjects(projectId: targetProjectId).then((projects) {
          final currentCtx = navigatorKey.currentContext;
          if (currentCtx == null) return;

          ProjectModel? matchedProject;
          for (final p in projects) {
            if (p.id == targetProjectId) {
              matchedProject = p;
              break;
            }
          }

          final targetProject = matchedProject ?? ProjectModel(
            id: targetProjectId,
            name: cleanTitle,
            taskCount: 1,
            labelTasks: 'Tasks',
          );

          _navigateToScreenFromNotification(
            currentCtx,
            ProjectDetailsScreen(
              project: targetProject,
              initialTaskId: targetTaskId,
            ),
          );
        }).catchError((err) {
          debugPrint('🟡 Error fetching project details for notification navigation: $err');
          final currentCtx = navigatorKey.currentContext;
          if (currentCtx != null) {
            final fallbackProject = ProjectModel(
              id: targetProjectId,
              name: cleanTitle,
              taskCount: 1,
              labelTasks: 'Tasks',
            );
            _navigateToScreenFromNotification(
              currentCtx,
              ProjectDetailsScreen(
                project: fallbackProject,
                initialTaskId: targetTaskId,
              ),
            );
          }
        });
      } else {
        final fallbackProject = ProjectModel(
          id: targetProjectId,
          name: cleanTitle,
          taskCount: 1,
          labelTasks: 'Tasks',
        );
        _navigateToScreenFromNotification(
          context,
          ProjectDetailsScreen(
            project: fallbackProject,
            initialTaskId: targetTaskId,
          ),
        );
      }
      return;
    }

    final bool isQuotationSent = notifType == 'quotation_sent' ||
        resModel == 'sale.order' ||
        (saleOrderId != null && saleOrderId > 0);

    final targetId = saleOrderId ?? resId;

    if (isQuotationSent && targetId != null && odooService != null) {
      odooService.getQuotationDetails(targetId).then((quotationData) {
        final currentCtx = navigatorKey.currentContext;
        if (quotationData != null && currentCtx != null) {
          final est = EstimationModel.fromOdooJson(quotationData);
          _navigateToScreenFromNotification(
            currentCtx,
            EstimationScreen(estimation: est),
          );
        } else if (currentCtx != null) {
          final est = EstimationModel.fromNotificationJson(message.data);
          _navigateToScreenFromNotification(
            currentCtx,
            EstimationScreen(estimation: est),
          );
        }
      });
    } else {
      final est = EstimationModel.fromNotificationJson(message.data);
      _navigateToScreenFromNotification(
        context,
        EstimationScreen(estimation: est),
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

    _navigateToScreenFromNotification(
      context,
      UpcomingAppointmentDetailsScreen(
        booking: fallbackBooking,
        isDownPaymentInvoice: true,
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
