class Doctor {
  final String id;
  final String name;
  final String? specialty;
  final String? qualification;
  final String? registrationNumber;
  final String? email;
  final String? phone;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final List<String> availableDays;

  Doctor({
    required this.id,
    required this.name,
    this.specialty,
    this.qualification,
    this.registrationNumber,
    this.email,
    this.phone,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
    this.availableDays = const [],
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      specialty: json['specialty'] as String?,
      qualification: json['qualification'] as String?,
      registrationNumber: json['registration_number'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      availableDays:
          (json['available_days'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'qualification': qualification,
      'registration_number': registrationNumber,
      'email': email,
      'phone': phone,
      'description': description,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'available_days': availableDays,
    };
  }
}
