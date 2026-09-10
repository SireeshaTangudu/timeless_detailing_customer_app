import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/config/app_config.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/splash_screen.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/tracking/controllers/tracking_controller.dart';
import 'package:timeless_detailing_customer_app/features/tracking/controllers/projects_controller.dart';
import 'package:timeless_detailing_customer_app/features/warranties/controllers/warranties_controller.dart';
import 'package:timeless_detailing_customer_app/features/subscriptions/controllers/subscriptions_controller.dart';
import 'package:timeless_detailing_customer_app/features/quotations/controllers/quotations_controller.dart';
import 'package:timeless_detailing_customer_app/core/theme/theme_controller.dart';

import 'package:timeless_detailing_customer_app/core/services/network_connectivity_service.dart';
import 'package:timeless_detailing_customer_app/core/services/firebase_notification_service.dart';
import 'package:timeless_detailing_customer_app/core/services/currency_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  if (!AppConfig.isInitialized) {
    AppConfig.init(
      environment: Environment.uat,
      appName: 'Timeless Detailing UAT',
      baseUrl:
          'https://keerthan-lfi-lfi-timeless-detailing1-uat-37440283.dev.odoo.com',
      db: 'keerthan-lfi-lfi-timeless-detailing1-uat-37440283',
    );
  }
  await bootstrap();
}

/// Shared initialization logic called by main.dart, main_uat.dart, and main_prod.dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await CurrencyService.instance.init();

  // =========================================================================
  // ODOO INTEGRATION CONFIGURATION FROM APPCONFIG
  // =========================================================================
  final config = AppConfig.instance;
  final odooService = OdooApiService(
    baseUrl: config.baseUrl,
    db: config.db,
  );

  // Initialize Firebase & FCM asynchronously so runApp is NEVER blocked on startup
  FirebaseNotificationService.initialize(odooService: odooService).catchError((
    e,
  ) {
    debugPrint('⚠️ FirebaseNotificationService initialize error: $e');
  });

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // Core Odoo service provider injection
        Provider<BaseOdooService>.value(value: odooService),
        ChangeNotifierProvider(create: (context) => NetworkConnectivityService()),

        // Feature Controller Providers
        ChangeNotifierProvider(
          create: (context) => AuthController(odooService),
        ),
        ChangeNotifierProvider(create: (context) => ThemeController()),
        ChangeNotifierProvider(create: (context) => DashboardController()),
        ChangeNotifierProvider(
          create: (context) => ServicesController(odooService),
        ),
        ChangeNotifierProvider(
          create: (context) => BookingsController(odooService),
        ),
        ChangeNotifierProvider(
          create: (context) => ProjectsController(odooService),
        ),
        ChangeNotifierProvider(
          create: (context) => WarrantiesController(odooService),
        ),
        ChangeNotifierProvider(
          create: (context) => SubscriptionsController(odooService),
        ),
        ChangeNotifierProvider(
          create: (context) => QuotationsController(odooService),
        ),
        ChangeNotifierProxyProvider2<
          BaseOdooService,
          BookingsController,
          TrackingController
        >(
          create: (context) => TrackingController(
            odooService,
            Provider.of<BookingsController>(context, listen: false),
          ),
          update: (context, odoo, bookings, previous) =>
              previous ?? TrackingController(odoo, bookings),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Timeless Detailing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
