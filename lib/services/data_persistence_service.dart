import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/models/medication.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';

class DataPersistenceService {
  // Keys for various data types
  static const String _keySymptomEntries = 'symptom_entries';
  static const String _keyMedications = 'medications';
  static const String _keyAppointments = 'appointments';
  static const String _keyEducationalContent = 'educational_content';
  static const String _keyCommunityPosts = 'community_posts';
  static const String _keyLastSyncTime = 'last_sync_time';

  // Symptom Entries
  static Future<List<SymptomEntry>> getSymptomEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_keySymptomEntries) ?? [];

    return entriesJson
        .map((json) => SymptomEntry.fromMap(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveSymptomEntry(SymptomEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getSymptomEntries();

    entries.add(entry);

    final jsonEntries =
        entries.map((entry) => jsonEncode(entry.toMap())).toList();

    await prefs.setStringList(_keySymptomEntries, jsonEntries);
  }

  static Future<void> updateSymptomEntry(
    int index,
    SymptomEntry updatedEntry,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getSymptomEntries();

    if (index >= 0 && index < entries.length) {
      entries[index] = updatedEntry;

      final jsonEntries =
          entries.map((entry) => jsonEncode(entry.toMap())).toList();

      await prefs.setStringList(_keySymptomEntries, jsonEntries);
    }
  }

  static Future<void> deleteSymptomEntry(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getSymptomEntries();

    if (index >= 0 && index < entries.length) {
      entries.removeAt(index);

      final jsonEntries =
          entries.map((entry) => jsonEncode(entry.toMap())).toList();

      await prefs.setStringList(_keySymptomEntries, jsonEntries);
    }
  }

  // Medications
  static Future<List<Medication>> getMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final medsJson = prefs.getStringList(_keyMedications) ?? [];

    return medsJson
        .map((json) => Medication.fromMap(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveMedication(Medication medication) async {
    final prefs = await SharedPreferences.getInstance();
    final medications = await getMedications();

    medications.add(medication);

    final jsonMedications =
        medications.map((med) => jsonEncode(med.toMap())).toList();

    await prefs.setStringList(_keyMedications, jsonMedications);
  }

  static Future<void> updateMedication(
    int index,
    Medication updatedMedication,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final medications = await getMedications();

    if (index >= 0 && index < medications.length) {
      medications[index] = updatedMedication;

      final jsonMedications =
          medications.map((med) => jsonEncode(med.toMap())).toList();

      await prefs.setStringList(_keyMedications, jsonMedications);
    }
  }

  static Future<void> deleteMedication(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final medications = await getMedications();

    if (index >= 0 && index < medications.length) {
      medications.removeAt(index);

      final jsonMedications =
          medications.map((med) => jsonEncode(med.toMap())).toList();

      await prefs.setStringList(_keyMedications, jsonMedications);
    }
  }

  // Appointments
  static Future<List<Appointment>> getAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final apptsJson = prefs.getStringList(_keyAppointments) ?? [];

    return apptsJson
        .map((json) => Appointment.fromMap(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveAppointment(Appointment appointment) async {
    final prefs = await SharedPreferences.getInstance();
    final appointments = await getAppointments();

    appointments.add(appointment);

    final jsonAppointments =
        appointments.map((appt) => jsonEncode(appt.toMap())).toList();

    await prefs.setStringList(_keyAppointments, jsonAppointments);
  }

  static Future<void> updateAppointment(
    int index,
    Appointment updatedAppointment,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final appointments = await getAppointments();

    if (index >= 0 && index < appointments.length) {
      appointments[index] = updatedAppointment;

      final jsonAppointments =
          appointments.map((appt) => jsonEncode(appt.toMap())).toList();

      await prefs.setStringList(_keyAppointments, jsonAppointments);
    }
  }

  static Future<void> deleteAppointment(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final appointments = await getAppointments();

    if (index >= 0 && index < appointments.length) {
      appointments.removeAt(index);

      final jsonAppointments =
          appointments.map((appt) => jsonEncode(appt.toMap())).toList();

      await prefs.setStringList(_keyAppointments, jsonAppointments);
    }
  }

  // Educational Content
  static Future<Map<String, dynamic>> getEducationalContent() async {
    final prefs = await SharedPreferences.getInstance();
    final contentJson = prefs.getString(_keyEducationalContent);

    if (contentJson == null) {
      return {};
    }

    return jsonDecode(contentJson);
  }

  static Future<void> saveEducationalContent(
    Map<String, dynamic> content,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEducationalContent, jsonEncode(content));
  }

  // Sync Status
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_keyLastSyncTime);

    if (timeString == null) {
      return null;
    }

    return DateTime.parse(timeString);
  }

  static Future<void> updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSyncTime, DateTime.now().toIso8601String());
  }

  // Community Posts (Simplified for offline access)
  static Future<List<Map<String, dynamic>>> getCommunityPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getStringList(_keyCommunityPosts) ?? [];

    return postsJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> saveCommunityPosts(
    List<Map<String, dynamic>> posts,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonPosts = posts.map((post) => jsonEncode(post)).toList();

    await prefs.setStringList(_keyCommunityPosts, jsonPosts);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
