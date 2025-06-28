import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Return the web-specific options when running on the web
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  //+++ START: ADD YOUR WEB CONFIGURATION HERE +++
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7fBV11HMuz9waFssw2-gl6HagWYD9Tf0', // Paste your web API key here
    appId: '1:792638518865:web:26947adeddb83d163d2a70', // Paste your web App ID here
    messagingSenderId: '792638518865', // This is usually the same
    projectId: 'gloryfit3', // This is usually the same
    authDomain: 'gloryfit3.firebaseapp.com', // This is usually the same
    storageBucket: 'gloryfit3.appspot.com', // Usually 'your-project-id.appspot.com'
  );
  //+++ END: WEB CONFIGURATION +++

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7fBV11HMuz9waFssw2-gl6HagWYD9Tf0',
    appId: '1:792638518865:android:64140ce8191e5db43d2a70',
    messagingSenderId: '792638518865',
    projectId: 'gloryfit3',
    storageBucket: 'gloryfit3.firebasestorage.app',
    authDomain: 'gloryfit3.firebaseapp.com',
  );
}