import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header Image & Monogram
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.black),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          AppTheme.background.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIMELESS DETAILING',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Where automotive car care is a timeless standard',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar Selector
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.background,
              child: TabBar(
                controller: _subTabController,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Profile'),
                  Tab(text: 'Process'),
                  Tab(text: 'Our Team'),
                ],
              ),
            ),
          ),

          // Scrollable content based on sub tabs
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: TabBarView(
                controller: _subTabController,
                children: [
                  _buildProfileTab(context),
                  _buildProcessTab(context),
                  _buildTeamTab(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABOUT US',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Timeless Detailing is a premium automotive enhancement and protection studio based in Boksburg and Northlands Business Park. We specialise in high-end automotive detailing solutions which are tailored to car enthusiasts and vehicle owners who value craftsmanship and protection.\n\nOur craftsmanship quality will never be compromised. To us, every detail matters; from the smallest crevice to the final finish. We take pride in our service and treat every vehicle like it\'s our own. Through honesty, care, and clear communication, we ensure service delivery with no compromises along the way.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: 'MISSION',
                  desc:
                      'To REDEFINE automotive detailing in South Africa by offering premium, precise, and professional services, protecting and elevating every vehicle and delivering an unmatched customer experience.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: 'VISION',
                  desc:
                      'To become the most TRUSTED and recognized automotive detailing brand in the industry, where automotive care isn\'t just a service, but a timeless standard.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'STUDIO DETAILS',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            Icons.location_on_outlined,
            'Boksburg & Northlands Business Park',
          ),
          _buildContactRow(
            Icons.map_outlined,
            '7 Crystal Crescent, Golden Crest Country Estate, Parkrand, Boksburg, 1459',
          ),
          _buildContactRow(Icons.phone_android_outlined, '+27 60 974 3533'),
          _buildContactRow(Icons.mail_outline, 'timelessdetailingsa@gmail.com'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProcessTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OUR DETAILING PROCESS',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What makes Timeless Detailing stand out is our carefully refined process that balances luxury, precision, and trust. Here is how we elevate your detailing experience:',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildProcessStep(
            '1',
            'Detailed Pre-Inspection',
            'We believe every detail matters—especially the ones you can\'t see right away. Comprehensive paint diagnostics ensure transparency before we start.',
          ),
          _buildProcessStep(
            '2',
            'Tailored Treatment Plans',
            'Your services are curated to fit each vehicle\'s condition; every detail is personalized rather than just off-the-shelf packages.',
          ),
          _buildProcessStep(
            '3',
            'Certified Products & Expert Hands',
            'We are not experimenting on your car; we are perfecting it using battle-tested ceramic coatings, PPF films, and restore systems.',
          ),
          _buildProcessStep(
            '4',
            'Aftercare Support',
            'The Timeless Detail does not stop at the detail bay. It lives on in how your car performs and shines every single day.',
          ),
          _buildProcessStep(
            '5',
            'Premium Yet Personal',
            'We treat your car like our own; and your time like gold.',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTeamTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MEET THE EXPERTS',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'At Timeless Detailing, our team is small, skilled, and driven by passion. Every member plays a hands-on role in delivering excellence with each Timeless Detail. We\'re not just technicians—we\'re perfectionists and craftsmen.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_pin,
                        color: AppTheme.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reshlin Soorajpal',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Founder & Lead Detailer',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppTheme.divider),
                const SizedBox(height: 12),
                Text(
                  'Reshlin brings a sharp eye with over half a decade of hands-on experience and a deep love for all automotive aesthetics. As the founder, he leads every project with a perfectionist mindset, ensuring that each vehicle receives world-class treatment.\n\nHe is fully certified in paint correction, Paint Protection Film (PPF), and ceramic coatings installations.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13.5,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.montserrat(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            width: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.outfit(
                color: AppTheme.background,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
