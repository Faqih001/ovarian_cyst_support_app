import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAnd3X_cxcfMj3D9fifDG1ZlCNhnH9llPE',
    appId: '1:327593050838:web:17ffceacfe17179cf6ff77',
    messagingSenderId: '327593050838',
    projectId: 'ovarian-cyst-app',
    authDomain: 'ovarian-cyst-app.firebaseapp.com',
    storageBucket: 'ovarian-cyst-app.firebasestorage.app',
    measurementId: 'G-NVX0YHQ6LE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBIfayrRFib08tf9_lkpLj0c29G6ngncdo',
    appId: '1:327593050838:android:350291cd1dcee241f6ff77',
    messagingSenderId: '327593050838',
    projectId: 'ovarian-cyst-app',
    storageBucket: 'ovarian-cyst-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBIfayrRFib08tf9_lkpLj0c29G6ngncdo',
    appId: '1:327593050838:ios:350291cd1dcee241f6ff77',
    messagingSenderId: '327593050838',
    projectId: 'ovarian-cyst-app',
    storageBucket: 'ovarian-cyst-app.firebasestorage.app',
  );
}
