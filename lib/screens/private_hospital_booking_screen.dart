import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/screens/kenyan_hospital_booking_screen.dart';
import 'package:ovarian_cyst_support_app/services/hospital_service.dart';

class PrivateHospitalBookingScreen extends StatelessWidget {
  const PrivateHospitalBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simply return KenyanHospitalBookingScreen with private hospital type
    return const KenyanHospitalBookingScreen(
      initialFacilityType: FacilityType.private,
    );
  }
}
