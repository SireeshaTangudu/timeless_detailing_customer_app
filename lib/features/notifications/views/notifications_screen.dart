import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';
import 'package:timeless_detailing_customer_app/features/notifications/views/notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final odooService = Provider.of<BaseOdooService>(context, listen: false);
      final notifs = await odooService.getUserNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      appBar: CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(child: FourRotatingDotsLoader())
          : RefreshIndicator(
              color: const Color(0xFFC4913F),
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: Color(0xFFD6C8B4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Notifications Yet',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3A2F1E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Updates about your bookings, vehicle inspection, and quotations will appear here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: const Color(0xFF7A7A7E),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final title = notif['title'] ??
                            notif['name'] ??
                            notif['subject'] ??
                            'Notification Update';
                        final body = notif['body'] ??
                            notif['message'] ??
                            notif['description'] ??
                            '';
                        final isRead = notif['read'] == true || notif['is_read'] == true;

                        String timeStr = '';
                        final rawDate = notif['date'] ?? notif['create_date'];
                        if (rawDate != null) {
                          final dt = DateTime.tryParse(
                              rawDate.toString().replaceAll(' ', 'T'));
                          if (dt != null) {
                            final localDt = dt.add(const Duration(hours: 2));
                            timeStr = DateFormat('dd MMM, hh:mm a').format(localDt);
                          }
                        }

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NotificationDetailScreen(notification: notif),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isRead ? Colors.white : const Color(0xFFFFFDF8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRead
                                    ? const Color(0xFFEBE7DF)
                                    : const Color(0xFFEEDBB2),
                                width: isRead ? 1 : 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isRead
                                        ? const Color(0xFFF0ECE1)
                                        : const Color(0xFFC4913F).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isRead
                                        ? Icons.notifications_none_outlined
                                        : Icons.notifications_active_outlined,
                                    color: isRead
                                        ? const Color(0xFF8C8273)
                                        : const Color(0xFFC4913F),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.bold,
                                                color: const Color(0xFF3A2F1E),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (timeStr.isNotEmpty)
                                            Text(
                                              timeStr,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 11,
                                                color: const Color(0xFF9E9384),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (body.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          body
                                              .replaceAll('&nbsp;', ' ')
                                              .replaceAll('&amp;', '&')
                                              .replaceAll('&quot;', '"')
                                              .replaceAll('&#39;', "'")
                                              .replaceAll('&lt;', '<')
                                              .replaceAll('&gt;', '>')
                                              .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
                                              .replaceAll(RegExp(r'<[^>]*>'), '')
                                              .trim(),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12.5,
                                            color: const Color(0xFF6B5F4D),
                                            height: 1.35,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFFC5B7A1),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
