import 'package:timeless_detailing_customer_app/core/services/currency_service.dart';

class SubscriptionModel {
  final int id;
  final String name;
  final String dateOrder;
  final String state;
  final bool isSubscription;
  final String subscriptionState;
  final String planName;
  final String startDate;
  final String? endDate;
  final String nextInvoiceDate;
  final double recurringTotal;
  final double amountTotal;
  final String currencySymbol;
  final List<Map<String, dynamic>> invoiceIds;
  final List<Map<String, dynamic>> orderLines;

  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.dateOrder,
    required this.state,
    required this.isSubscription,
    required this.subscriptionState,
    required this.planName,
    required this.startDate,
    this.endDate,
    required this.nextInvoiceDate,
    required this.recurringTotal,
    required this.amountTotal,
    required this.currencySymbol,
    required this.invoiceIds,
    required this.orderLines,
  });

  bool get isActive => state.toLowerCase() == 'sale' || subscriptionState.contains('progress');

  String get formattedStatus {
    if (subscriptionState == '3_progress' || subscriptionState == 'progress') {
      return 'Active Maintenance';
    }
    return subscriptionState.replaceAll('_', ' ').toUpperCase();
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    String pName = '';
    final planRaw = json['plan_id'];
    if (planRaw is Map && planRaw['display_name'] != null && planRaw['display_name'].toString().isNotEmpty) {
      pName = planRaw['display_name'].toString();
    } else if (planRaw is Map && planRaw['name'] != null && planRaw['name'].toString().isNotEmpty) {
      pName = planRaw['name'].toString();
    } else if (planRaw is List && planRaw.length >= 2 && planRaw[1].toString().isNotEmpty) {
      pName = planRaw[1].toString();
    } else if (json['name'] != null) {
      pName = 'Plan ${json['name']}';
    }

    String cSym = CurrencyService.instance.getSymbol(currencyId: json['currency_id']);
    final currRaw = json['currency_id'];
    if (currRaw is Map) {
      final sym = currRaw['symbol']?.toString();
      final cName = currRaw['name']?.toString();
      if (sym != null && sym.isNotEmpty && sym != 'null' && sym != 'false') {
        cSym = sym;
      } else if (cName == 'ZAR') {
        cSym = 'R';
      } else if (cName != null && cName.isNotEmpty) {
        cSym = cName;
      }
    } else if (currRaw is List && currRaw.length >= 2) {
      final val = currRaw[1].toString();
      cSym = val == 'ZAR' ? 'R' : val;
    }

    final List<Map<String, dynamic>> invList = [];
    final rawInvs = json['invoice_ids'];
    if (rawInvs is List) {
      for (final inv in rawInvs) {
        if (inv is Map) {
          invList.add(Map<String, dynamic>.from(inv));
        } else if (inv is List && inv.length >= 2) {
          invList.add({'id': inv[0], 'name': inv[1]});
        } else if (inv is int) {
          invList.add({'id': inv, 'name': 'INV/$inv'});
        }
      }
    }

    final List<Map<String, dynamic>> linesList = [];
    final rawLines = json['order_line'];
    if (rawLines is List) {
      for (final line in rawLines) {
        if (line is Map) {
          final lineMap = Map<String, dynamic>.from(line);
          final projId = lineMap['project_id'];
          final prodId = lineMap['product_id'];
          final nameStr = lineMap['name']?.toString().toLowerCase() ?? '';
          final bool isDownPayment = nameStr.contains('down payment');

          if (projId != null && projId != false && prodId != null && prodId != false && !isDownPayment) {
            if ((lineMap['name'] == null || lineMap['name'].toString().isEmpty) && lineMap['product_id'] is Map) {
              lineMap['name'] = lineMap['product_id']['display_name'] ?? lineMap['product_id']['name'] ?? '';
            }
            linesList.add(lineMap);
          }
        }
      }
    }

    final String? endDt = (json['end_date'] != null && json['end_date'] != false && json['end_date'] != 'false')
        ? json['end_date'].toString()
        : null;

    return SubscriptionModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      dateOrder: (json['date_order'] ?? '').toString(),
      state: (json['state'] ?? 'sale').toString(),
      isSubscription: json['is_subscription'] == true,
      subscriptionState: (json['subscription_state'] ?? '3_progress').toString(),
      planName: pName,
      startDate: (json['start_date'] ?? '').toString(),
      endDate: endDt,
      nextInvoiceDate: (json['next_invoice_date'] ?? '').toString(),
      recurringTotal: (json['recurring_total'] as num?)?.toDouble() ?? 0.0,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      currencySymbol: cSym,
      invoiceIds: invList,
      orderLines: linesList,
    );
  }
}
