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

    return DetailService(
      id: json['id']?.toString() ?? json['id'].toString(),
      name: json['name'] ?? 'Unknown Service',
      description: json['description_sale'] ?? json['description'] ?? 'Premium detailing service.',
      price: (json['lst_price'] as num?)?.toDouble() ?? 0.0,
      durationHours: (json['detailing_duration'] as num?)?.toDouble() ?? 2.0,
      imageUrl: json['image_url'] ?? '',
      category: json['categ_id'] is List 
          ? (json['categ_id'] as List)[1].toString() 
          : (json['categ_id']?.toString() ?? 'General'),
      whatsIncluded: parseIncluded(json['whats_included']),
      odooProductId: json['id'] is int ? json['id'] as int : null,
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
