import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/dashboard_screen.dart';
import 'package:timeless_detailing_customer_app/features/services/views/services_list_screen.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/bookings_history_screen.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/profile_screen.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/login_screen.dart';
import 'package:timeless_detailing_customer_app/features/about/views/about_us_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  int _currentIndex = 0;

  void _openDrawer() {
    debugPrint(
      '🔵 [MainNavigationScaffold] Opening side drawer via _scaffoldKey!',
    );
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSelectItem(int index) {
    _tabController.animateTo(index);
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context); // Close side drawer
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppTheme.primary : const Color(0xFF7A7A7E),
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : const Color(0xFF3A2F1E),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => _onSelectItem(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // User Profile Header in Side Drawer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F7F4),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEBE7DF), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        border: Border.all(color: AppTheme.primary, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.userName,
                            style: AppTypography.canela(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3A2F1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.userEmail.isNotEmpty
                                ? auth.userEmail
                                : 'Customer Account',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF7A7A7E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sidebar Navigation Items
              _buildDrawerItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                title: 'Home',
                index: 0,
              ),
              _buildDrawerItem(
                icon: Icons.cleaning_services_outlined,
                activeIcon: Icons.cleaning_services,
                title: 'Services',
                index: 1,
              ),
              _buildDrawerItem(
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month,
                title: 'Bookings',
                index: 2,
              ),
              _buildDrawerItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                title: 'Profile',
                index: 3,
              ),

              // _buildDrawerItem(
              //   icon: Icons.info_outline,
              //   activeIcon: Icons.info,
              //   title: 'About Us',
              //   index: 4,
              // ),
              const Spacer(),
              const Divider(color: Color(0xFFEBE7DF), height: 1),

              // Logout Option
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Color(0xFFE74C3C),
                    size: 22,
                  ),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE74C3C),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    final navigator = Navigator.of(
                      context,
                      rootNavigator: true,
                    );
                    final auth = Provider.of<AuthController>(
                      context,
                      listen: false,
                    );
                    auth.logout();

                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DashboardScreen(
            tabController: _tabController,
            onMenuTap: _openDrawer,
          ),
          ServicesListScreen(onMenuTap: () => _tabController.animateTo(0)),
          BookingsHistoryScreen(onMenuTap: () => _tabController.animateTo(0)),
          ProfileScreen(
            tabController: _tabController,
            onMenuTap: () => _tabController.animateTo(0),
          ),
          AboutUsScreen(onMenuTap: _openDrawer),
        ],
      ),
    );
  }
}
