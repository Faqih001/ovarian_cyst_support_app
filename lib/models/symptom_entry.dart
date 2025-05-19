import 'package:cloud_firestore/cloud_firestore.dart';

class SymptomEntry {
  final String id;
  final DateTime date;
  final DateTime timestamp;
  final String description;
  final String mood;
  final int painLevel;
  final int bloatingLevel;
  final List<String> symptoms;
  final String notes;
  final bool isUploaded;
  final DateTime updatedAt;

  SymptomEntry({
    required this.id,
    required this.date,
    DateTime? timestamp,
    this.description = '',
    required this.mood,
    required this.painLevel,
    required this.bloatingLevel,
    required this.symptoms,
    this.notes = '',
    this.isUploaded = false,
    required this.updatedAt,
  }) : timestamp = timestamp ?? date;

  // Convert from Firestore DocumentSnapshot
  factory SymptomEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SymptomEntry(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
          (data['date'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      mood: data['mood'] ?? 'Neutral',
      painLevel: data['painLevel'] ?? 0,
      bloatingLevel: data['bloatingLevel'] ?? 0,
      symptoms: List<String>.from(data['symptoms'] ?? []),
      notes: data['notes'] ?? '',
      isUploaded: true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ??
          (data['date'] as Timestamp).toDate(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'mood': mood,
      'painLevel': painLevel,
      'bloatingLevel': bloatingLevel,
      'symptoms': symptoms,
      'notes': notes,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Convert from Map (for local storage compatibility)
  factory SymptomEntry.fromMap(Map<String, dynamic> map) {
    return SymptomEntry(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: map['date'] is String
          ? DateTime.parse(map['date'])
          : map['date'] is Timestamp
              ? (map['date'] as Timestamp).toDate()
              : map['date'],
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] is String
              ? DateTime.parse(map['timestamp'])
              : map['timestamp'] is Timestamp
                  ? (map['timestamp'] as Timestamp).toDate()
                  : map['timestamp'])
          : (map['date'] is String
              ? DateTime.parse(map['date'])
              : map['date'] is Timestamp
                  ? (map['date'] as Timestamp).toDate()
                  : map['date']),
      description: map['description'] ?? map['notes'] ?? '',
      mood: map['mood'],
      painLevel: map['painLevel'],
      bloatingLevel: map['bloatingLevel'] ?? 0,
      symptoms: map['symptoms'] is List<String>
          ? map['symptoms']
          : (map['symptoms'] as String?)?.split(',') ?? [],
      notes: map['notes'] ?? '',
      isUploaded: map['isUploaded'] == 1 || map['isUploaded'] == true,
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'])
          : map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : map['updatedAt'] ?? DateTime.now(),
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'mood': mood,
      'painLevel': painLevel,
      'bloatingLevel': bloatingLevel,
      'symptoms': symptoms.join(','),
      'notes': notes,
      'isUploaded': isUploaded ? 1 : 0,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with some fields changed
  SymptomEntry copyWith({
    String? id,
    DateTime? date,
    DateTime? timestamp,
    String? description,
    String? mood,
    int? painLevel,
    int? bloatingLevel,
    List<String>? symptoms,
    String? notes,
    bool? isUploaded,
    DateTime? updatedAt,
  }) {
    return SymptomEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      mood: mood ?? this.mood,
      painLevel: painLevel ?? this.painLevel,
      bloatingLevel: bloatingLevel ?? this.bloatingLevel,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      isUploaded: isUploaded ?? this.isUploaded,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
