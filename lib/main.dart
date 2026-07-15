import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/login_screen.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/main_navigation_scaffold.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/tracking/controllers/tracking_controller.dart';

void main() {
  // =========================================================================
  // ODOO INTEGRATION CONFIGURATION
  // =========================================================================
  // To connect to your live Odoo database, comment out MockOdooService
  // and uncomment the OdooApiService block below:
  //
  final odooService = OdooApiService(
    baseUrl:
        'https://demo-lfi-timeless-detailing-staging-33762385.dev.odoo.com',
    db: 'demo-lfi-timeless-detailing-staging-33762385',
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
        ChangeNotifierProvider(create: (context) => DashboardController()),
        ChangeNotifierProvider(
          create: (context) => ServicesController(odooService),
        ),
        ChangeNotifierProvider(
          create: (context) => BookingsController(odooService),
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
      theme: AppTheme.darkTheme,
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listens to Auth state to swap between login screen and main home tabs
    final authController = Provider.of<AuthController>(context);

    if (authController.isAuthenticated) {
      return const MainNavigationScaffold();
    } else {
      return const LoginScreen();
    }
  }
}
