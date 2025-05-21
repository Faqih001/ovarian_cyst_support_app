import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/screens/splash_screen.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/payment_service.dart';
import 'package:ovarian_cyst_support_app/services/firestore_service.dart';
import 'package:ovarian_cyst_support_app/services/hospital_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ovarian_cyst_support_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();

  try {
    // Initialize Firebase with retry mechanism
    await _initializeFirebaseWithRetry(logger);

    final firestoreService = FirestoreService();
    firestoreService.enablePersistence();

    final hospitalService = HospitalService();

    // Initialize services in parallel
    await Future.wait([
      _initializeAppCheck(logger),
      _setupHospitalData(hospitalService, logger),
    ]).catchError((error) {
      logger.e('Error during parallel initialization: $error');
      // Return empty list to satisfy Future<List<void>> return type
      return <void>[];
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
    logger.e('Error during app initialization: $e');
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

Future<void> _initializeFirebaseWithRetry(Logger logger,
    {int maxAttempts = 3}) async {
  int attempts = 0;
  while (attempts < maxAttempts) {
    try {
      await Firebase.initializeApp(
        name: 'ovarian_cyst_support_app',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i('Firebase initialized successfully');
      return;
    } catch (e) {
      attempts++;
      logger.w('Firebase initialization attempt $attempts failed: $e');
      if (attempts == maxAttempts) rethrow;
      await Future.delayed(Duration(seconds: 1));
    }
  }
}

Future<void> _initializeAppCheck(Logger logger) async {
  try {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
    );
    logger.i('Firebase App Check initialized successfully');
  } catch (e) {
    logger.w('Firebase App Check initialization failed: $e');
    // Continue without App Check in development
  }
}

Future<void> _setupHospitalData(
    HospitalService hospitalService, Logger logger) async {
  try {
    // Set longer timeouts for Firebase Storage operations
    FirebaseStorage.instance.setMaxUploadRetryTime(const Duration(seconds: 60));
    FirebaseStorage.instance
        .setMaxDownloadRetryTime(const Duration(seconds: 60));

    final success = await hospitalService.ensureCsvInFirebaseStorage();
    if (success) {
      logger.i('Healthcare facilities data processed successfully');
    } else {
      logger.w('Using local healthcare facilities data');
    }
  } catch (e) {
    logger.e('Error setting up hospital data: $e');
    // Allow app to continue with local data
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
