import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuotationModel {
  final int id;
  final String name;
  final String? dateOrder;
  final String? validityDate;
  final double amountUntaxed;
  final double amountTax;
  final double amountTotal;
  final int? currencyId;
  final String state;
  final bool isSubscription;
  final String? subscriptionState;
  final int? planId;
  final String? planName;
  final String? nextInvoiceDate;
  final double recurringTotal;
  final int? partnerId;
  final String? partnerName;

  const QuotationModel({
    required this.id,
    required this.name,
    this.dateOrder,
    this.validityDate,
    required this.amountUntaxed,
    required this.amountTax,
    required this.amountTotal,
    this.currencyId,
    required this.state,
    required this.isSubscription,
    this.subscriptionState,
    this.planId,
    this.planName,
    this.nextInvoiceDate,
    required this.recurringTotal,
    this.partnerId,
    this.partnerName,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    // Helper to extract id from map/list/int
    int? parseId(dynamic val) {
      if (val is int) return val;
      if (val is Map && val['id'] is int) return val['id'] as int;
      if (val is List && val.isNotEmpty && val[0] is int) return val[0] as int;
      return null;
    }

    // Helper to extract name from map/list/string
    String? parseName(dynamic val) {
      if (val is String) return val;
      if (val is Map && val['name'] is String) return val['name'] as String;
      if (val is List && val.length > 1 && val[1] is String) {
        return val[1] as String;
      }
      return null;
    }

    return QuotationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      dateOrder: json['date_order'] is String ? json['date_order'] as String : null,
      validityDate: json['validity_date'] is String ? json['validity_date'] as String : null,
      amountUntaxed: (json['amount_untaxed'] as num?)?.toDouble() ?? 0.0,
      amountTax: (json['amount_tax'] as num?)?.toDouble() ?? 0.0,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      currencyId: parseId(json['currency_id']),
      state: json['state']?.toString() ?? '',
      isSubscription: json['is_subscription'] == true,
      subscriptionState: json['subscription_state'] is String ? json['subscription_state'] as String : null,
      planId: parseId(json['plan_id']),
      planName: parseName(json['plan_id']),
      nextInvoiceDate: json['next_invoice_date'] is String ? json['next_invoice_date'] as String : null,
      recurringTotal: (json['recurring_total'] as num?)?.toDouble() ?? 0.0,
      partnerId: parseId(json['partner_id']),
      partnerName: parseName(json['partner_id']),
    );
  }

  String get formattedDateOrder {
    if (dateOrder == null || dateOrder!.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(dateOrder!);
      return DateFormat('MMM dd, yyyy').format(parsed);
    } catch (_) {
      return dateOrder!;
    }
  }

  String get formattedValidityDate {
    if (validityDate == null || validityDate!.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(validityDate!);
      return DateFormat('MMM dd, yyyy').format(parsed);
    } catch (_) {
      return validityDate!;
    }
  }

  String get stateLabel {
    switch (state.toLowerCase()) {
      case 'sent':
        return 'Quotation Sent';
      case 'sale':
        return 'Sales Order';
      case 'cancel':
        return 'Cancelled';
      case 'draft':
        return 'Quotation Draft';
      default:
        return state.isNotEmpty
            ? '${state[0].toUpperCase()}${state.substring(1)}'
            : 'Unknown';
    }
  }

  Color get stateColor {
    switch (state.toLowerCase()) {
      case 'sent':
        return const Color(0xFFC4913F); // Warm gold
      case 'sale':
        return const Color(0xFF27AE60); // Green
      case 'cancel':
        return const Color(0xFFE74C3C); // Red
      case 'draft':
        return const Color(0xFF3498DB); // Blue
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  Color get stateBackgroundColor {
    return stateColor.withValues(alpha: 0.12);
  }

  Color get foldColor {
    switch (state.toLowerCase()) {
      case 'sent':
        return const Color(0xFF8E6320);
      case 'sale':
        return const Color(0xFF1E8449);
      case 'cancel':
        return const Color(0xFF900C3F);
      case 'draft':
        return const Color(0xFF1F618D);
      default:
        return const Color(0xFF4A4A4A);
    }
  }
}
