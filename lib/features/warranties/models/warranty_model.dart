class WarrantyModel {
  final int id;
  final String name;
  final String productName;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleRegistration;
  final String warrantyStart;
  final String warrantyEnd;
  final String status;
  final int? saleOrderId;
  final String? saleOrderName;

  const WarrantyModel({
    required this.id,
    required this.name,
    required this.productName,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleRegistration,
    required this.warrantyStart,
    required this.warrantyEnd,
    required this.status,
    this.saleOrderId,
    this.saleOrderName,
  });

  String get vehicleTitle {
    final title = '$vehicleMake $vehicleModel'.trim();
    return title;
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get isExpiring => status.toLowerCase() == 'expiring';
  bool get isExpired => status.toLowerCase() == 'expired';

  String get formattedStatus {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'expiring':
        return 'Expiring';
      case 'expired':
        return 'Expired';
      default:
        return status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'Active';
    }
  }

  factory WarrantyModel.fromJson(Map<String, dynamic> json) {
    String pName = '';
    final prodRaw = json['product_id'];
    if (prodRaw is Map && prodRaw['display_name'] != null && prodRaw['display_name'].toString().isNotEmpty) {
      pName = prodRaw['display_name'].toString();
    } else if (prodRaw is Map && prodRaw['name'] != null && prodRaw['name'].toString().isNotEmpty) {
      pName = prodRaw['name'].toString();
    } else if (prodRaw is List && prodRaw.length >= 2 && prodRaw[1].toString().isNotEmpty) {
      pName = prodRaw[1].toString();
    }

    int? soId;
    String? soName;
    final soRaw = json['sale_order_id'];
    if (soRaw is Map) {
      if (soRaw['id'] is int) soId = soRaw['id'] as int;
      if (soRaw['name'] != null) soName = soRaw['name'].toString();
    } else if (soRaw is List && soRaw.isNotEmpty) {
      if (soRaw[0] is int) soId = soRaw[0] as int;
      if (soRaw.length >= 2) soName = soRaw[1].toString();
    }

    return WarrantyModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      productName: pName,
      vehicleMake: (json['vehicle_make'] ?? '').toString(),
      vehicleModel: (json['vehicle_model'] ?? '').toString(),
      vehicleRegistration: (json['vehicle_registration'] ?? '').toString(),
      warrantyStart: (json['warranty_start'] ?? '').toString(),
      warrantyEnd: (json['warranty_end'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      saleOrderId: soId,
      saleOrderName: soName,
    );
  }
}
