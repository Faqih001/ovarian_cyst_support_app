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

  // Convert from Map (for Firestore)
  factory TreatmentItem.fromMap(Map<String, dynamic> map) {
    return TreatmentItem(
      id: map['id'],
      name: map['name'],
      type: TreatmentItemType.values.firstWhere(
        (e) => e.toString() == 'TreatmentItemType.${map['type']}',
        orElse: () => TreatmentItemType.medication,
      ),
      description: map['description'],
      cost: map['cost'],
      requiresPrescription: map['requiresPrescription'] ?? false,
      stockLevel: map['stockLevel'],
      facilityId: map['facilityId'],
      manufacturer: map['manufacturer'],
      dosageInfo: map['dosageInfo'],
      sideEffects: map['sideEffects'] != null
          ? List<String>.from(map['sideEffects'])
          : null,
    );
  }

  // Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
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

  // Convert from JSON
  factory TreatmentItem.fromJson(Map<String, dynamic> json) {
    return TreatmentItem.fromMap(json);
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return toMap();
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
