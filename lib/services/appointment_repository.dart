import 'package:ovarian_cyst_support_app/models/appointment.dart';
import 'package:ovarian_cyst_support_app/services/firestore_repository.dart';

/// Repository for working with appointments in Firestore
class AppointmentRepository extends FirestoreRepository<Appointment> {
  AppointmentRepository()
      : super(
          collectionPath: 'appointments',
          fromMap: (map) => Appointment.fromMap(map),
          toMap: (appointment) => appointment.toMap(),
        );

  /// Get upcoming appointments
  Future<List<Appointment>> getUpcomingAppointments() async {
    return await query(
      field: 'dateTime',
      isGreaterThanOrEqualTo: DateTime.now().toIso8601String(),
    );
  }

  /// Get past appointments
  Future<List<Appointment>> getPastAppointments() async {
    return await query(
      field: 'dateTime',
      isLessThan: DateTime.now().toIso8601String(),
    );
  }

  /// Get appointments by status
  Future<List<Appointment>> getAppointmentsByStatus(String status) async {
    return await query(
      field: 'status',
      isEqualTo: status,
    );
  }

  /// Get appointments by doctor
  Future<List<Appointment>> getAppointmentsByDoctor(String doctorId) async {
    return await query(
      field: 'doctorId',
      isEqualTo: doctorId,
    );
  }

  /// Get appointments by facility
  Future<List<Appointment>> getAppointmentsByFacility(
      String facilityName) async {
    return await query(
      field: 'facilityName',
      isEqualTo: facilityName,
    );
  }

  /// Get next appointment
  Future<Appointment?> getNextAppointment() async {
    final now = DateTime.now().toIso8601String();

    final upcomingAppointments = await query(
      field: 'dateTime',
      isGreaterThanOrEqualTo: now,
    );

    if (upcomingAppointments.isEmpty) return null;

    upcomingAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcomingAppointments.first;
  }

  /// Get real-time stream of upcoming appointments
  Stream<List<Appointment>> getUpcomingAppointmentsStream() {
    return queryStream(
      field: 'dateTime',
      isGreaterThanOrEqualTo: DateTime.now().toIso8601String(),
      orderBy: 'dateTime',
      descending: false,
    );
  }
}
