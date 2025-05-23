import 'package:ovarian_cyst_support_app/models/treatment_item.dart';
import 'package:ovarian_cyst_support_app/services/firestore_repository.dart';

/// Repository for working with treatment items in Firestore
class TreatmentItemRepository extends FirestoreRepository<TreatmentItem> {
  TreatmentItemRepository()
      : super(
          collectionPath: 'treatment_items',
          fromMap: (map) => TreatmentItem.fromMap(map),
          toMap: (item) => item.toMap(),
        );

  /// Get treatments by type
  Future<List<TreatmentItem>> getTreatmentsByType(String type) {
    return query(
      field: 'type',
      isEqualTo: type,
    );
  }

  /// Get treatments by facility
  Future<List<TreatmentItem>> getTreatmentsByFacility(String facilityId) {
    return query(
      field: 'facilityId',
      isEqualTo: facilityId,
    );
  }

  /// Get treatments that require prescription
  Future<List<TreatmentItem>> getPrescriptionTreatments() {
    return query(
      field: 'requiresPrescription',
      isEqualTo: true,
    );
  }

  /// Get low stock treatments
  Future<List<TreatmentItem>> getLowStockTreatments(int threshold) {
    return query(
      field: 'stockLevel',
      isLessThanOrEqualTo: threshold,
    );
  }

  /// Get treatments by price range
  Future<List<TreatmentItem>> getTreatmentsByPriceRange(
      double min, double max) async {
    if (min > max) {
      throw ArgumentError('Minimum price cannot be greater than maximum price');
    }

    final items = await query(
      field: 'cost',
      isGreaterThanOrEqualTo: min,
    );

    return items
        .where((item) => (item.cost ?? double.infinity) <= max)
        .toList();
  }

  /// Get treatments with a specific manufacturer
  Future<List<TreatmentItem>> getTreatmentsByManufacturer(String manufacturer) {
    return query(
      field: 'manufacturer',
      isEqualTo: manufacturer,
    );
  }
}
