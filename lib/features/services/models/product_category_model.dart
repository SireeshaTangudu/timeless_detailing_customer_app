class ProductCategory {
  final int id;
  final String name;
  final int sequence;
  final String? image;
  final String? writeDate;

  const ProductCategory({
    required this.id,
    required this.name,
    this.sequence = 0,
    this.image,
    this.writeDate,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      sequence: json['sequence'] is int ? json['sequence'] as int : 0,
      image: json['image'] is String ? json['image'] as String : null,
      writeDate: json['write_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sequence': sequence,
      'image': image,
      'write_date': writeDate,
    };
  }
}
