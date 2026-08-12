class DetailService {
  final String id;
  final String name;
  final String description;
  final double price;
  final double durationHours;
  final String imageUrl;
  final String category;
  final List<String> whatsIncluded;
  final int? odooProductId;
  final int? appointmentTypeId;
  final String? assetImagePath;

  const DetailService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationHours,
    required this.imageUrl,
    required this.category,
    required this.whatsIncluded,
    this.odooProductId,
    this.appointmentTypeId,
    this.assetImagePath,
  });

  factory DetailService.fromOdooJson(Map<String, dynamic> json) {
    List<String> parseIncluded(dynamic included) {
      if (included == null) return [];
      if (included is List) {
        return included.map((e) => e.toString()).toList();
      }
      if (included is String) {
        return included
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    final rawPrice = json['list_price'] ?? json['lst_price'];
    final priceVal = (rawPrice is num) ? rawPrice.toDouble() : 0.0;
    final serviceName = json['name']?.toString() ?? 'Unknown Service';
    final lowerName = serviceName.toLowerCase();

    String derivedCategory = json['categ_id'] is List
        ? (json['categ_id'] as List)[1].toString()
        : (json['categ_id']?.toString() ?? 'General');

    String? assetImg;
    if (lowerName.contains('ppf') || lowerName.contains('protect')) {
      if (derivedCategory == 'General') derivedCategory = 'Protection';
      assetImg = 'assets/services/paint_care/paint_care.png';
    } else if (lowerName.contains('paint') ||
        lowerName.contains('correction') ||
        lowerName.contains('enhancement')) {
      if (derivedCategory == 'General') derivedCategory = 'Exterior';
      assetImg = 'assets/services/paint_care/paint_care.png';
    } else if (lowerName.contains('interior')) {
      if (derivedCategory == 'General') derivedCategory = 'Interior';
      assetImg = 'assets/services/interior/interior_detailing.png';
    }

    int? apptTypeId;
    if (json['appointment_type_id'] is Map) {
      final map = json['appointment_type_id'] as Map;
      apptTypeId = map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? '');
    } else if (json['appointment_type_id'] is List &&
        (json['appointment_type_id'] as List).isNotEmpty) {
      apptTypeId = (json['appointment_type_id'] as List)[0] is int
          ? (json['appointment_type_id'] as List)[0] as int
          : int.tryParse((json['appointment_type_id'] as List)[0]?.toString() ?? '');
    } else if (json['appointment_type_id'] is int) {
      apptTypeId = json['appointment_type_id'] as int;
    }

    return DetailService(
      id: json['id']?.toString() ?? json['id'].toString(),
      name: serviceName,
      description: json['description_sale']?.toString() ??
          json['description']?.toString() ??
          'Comprehensive professional detailing treatment for exceptional vehicle restoration and protection.',
      price: priceVal,
      durationHours: (json['detailing_duration'] as num?)?.toDouble() ?? 3.0,
      imageUrl: json['image_url']?.toString() ?? '',
      category: derivedCategory,
      whatsIncluded: parseIncluded(json['whats_included']),
      odooProductId: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      appointmentTypeId: apptTypeId,
      assetImagePath: assetImg,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'durationHours': durationHours,
      'imageUrl': imageUrl,
      'category': category,
      'whatsIncluded': whatsIncluded,
      'odooProductId': odooProductId,
      'assetImagePath': assetImagePath,
    };
  }
}
