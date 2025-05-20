import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/screens/splash_screen.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/payment_service.dart';
import 'package:ovarian_cyst_support_app/services/firestore_service.dart';
import 'package:ovarian_cyst_support_app/services/hospital_service.dart';
import 'package:ovarian_cyst_support_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();

  try {
    final apps = Firebase.apps;
    if (apps.isEmpty) {
      await Firebase.initializeApp(
        name: 'ovarian_cyst_support_app', // Unique name for this app instance
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i('Firebase initialized successfully');
    } else {
      logger.w('Firebase already initialized');
      Firebase.app('ovarian_cyst_support_app'); // Get the named instance
    }

    final firestoreService = FirestoreService();
    firestoreService.enablePersistence();

    // Initialize hospital service and upload healthcare facilities data to Firebase Storage
    final hospitalService = HospitalService();
    hospitalService.ensureCsvInFirebaseStorage().then((success) {
      if (success) {
        logger.i(
            'Healthcare facilities data uploaded to Firebase Storage successfully');
      } else {
        logger.w(
            'Failed to upload healthcare facilities data to Firebase Storage');
      }
    });

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
          Provider<PaymentService>(create: (_) => PaymentService()),
          Provider<FirestoreService>(create: (_) => firestoreService),
          Provider<HospitalService>(create: (_) => hospitalService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    logger.e('Error during Firebase initialization: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ovarian Cyst',
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
      home: const SplashScreen(), // Start with the splash screen
    );
  }
}
