import 'package:flutter/foundation.dart';

enum TreatmentItemType {
  medication,
  therapy,
  surgery,
  consultation,
  procedure,
  equipment,
  service,
  test,
  other
}

@immutable
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

  const TreatmentItem({
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
    try {
      return TreatmentItem(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        type: TreatmentItemType.values.firstWhere(
          (e) => e.toString() == 'TreatmentItemType.${map['type']}',
          orElse: () => TreatmentItemType.other,
        ),
        description: map['description'] as String? ?? '',
        cost: (map['cost'] as num?)?.toDouble(),
        requiresPrescription: map['requiresPrescription'] as bool? ?? false,
        stockLevel: map['stockLevel'] as int?,
        facilityId: map['facilityId'] as String?,
        manufacturer: map['manufacturer'] as String?,
        dosageInfo: map['dosageInfo'] as String?,
        sideEffects: map['sideEffects'] != null
            ? List<String>.from(map['sideEffects'] as List)
            : null,
      );
    } catch (e) {
      debugPrint('Error creating TreatmentItem from map: $e');
      rethrow;
    }
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatmentItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          description == other.description &&
          cost == other.cost &&
          requiresPrescription == other.requiresPrescription &&
          stockLevel == other.stockLevel &&
          facilityId == other.facilityId &&
          manufacturer == other.manufacturer &&
          dosageInfo == other.dosageInfo &&
          listEquals(sideEffects, other.sideEffects);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      description.hashCode ^
      cost.hashCode ^
      requiresPrescription.hashCode ^
      stockLevel.hashCode ^
      facilityId.hashCode ^
      manufacturer.hashCode ^
      dosageInfo.hashCode ^
      (sideEffects?.hashCode ?? 0);

  @override
  String toString() =>
      'TreatmentItem(id: $id, name: $name, type: $type, cost: $cost, requiresPrescription: $requiresPrescription)';
}
