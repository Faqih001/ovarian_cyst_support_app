import 'package:flutter/material.dart';

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final TimeOfDay time;
  final DateTime startDate;
  final DateTime? endDate;
  final bool reminderEnabled;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.startDate,
    this.endDate,
    this.reminderEnabled = false,
  });

  // Convert from Map to Medication object
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      name: map['name'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      time: TimeOfDay(hour: map['timeHour'], minute: map['timeMinute']),
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      reminderEnabled: map['reminderEnabled'] ?? false,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'reminderEnabled': reminderEnabled,
    };
  }
}
