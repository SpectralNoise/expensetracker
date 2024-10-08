// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyAWf4792g8JkKCDyBMjbohjDtQLO1ESd94',
    appId: '1:90043983853:web:dc34ad92875f9ae1ed29e4',
    messagingSenderId: '90043983853',
    projectId: 'expensetraker-d2cad',
    authDomain: 'expensetraker-d2cad.firebaseapp.com',
    storageBucket: 'expensetraker-d2cad.appspot.com',
    measurementId: 'G-2TBCW2PH12',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAzfYGZaVsWhSzBGX7u1Emv6uWyHZhxmho',
    appId: '1:90043983853:android:1fce3c13aaeadc5aed29e4',
    messagingSenderId: '90043983853',
    projectId: 'expensetraker-d2cad',
    storageBucket: 'expensetraker-d2cad.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBIQWfpFIfkIbfvwsXN_pqUB2Rxr6gcNKU',
    appId: '1:90043983853:ios:e8d1d604b817d948ed29e4',
    messagingSenderId: '90043983853',
    projectId: 'expensetraker-d2cad',
    storageBucket: 'expensetraker-d2cad.appspot.com',
    iosBundleId: 'com.example.expenseTracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBIQWfpFIfkIbfvwsXN_pqUB2Rxr6gcNKU',
    appId: '1:90043983853:ios:e8d1d604b817d948ed29e4',
    messagingSenderId: '90043983853',
    projectId: 'expensetraker-d2cad',
    storageBucket: 'expensetraker-d2cad.appspot.com',
    iosBundleId: 'com.example.expenseTracker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAWf4792g8JkKCDyBMjbohjDtQLO1ESd94',
    appId: '1:90043983853:web:df3eb6a2e6b609aeed29e4',
    messagingSenderId: '90043983853',
    projectId: 'expensetraker-d2cad',
    authDomain: 'expensetraker-d2cad.firebaseapp.com',
    storageBucket: 'expensetraker-d2cad.appspot.com',
    measurementId: 'G-KJY5T5FTXZ',
  );

}