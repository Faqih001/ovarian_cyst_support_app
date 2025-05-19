import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/screens/cost_estimation_screen.dart';
import 'package:ovarian_cyst_support_app/services/payment_service.dart';
import 'package:ovarian_cyst_support_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('Firebase initialized successfully');
  } catch (e) {
    logger.e('Failed to initialize Firebase: $e');
    // App will continue without Firebase functionality
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Include only the services needed for cost estimation
        Provider(create: (_) => PaymentService()),
      ],
      child: MaterialApp(
        title: 'OvaCare',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Go directly to the cost estimation screen
        home: const CostEstimationScreen(),
      ),
    );
  }
}
