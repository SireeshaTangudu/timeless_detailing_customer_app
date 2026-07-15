import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/dashboard_screen.dart';
import 'package:timeless_detailing_customer_app/features/services/views/services_list_screen.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/bookings_history_screen.dart';
import 'package:timeless_detailing_customer_app/features/about/views/about_us_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Only navigate via tab bar
        children: [
          DashboardScreen(tabController: _tabController),
          const ServicesListScreen(),
          const BookingsHistoryScreen(),
          const AboutUsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.divider, width: 1),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(color: AppTheme.primary, width: 3),
            borderRadius: BorderRadius.circular(3),
            insets: const EdgeInsets.symmetric(horizontal: 16),
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined),
              text: 'Home',
            ),
            Tab(
              icon: Icon(Icons.cleaning_services_outlined),
              text: 'Services',
            ),
            Tab(
              icon: Icon(Icons.calendar_month_outlined),
              text: 'Bookings',
            ),
            Tab(
              icon: Icon(Icons.info_outline),
              text: 'About Us',
            ),
          ],
        ),
      ),
    );
  }
}
