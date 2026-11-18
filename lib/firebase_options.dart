// Opsi Firebase untuk proyek ini.
//
// Diisi dari google-services.json proyek kasir-79d26 (setara hasil
// `flutterfire configure`). File ini hanya ada di salinan laptop DITA;
// salinan kode di tempat lain tetap memakai placeholder.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// True kalau nilai di bawah sudah diganti dengan nilai proyek asli.
  static bool get isConfigured =>
      android.apiKey != 'ISI_API_KEY_FIREBASE' &&
      android.projectId != 'ISI_PROJECT_ID_FIREBASE';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions belum dikonfigurasi untuk web - '
        'jalankan flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform ini - '
          'jalankan flutterfire configure.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRlCbqGApg32HohG8LTGkf6lXAmAFyXeg',
    appId: '1:640643704828:android:b00e35483ade647079f479',
    messagingSenderId: '640643704828',
    projectId: 'kasir-79d26',
    storageBucket: 'kasir-79d26.firebasestorage.app',
  );
}
