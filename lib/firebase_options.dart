import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDx7csijVC4rnw-SPr2HZS2vX4cQpJKEAI',
    appId: '1:191635978435:web:085a9b0d701b55e6a4ca76',
    messagingSenderId: '191635978435',
    projectId: 'docmac-88a0d',
    authDomain: 'docmac-88a0d.firebaseapp.com',
    storageBucket: 'docmac-88a0d.firebasestorage.app',
    measurementId: 'G-GK467GFT2Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBahKymWyOl4qHgIHVP2EGgtixuajrmcfw',
    appId: '1:191635978435:android:dd5d82d4f7684865a4ca76',
    messagingSenderId: '191635978435',
    projectId: 'docmac-88a0d',
    storageBucket: 'docmac-88a0d.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB4_dbAGg70YLAdwP8e2tDiB5frQyVJEXc',
    appId: '1:191635978435:ios:90e565b4bc6bd06ea4ca76',
    messagingSenderId: '191635978435',
    projectId: 'docmac-88a0d',
    storageBucket: 'docmac-88a0d.firebasestorage.app',
    iosBundleId: 'com.jack.docmac',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB4_dbAGg70YLAdwP8e2tDiB5frQyVJEXc',
    appId: '1:191635978435:ios:ccb8795219cc0c06a4ca76',
    messagingSenderId: '191635978435',
    projectId: 'docmac-88a0d',
    storageBucket: 'docmac-88a0d.firebasestorage.app',
    iosBundleId: 'com.jack.docmacApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDx7csijVC4rnw-SPr2HZS2vX4cQpJKEAI',
    appId: '1:191635978435:web:6600656d1d253f51a4ca76',
    messagingSenderId: '191635978435',
    projectId: 'docmac-88a0d',
    authDomain: 'docmac-88a0d.firebaseapp.com',
    storageBucket: 'docmac-88a0d.firebasestorage.app',
    measurementId: 'G-JE52YQWY1F',
  );
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_LINUX_API_KEY',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
  );
}
