import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_0r2JootXCgRBQO-YWEka-tsAR9qGPrE',
    appId: '1:79244036680:android:fbf66803d4143ecfa9667d',
    messagingSenderId: '79244036680',
    projectId: 'distribuidora-paucara',
    storageBucket: 'distribuidora-paucara.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_0r2JootXCgRBQO-YWEka-tsAR9qGPrE',
    appId: '1:79244036680:web:c1d2e3f4g5h6i7j8k9l0',
    messagingSenderId: '79244036680',
    projectId: 'distribuidora-paucara',
    storageBucket: 'distribuidora-paucara.firebasestorage.app',
    authDomain: 'distribuidora-paucara.firebaseapp.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_0r2JootXCgRBQO-YWEka-tsAR9qGPrE',
    appId: '1:79244036680:ios:fbf66803d4143ecfa9667d',
    messagingSenderId: '79244036680',
    projectId: 'distribuidora-paucara',
    storageBucket: 'distribuidora-paucara.firebasestorage.app',
    iosBundleId: 'com.distribuidora.paucara.distribuidora',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA_0r2JootXCgRBQO-YWEka-tsAR9qGPrE',
    appId: '1:79244036680:ios:fbf66803d4143ecfa9667d',
    messagingSenderId: '79244036680',
    projectId: 'distribuidora-paucara',
    storageBucket: 'distribuidora-paucara.firebasestorage.app',
    iosBundleId: 'com.distribuidora.paucara.distribuidora',
  );
}
