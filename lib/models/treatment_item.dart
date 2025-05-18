class TreatmentItem {
  final String id;
  final String name;
  final TreatmentItemType type;
  final String description;
  final double? cost;
  final bool requiresPrescription;
  final int? stockLevel;
  final String? facilityId;
  final String? manufacturer;
  final String? dosageInfo;
  final List<String>? sideEffects;

  TreatmentItem({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.cost,
    required this.requiresPrescription,
    this.stockLevel,
    this.facilityId,
    this.manufacturer,
    this.dosageInfo,
    this.sideEffects,
  });

  // Create a copy with updated values
  TreatmentItem copyWith({
    String? id,
    String? name,
    TreatmentItemType? type,
    String? description,
    double? cost,
    bool? requiresPrescription,
    int? stockLevel,
    String? facilityId,
    String? manufacturer,
    String? dosageInfo,
    List<String>? sideEffects,
  }) {
    return TreatmentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      requiresPrescription: requiresPrescription ?? this.requiresPrescription,
      stockLevel: stockLevel ?? this.stockLevel,
      facilityId: facilityId ?? this.facilityId,
      manufacturer: manufacturer ?? this.manufacturer,
      dosageInfo: dosageInfo ?? this.dosageInfo,
      sideEffects: sideEffects ?? this.sideEffects,
    );
  }

  // Convert from JSON
  factory TreatmentItem.fromJson(Map<String, dynamic> json) {
    return TreatmentItem(
      id: json['id'],
      name: json['name'],
      type: TreatmentItemType.values.firstWhere(
        (e) => e.toString() == 'TreatmentItemType.${json['type']}',
        orElse: () => TreatmentItemType.medication,
      ),
      description: json['description'],
      cost: json['cost'],
      requiresPrescription: json['requiresPrescription'] ?? false,
      stockLevel: json['stockLevel'],
      facilityId: json['facilityId'],
      manufacturer: json['manufacturer'],
      dosageInfo: json['dosageInfo'],
      sideEffects:
          json['sideEffects'] != null
              ? List<String>.from(json['sideEffects'])
              : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'description': description,
      'cost': cost,
      'requiresPrescription': requiresPrescription,
      'stockLevel': stockLevel,
      'facilityId': facilityId,
      'manufacturer': manufacturer,
      'dosageInfo': dosageInfo,
      'sideEffects': sideEffects,
    };
  }
}

enum TreatmentItemType {
  medication,
  equipment,
  procedure,
  service,
  test,
  other,
}
