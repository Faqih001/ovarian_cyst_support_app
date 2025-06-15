import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final String appointmentsCollection = 'appointments';

  // Get all appointments for a user
  Future<List<Appointment>> getUserAppointments(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(appointmentsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('appointmentDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
                'dateTime': (doc.data()
                            as Map<String, dynamic>)['appointmentDate'] !=
                        null
                    ? (doc.data() as Map<String, dynamic>)['appointmentDate']
                        .toDate()
                        .toIso8601String()
                    : DateTime.now().toIso8601String(),
                'doctorName':
                    (doc.data() as Map<String, dynamic>)['doctorName'] ??
                        (doc.data() as Map<String, dynamic>)['providerName'] ??
                        'Doctor',
                'providerName':
                    (doc.data() as Map<String, dynamic>)['facilityName'] ??
                        (doc.data() as Map<String, dynamic>)['providerName'] ??
                        'Facility',
                'location': (doc.data() as Map<String, dynamic>)['location'] ??
                    ((doc.data() as Map<String, dynamic>)['county'] != null
                        ? "${(doc.data() as Map<String, dynamic>)['county']}, Kenya"
                        : 'Kenya'),
                'purpose': (doc.data() as Map<String, dynamic>)['purpose'] ??
                    (doc.data() as Map<String, dynamic>)['reason'] ??
                    'Consultation',
                'notes': (doc.data() as Map<String, dynamic>)['notes'],
                'reminderEnabled':
                    (doc.data() as Map<String, dynamic>)['reminderEnabled'] ??
                        false,
                'specialization':
                    (doc.data() as Map<String, dynamic>)['specialization'] ??
                        'General',
              }))
          .toList();
    } catch (e) {
      _logger.e('Error getting user appointments: $e');
      throw Exception('Failed to load appointments');
    }
  }

  // Get upcoming appointments for a user
  Future<List<Appointment>> getUpcomingAppointments(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(appointmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .orderBy('appointmentDate', descending: false)
          .limit(5)
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
                'dateTime': (doc.data()
                            as Map<String, dynamic>)['appointmentDate'] !=
                        null
                    ? (doc.data() as Map<String, dynamic>)['appointmentDate']
                        .toDate()
                        .toIso8601String()
                    : DateTime.now().toIso8601String(),
                'doctorName':
                    (doc.data() as Map<String, dynamic>)['doctorName'] ??
                        (doc.data() as Map<String, dynamic>)['providerName'] ??
                        'Doctor',
                'providerName':
                    (doc.data() as Map<String, dynamic>)['facilityName'] ??
                        (doc.data() as Map<String, dynamic>)['providerName'] ??
                        'Facility',
                'location': (doc.data() as Map<String, dynamic>)['location'] ??
                    ((doc.data() as Map<String, dynamic>)['county'] != null
                        ? "${(doc.data() as Map<String, dynamic>)['county']}, Kenya"
                        : 'Kenya'),
                'purpose': (doc.data() as Map<String, dynamic>)['purpose'] ??
                    (doc.data() as Map<String, dynamic>)['reason'] ??
                    'Consultation',
                'notes': (doc.data() as Map<String, dynamic>)['notes'],
                'reminderEnabled':
                    (doc.data() as Map<String, dynamic>)['reminderEnabled'] ??
                        false,
                'specialization':
                    (doc.data() as Map<String, dynamic>)['specialization'] ??
                        'General',
              }))
          .toList();
    } catch (e) {
      _logger.e('Error getting upcoming appointments: $e');
      throw Exception('Failed to load upcoming appointments');
    }
  }

  // Add a new appointment
  Future<String> addAppointment(Map<String, dynamic> appointmentData) async {
    try {
      final docRef = await _firestore
          .collection(appointmentsCollection)
          .add(appointmentData);

      return docRef.id;
    } catch (e) {
      _logger.e('Error adding appointment: $e');
      throw Exception('Failed to add appointment');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error updating appointment status: $e');
      throw Exception('Failed to update appointment status');
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error cancelling appointment: $e');
      throw Exception('Failed to cancel appointment');
    }
  }

  // Reschedule appointment
  Future<void> rescheduleAppointment(
      String appointmentId, DateTime newDate, String newTime) async {
    try {
      await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .update({
        'appointmentDate': Timestamp.fromDate(newDate),
        'appointmentTime': newTime,
        'status': 'rescheduled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error rescheduling appointment: $e');
      throw Exception('Failed to reschedule appointment');
    }
  }

  // Delete appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .delete();
    } catch (e) {
      _logger.e('Error deleting appointment: $e');
      throw Exception('Failed to delete appointment');
    }
  }

  // Book appointment
  Future<String> bookAppointment({
    required String userId,
    required String facilityId,
    required String facilityName,
    required String doctorId,
    required String doctorName,
    required DateTime appointmentDateTime,
    required String status,
    String? notes,
  }) async {
    try {
      final appointmentData = {
        'userId': userId,
        'facilityId': facilityId,
        'facilityName': facilityName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'appointmentDate': Timestamp.fromDate(appointmentDateTime),
        'appointmentTime':
            '${appointmentDateTime.hour.toString().padLeft(2, '0')}:${appointmentDateTime.minute.toString().padLeft(2, '0')}',
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'notes': notes ?? 'Appointment for ovarian cyst consultation',
        'reminderEnabled': true,
        'purpose': 'Ovarian cyst consultation',
      };

      return await addAppointment(appointmentData);
    } catch (e) {
      _logger.e('Error booking appointment: $e');
      throw Exception('Failed to book appointment');
    }
  }
}
