import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyUsername = 'username';
  static const String _keyMedications = 'medications';
  static const String _keySymptomHistory = 'symptom_history';
  static const String _keyAppointments = 'appointments';

  // Onboarding Status
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  // User Information
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  static Future<void> setUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, name);
  }

  // Medication Management
  static Future<List<String>> getMedications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyMedications) ?? [];
  }

  static Future<void> saveMedication(String medication) async {
    final prefs = await SharedPreferences.getInstance();
    final medications = await getMedications();

    if (!medications.contains(medication)) {
      medications.add(medication);
      await prefs.setStringList(_keyMedications, medications);
    }
  }

  static Future<void> removeMedication(String medication) async {
    final prefs = await SharedPreferences.getInstance();
    final medications = await getMedications();

    if (medications.contains(medication)) {
      medications.remove(medication);
      await prefs.setStringList(_keyMedications, medications);
    }
  }

  // Symptom Tracking
  static Future<List<Map<String, dynamic>>> getSymptomHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final symptomJson = prefs.getStringList(_keySymptomHistory) ?? [];

    return symptomJson.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return map;
    }).toList();
  }

  static Future<void> saveSymptom(Map<String, dynamic> symptom) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSymptomHistory();

    history.add(symptom);

    final jsonHistory = history.map((item) => item.toString()).toList();
    await prefs.setStringList(_keySymptomHistory, jsonHistory);
  }

  // Appointment Management
  static Future<List<Map<String, dynamic>>> getAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = prefs.getStringList(_keyAppointments) ?? [];

    return appointmentsJson.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return map;
    }).toList();
  }

  static Future<void> saveAppointment(Map<String, dynamic> appointment) async {
    final prefs = await SharedPreferences.getInstance();
    final appointments = await getAppointments();

    appointments.add(appointment);

    final jsonAppointments =
        appointments.map((item) => item.toString()).toList();
    await prefs.setStringList(_keyAppointments, jsonAppointments);
  }

  static Future<void> removeAppointment(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final appointments = await getAppointments();

    if (index >= 0 && index < appointments.length) {
      appointments.removeAt(index);

      final jsonAppointments =
          appointments.map((item) => item.toString()).toList();
      await prefs.setStringList(_keyAppointments, jsonAppointments);
    }
  }

  // Clear all data (for logout functionality)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
