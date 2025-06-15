class Appointment {
  final String id;
  final String doctorName;
  final String providerName;
  final String specialization;
  final String purpose;
  final DateTime dateTime;
  final String location;
  final String? notes;
  final bool reminderEnabled;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.providerName,
    required this.specialization,
    required this.purpose,
    required this.dateTime,
    required this.location,
    this.notes,
    this.reminderEnabled = false,
  });

  // Convert from Map to Appointment object
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      doctorName: map['doctorName'],
      providerName: map['providerName'] ?? map['doctorName'],
      specialization: map['specialization'] ?? 'General',
      purpose: map['purpose'],
      dateTime: DateTime.parse(map['dateTime']),
      location: map['location'],
      notes: map['notes'],
      reminderEnabled: map['reminderEnabled'] ?? false,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorName': doctorName,
      'providerName': providerName,
      'specialization': specialization,
      'purpose': purpose,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
    };
  }
}
