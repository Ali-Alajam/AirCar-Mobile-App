
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB4SRUDkAauOWR9dgvJSHz12F3VGcTWY9w',
    appId: '1:318057519031:web:92445ee32f0212f5ebba32',
    messagingSenderId: '318057519031',
    projectId: 'air--car',
    authDomain: 'air--car.firebaseapp.com',
    storageBucket: 'air--car.firebasestorage.app',
    measurementId: 'G-W5KPDKG921',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBOH47kFC6B_mc-8Yi8kyYn8TY3bXQljVg',
    appId: '1:318057519031:android:890ca4f611e123f6ebba32',
    messagingSenderId: '318057519031',
    projectId: 'air--car',
    storageBucket: 'air--car.firebasestorage.app',
  );
}
