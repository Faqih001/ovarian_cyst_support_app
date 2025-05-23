import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/services/firestore_repository.dart';

/// Repository for working with symptom entries in Firestore
class SymptomEntryRepository extends FirestoreRepository<SymptomEntry> {
  SymptomEntryRepository()
      : super(
          collectionPath: 'symptom_entries',
          fromMap: (map) => SymptomEntry.fromMap(map),
          toMap: (entry) => entry.toMap(),
        );

  /// Get symptom entries from a specific date range
  Future<List<SymptomEntry>> getEntriesInDateRange(
      DateTime start, DateTime end) async {
    final startDate = start.toIso8601String().split('T')[0];
    final endDate = end.toIso8601String().split('T')[0];

    return await query(
      field: 'date',
      isGreaterThanOrEqualTo: startDate,
      isLessThanOrEqualTo: '${endDate}Z', // Add Z to include the entire day
    );
  }

  /// Get entries with high pain levels (7+)
  Future<List<SymptomEntry>> getHighPainEntries() async {
    return await query(
      field: 'painLevel',
      isGreaterThanOrEqualTo: 7,
    );
  }

  /// Get entries with a specific mood
  Future<List<SymptomEntry>> getEntriesByMood(String mood) async {
    return await query(
      field: 'mood',
      isEqualTo: mood,
    );
  }

  /// Get latest entry
  Future<SymptomEntry?> getLatestEntry() async {
    final entries = await query(
      field: 'date',
      isLessThan: DateTime.now().toIso8601String(),
    );

    if (entries.isEmpty) return null;

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.first;
  }

  /// Get real-time stream of entries for a specific month
  Stream<List<SymptomEntry>> getMonthlyEntriesStream(int year, int month) {
    final startDate = DateTime(year, month, 1).toIso8601String().split('T')[0];
    final endDate =
        '${DateTime(year, month + 1, 0).toIso8601String().split('T')[0]}Z';

    return queryStream(
      field: 'date',
      isGreaterThanOrEqualTo: startDate,
      isLessThanOrEqualTo: endDate,
      orderBy: 'date',
      descending: true,
    );
  }
}
