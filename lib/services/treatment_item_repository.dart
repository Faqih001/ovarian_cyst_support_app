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
  Future<List<TreatmentItem>> getTreatmentsByType(String type) async {
    return await query(
      field: 'type',
      isEqualTo: type,
    );
  }

  /// Get treatments by facility
  Future<List<TreatmentItem>> getTreatmentsByFacility(String facilityId) async {
    return await query(
      field: 'facilityId',
      isEqualTo: facilityId,
    );
  }

  /// Get treatments that require prescription
  Future<List<TreatmentItem>> getPrescriptionTreatments() async {
    return await query(
      field: 'requiresPrescription',
      isEqualTo: true,
    );
  }

  /// Get low stock treatments
  Future<List<TreatmentItem>> getLowStockTreatments(int threshold) async {
    return await query(
      field: 'stockLevel',
      isLessThanOrEqualTo: threshold,
    );
  }

  /// Get treatments by price range
  Future<List<TreatmentItem>> getTreatmentsByPriceRange(
      double min, double max) async {
    final items = await query(
      field: 'cost',
      isGreaterThanOrEqualTo: min,
    );

    return items
        .where((item) => (item.cost ?? double.infinity) <= max)
        .toList();
  }

  /// Get treatments with a specific manufacturer
  Future<List<TreatmentItem>> getTreatmentsByManufacturer(
      String manufacturer) async {
    return await query(
      field: 'manufacturer',
      isEqualTo: manufacturer,
    );
  }
}
