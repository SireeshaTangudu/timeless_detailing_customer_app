import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/splash_screen.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/tracking/controllers/tracking_controller.dart';
import 'package:timeless_detailing_customer_app/features/tracking/controllers/projects_controller.dart';
import 'package:timeless_detailing_customer_app/core/theme/theme_controller.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // =========================================================================
  // ODOO INTEGRATION CONFIGURATION
  // =========================================================================
  final odooService = OdooApiService(
    baseUrl:
        'https://keerthan-lfi-lfi-timeless-detailing-uat-36441944.dev.odoo.com',
    db: 'keerthan-lfi-lfi-timeless-detailing-uat-36441944',
  );

  runApp(
    MultiProvider(
      providers: [
        // Core Odoo service provider injection
        Provider<BaseOdooService>.value(value: odooService),

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timeless Detailing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
