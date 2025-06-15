class Facility {
  final String id;
  final String code;
  final String name;
  final String facilityType;
  final String county;
  final String subCounty;
  final String ward;
  final String owner;
  final String operationalStatus;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? website;
  final String? postalAddress;
  final String? description;
  final List<String> services;

  Facility({
    required this.id,
    required this.code,
    required this.name,
    required this.facilityType,
    required this.county,
    required this.subCounty,
    required this.ward,
    required this.owner,
    required this.operationalStatus,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.website,
    this.postalAddress,
    this.description,
    this.services = const [],
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    // Extract services from nested structure if available
    List<String> servicesList = [];
    if (json['services'] != null && json['services'] is List) {
      servicesList = (json['services'] as List)
          .map((service) => service is Map<String, dynamic>
              ? service['name'] as String? ?? ''
              : '')
          .where((name) => name.isNotEmpty)
          .toList();
    }

    return Facility(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      facilityType:
          json['facility_type'] != null && json['facility_type'] is Map
              ? json['facility_type']['name'] as String? ?? 'Unknown'
              : 'Unknown',
      county: json['county'] != null && json['county'] is Map
          ? json['county']['name'] as String? ?? 'Unknown'
          : 'Unknown',
      subCounty: json['sub_county'] != null && json['sub_county'] is Map
          ? json['sub_county']['name'] as String? ?? 'Unknown'
          : 'Unknown',
      ward: json['ward'] != null && json['ward'] is Map
          ? json['ward']['name'] as String? ?? 'Unknown'
          : 'Unknown',
      owner: json['owner'] != null && json['owner'] is Map
          ? json['owner']['name'] as String? ?? 'Unknown'
          : 'Unknown',
      operationalStatus:
          json['operation_status'] != null && json['operation_status'] is Map
              ? json['operation_status']['name'] as String? ?? 'Unknown'
              : 'Unknown',
      latitude:
          json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      longitude: json['long'] != null
          ? double.tryParse(json['long'].toString())
          : null,
      phone: json['phone_number'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      postalAddress: json['postal_address'] as String?,
      description: json['description'] as String?,
      services: servicesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'facility_type': facilityType,
      'county': county,
      'sub_county': subCounty,
      'ward': ward,
      'owner': owner,
      'operation_status': operationalStatus,
      'lat': latitude,
      'long': longitude,
      'phone_number': phone,
      'email': email,
      'website': website,
      'postal_address': postalAddress,
      'description': description,
      'services': services,
    };
  }
}
