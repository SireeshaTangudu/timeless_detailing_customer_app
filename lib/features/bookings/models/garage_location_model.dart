class GarageLocation {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final String? googlePlaceId;
  final bool isDefault;

  const GarageLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.googlePlaceId,
    this.isDefault = false,
  });

  factory GarageLocation.fromJson(Map<String, dynamic> json) {
    return GarageLocation(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? json['street'] ?? '',
      phone: json['phone'] ?? '',
      latitude: (json['partner_latitude'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['partner_longitude'] ?? json['longitude'] ?? 0.0).toDouble(),
      googlePlaceId: json['google_place_id'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'google_place_id': googlePlaceId,
      'is_default': isDefault,
    };
  }

  /// Static sample list of multiple garage branches
  static List<GarageLocation> get defaultGarages {
    return const [
      GarageLocation(
        id: 'gar_1',
        name: 'Timeless Detailing - Sandton Main Branch',
        address: '123 Rivonia Rd, Sandton, Johannesburg',
        phone: '+27 11 123 4567',
        latitude: -26.10756,
        longitude: 28.05670,
        isDefault: true,
      ),
      GarageLocation(
        id: 'gar_2',
        name: 'Timeless Detailing - Rosebank Hub',
        address: '50 Bath Ave, Rosebank, Johannesburg',
        phone: '+27 11 987 6543',
        latitude: -26.14589,
        longitude: 28.04351,
      ),
      GarageLocation(
        id: 'gar_3',
        name: 'Timeless Detailing - Waterfront Workshop',
        address: 'Dock Rd, V&A Waterfront, Cape Town',
        phone: '+27 21 400 1122',
        latitude: -33.90562,
        longitude: 18.42111,
      ),
    ];
  }
}
