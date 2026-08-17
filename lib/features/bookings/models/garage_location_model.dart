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
    String address = json['address']?.toString() ?? '';
    if (address.isEmpty) {
      final street = (json['street'] != null && json['street'] != false)
          ? json['street'].toString()
          : '';
      final street2 = (json['street2'] != null && json['street2'] != false)
          ? json['street2'].toString()
          : '';
      final city = (json['city'] != null && json['city'] != false)
          ? json['city'].toString()
          : '';
      final state = (json['state_id'] is Map && json['state_id']['name'] != null)
          ? json['state_id']['name'].toString()
          : '';
      final zip = (json['zip'] != null && json['zip'] != false)
          ? json['zip'].toString()
          : '';
      final country = (json['country_id'] is Map && json['country_id']['name'] != null)
          ? json['country_id']['name'].toString()
          : '';

      address = [street, street2, city, state, zip, country]
          .where((s) => s.isNotEmpty && s != 'false')
          .join(', ');
    }

    final rawName = (json['name'] != null && json['name'] != false)
        ? json['name'].toString()
        : 'Timeless Detailing';

    return GarageLocation(
      id: json['id']?.toString() ?? '1',
      name: rawName,
      address: address.isNotEmpty
          ? address
          : '7 Crystal Crescent, Golden Crest Country Estate, Parkrand, Boksburg, 1459',
      phone: (json['phone'] != null && json['phone'] != false)
          ? json['phone'].toString()
          : '',
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : -25.933578,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : 28.18122,
      googlePlaceId: json['google_place_id']?.toString(),
      isDefault: json['is_default'] == true || json['id'] == 1,
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
