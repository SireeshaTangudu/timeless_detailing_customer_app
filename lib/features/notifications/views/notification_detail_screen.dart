import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/core/services/firebase_notification_service.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';

class NotificationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final notifId = widget.notification['id'];
    if (notifId is int) {
      setState(() => _isLoading = true);
      final odooService = Provider.of<BaseOdooService>(context, listen: false);
      final detail = await odooService.getNotificationDetail(notifId);
      if (mounted) {
        setState(() {
          _detailData = detail ?? widget.notification;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _detailData = widget.notification);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notif = _detailData ?? widget.notification;

    final title =
        notif['title'] ??
        notif['name'] ??
        notif['subject'] ??
        'Notification Detail';
    final body =
        notif['body'] ??
        notif['message'] ??
        notif['description'] ??
        'No message body provided.';

    String dateStr = '';
    final rawDate = notif['date'] ?? notif['create_date'];
    if (rawDate != null) {
      final dt = DateTime.tryParse(rawDate.toString().replaceAll(' ', 'T'));
      if (dt != null) {
        final localDt = dt.add(const Duration(hours: 2));
        dateStr = DateFormat('dd MMMM yyyy, hh:mm a').format(localDt);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      appBar: CustomAppBar(
        title: 'Notification Detail',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC4913F)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Card Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBE7DF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFC4913F,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_active_outlined,
                                color: Color(0xFFC4913F),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1D1813),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Color(0xFF8C8273),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: const Color(0xFF8C8273),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notification Message Body Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBE7DF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MESSAGE',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC4913F),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          body
                              .replaceAll('&nbsp;', ' ')
                              .replaceAll('&amp;', '&')
                              .replaceAll('&quot;', '"')
                              .replaceAll('&#39;', "'")
                              .replaceAll('&lt;', '<')
                              .replaceAll('&gt;', '>')
                              .replaceAll(
                                RegExp(r'<br\s*/?>', caseSensitive: false),
                                '\n',
                              )
                              .replaceAll(RegExp(r'<[^>]*>'), '')
                              .trim(),
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF3A2F1E),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Action Button based on notification_type
                  Builder(
                    builder: (context) {
                      final notifType =
                          (notif['notification_type'] ?? notif['type'] ?? '')
                              .toString()
                              .toLowerCase();
                      final resModel =
                          (notif['res_model'] ?? notif['model'] ?? '')
                              .toString()
                              .toLowerCase();
                      final titleStr =
                          (notif['title'] ??
                                  notif['name'] ??
                                  notif['subject'] ??
                                  '')
                              .toString()
                              .toLowerCase();
                      final String bodyStr =
                          (notif['body'] ??
                                  notif['message'] ??
                                  notif['description'] ??
                                  '')
                              .toString()
                              .toLowerCase();

                      final bool isBookingConfirmed =
                          notifType.contains('booking') ||
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
                        return const SizedBox.shrink();
                      }

                      int? extractId(dynamic raw) {
                        if (raw is int && raw > 0) return raw;
                        if (raw is String) return int.tryParse(raw);
                        if (raw is List && raw.isNotEmpty && raw.first is int)
                          return raw.first as int;
                        if (raw is Map && raw['id'] is int)
                          return raw['id'] as int;
                        if (raw is Map && raw['id'] is String)
                          return int.tryParse(raw['id'] as String);
                        return null;
                      }

                      final int? saleOrderId = extractId(
                        notif['sale_order_id'],
                      );

                      final bool isProjectOrTaskUpdate =
                          notifType == 'project_update' ||
                          notifType == 'task_update' ||
                          notifType.contains('pipeline') ||
                          notifType.contains('tracking') ||
                          resModel == 'project.project' ||
                          resModel == 'project.task' ||
                          titleStr.contains('status') ||
                          titleStr.contains('pipeline') ||
                          titleStr.contains('live track') ||
                          titleStr.contains('progress');

                      final bool isQuotationSent =
                          notifType == 'quotation_sent' ||
                          resModel == 'sale.order' ||
                          (saleOrderId != null && saleOrderId > 0) ||
                          titleStr.contains('quotation') ||
                          titleStr.contains('estimation') ||
                          titleStr.contains('quote');

                      final bool isDownPaymentOrInvoice =
                          notifType.contains('down') ||
                          notifType.contains('invoice') ||
                          resModel.contains('account.move') ||
                          titleStr.contains('down payment') ||
                          titleStr.contains('invoice');

                      String buttonText = 'VIEW DETAILS';
                      IconData buttonIcon = Icons.arrow_forward_rounded;

                      if (isProjectOrTaskUpdate) {
                        buttonText = 'VIEW TRACKING PROGRESS';
                        buttonIcon = Icons.track_changes_outlined;
                      } else if (isQuotationSent) {
                        buttonText = 'REVIEW';
                        buttonIcon = Icons.request_quote_outlined;
                      } else if (isDownPaymentOrInvoice) {
                        buttonText = 'VIEW INVOICE & PAY';
                        buttonIcon = Icons.receipt_long_outlined;
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final odooService = Provider.of<BaseOdooService>(
                              context,
                              listen: false,
                            );
                            FirebaseNotificationService.handleNotificationMapNavigation(
                              context,
                              notif,
                              odooService,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC4913F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(buttonIcon, size: 20),
                          label: Text(
                            buttonText,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
