import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:ovarian_cyst_support_app/firebase_options.dart';

class WebInitialization {
  static Future<void> initializeWeb() async {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }
}
