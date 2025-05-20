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
import 'package:ovarian_cyst_support_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();

  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      name: 'ovarian_cyst_support_app',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase App Check with debug token in debug mode
    await FirebaseAppCheck.instance
        .activate(
      webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
      // Use debug provider for development, switch to playIntegrity for production
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
    )
        .onError((error, stackTrace) {
      logger.e('Error initializing Firebase App Check: $error');
      // Continue app initialization even if App Check fails
      return;
    });

    logger.i('Firebase initialized successfully with App Check');

    final firestoreService = FirestoreService();
    // Don't await void method
    firestoreService.enablePersistence();

    // Initialize hospital service and upload healthcare facilities data
    final hospitalService = HospitalService();

    // Try to upload the CSV file, but don't block app startup if it fails
    hospitalService.ensureCsvInFirebaseStorage().then((success) {
      if (success) {
        logger.i('Healthcare facilities data uploaded successfully');
      } else {
        logger
            .w('Failed to upload healthcare facilities data, using local data');
      }
    }).catchError((error) {
      logger.e('Error handling healthcare facilities data: $error');
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
    // Fix logger.e call to use only one argument
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
