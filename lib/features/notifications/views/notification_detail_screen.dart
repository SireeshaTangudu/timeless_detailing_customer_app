import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/estimation_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/estimation_screen.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';
import 'package:timeless_detailing_customer_app/features/tracking/views/project_details_screen.dart';

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

                  // Action button navigating to Estimation Screen
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final notifType = (notif['notification_type'] ?? notif['type'] ?? '').toString().toLowerCase();
                        final resModel = (notif['res_model'] ?? notif['model'] ?? '').toString().toLowerCase();
                        final odooService = Provider.of<BaseOdooService>(context, listen: false);

                        final bool isProjectOrTaskUpdate = notifType == 'project_update' ||
                            notifType == 'task_update' ||
                            resModel == 'project.project' ||
                            resModel == 'project.task';

                        if (isProjectOrTaskUpdate) {
                          int? projId;
                          int? taskId;
                          final rawProj = notif['project_id'];
                          if (rawProj is Map && rawProj['id'] is int) {
                            projId = rawProj['id'] as int;
                          } else if (rawProj is int) {
                            projId = rawProj;
                          }

                          final resIdRaw = notif['res_id'] ?? notif['order_id'];
                          final resId = int.tryParse(resIdRaw?.toString() ?? '');

                          if (notifType == 'task_update' || resModel == 'project.task') {
                            taskId = resId;
                            projId = projId ?? resId ?? 37;
                          } else {
                            projId = resId ?? projId ?? 36;
                          }

                          final title = notif['title']?.toString() ?? 'Project #$projId';

                          odooService.getProjects(projectId: projId).then((projects) {
                            if (!mounted) return;
                            ProjectModel? matched;
                            for (final p in projects) {
                              if (p.id == projId) {
                                matched = p;
                                break;
                              }
                            }
                            final targetProj = matched ?? ProjectModel(
                              id: projId!,
                              name: title,
                              taskCount: 1,
                              labelTasks: 'Tasks',
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailsScreen(
                                  project: targetProj,
                                  initialTaskId: taskId,
                                ),
                              ),
                            );
                          });
                          return;
                        }

                        final rawSaleOrderId = notif['sale_order_id'];
                        int? saleOrderId;
                        if (rawSaleOrderId is List && rawSaleOrderId.isNotEmpty && rawSaleOrderId.first is int) {
                          saleOrderId = rawSaleOrderId.first as int;
                        } else if (rawSaleOrderId is int) {
                          saleOrderId = rawSaleOrderId;
                        } else if (rawSaleOrderId is String) {
                          saleOrderId = int.tryParse(rawSaleOrderId);
                        }

                        final resIdRaw = notif['order_id'] ?? notif['res_id'];
                        final resId = int.tryParse(resIdRaw?.toString() ?? '');

                        final bool isQuotationSent = notifType == 'quotation_sent' ||
                            resModel == 'sale.order' ||
                            (saleOrderId != null && saleOrderId > 0);

                        final targetId = saleOrderId ?? resId;

                        if (isQuotationSent && targetId != null) {
                          odooService.getQuotationDetails(targetId).then((quotationData) {
                            if (mounted && quotationData != null) {
                              final est = EstimationModel.fromOdooJson(quotationData);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EstimationScreen(estimation: est),
                                ),
                              );
                            } else if (mounted) {
                              final est = EstimationModel.fromNotificationJson(notif);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EstimationScreen(estimation: est),
                                ),
                              );
                            }
                          });
                        } else {
                          final est = EstimationModel.fromNotificationJson(notif);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EstimationScreen(estimation: est),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4913F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.track_changes_outlined, size: 20),
                      label: Text(
                        (notif['notification_type'] ?? '') == 'task_update' || (notif['notification_type'] ?? '') == 'project_update'
                            ? 'VIEW TRACKING PROGRESS'
                            : 'VIEW DETAILS',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
