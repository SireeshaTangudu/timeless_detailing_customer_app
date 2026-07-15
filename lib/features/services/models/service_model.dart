class DetailService {
  final String id;
  final String name;
  final String description;
  final double price;
  final double durationHours;
  final String imageUrl;
  final String category;
  final List<String> whatsIncluded;
  final int? odooProductId; // Maps to Odoo's product.product id

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
  });

  // Factory constructor to create a DetailService from Odoo JSON-RPC response map
  factory DetailService.fromOdooJson(Map<String, dynamic> json) {
    // Helper to extract list from Odoo's HTML/text fields or JSON
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
      durationHours: (json['detailing_duration'] as num?)?.toDouble() ?? 2.0, // custom Odoo field or fallback
      imageUrl: json['image_url'] ?? '',
      category: json['categ_id'] is List 
          ? (json['categ_id'] as List)[1].toString() 
          : (json['categ_id']?.toString() ?? 'General'),
      whatsIncluded: parseIncluded(json['whats_included']),
      odooProductId: json['id'] is int ? json['id'] as int : null,
    );
  }

  // Convert to Map for local database caching or mock representations
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
    };
  }
}
