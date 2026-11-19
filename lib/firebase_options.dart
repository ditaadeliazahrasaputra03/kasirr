// Opsi Firebase untuk proyek ini.
//
// Diisi dari proyek tugas-b9b98:
// - Android: aplikasi "POS Kasir" (package com.kasir.toko)
// - Web    : aplikasi "POS Kasir Web"
// Setara hasil `flutterfire configure`.

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
      return web;
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
    apiKey: 'AIzaSyAy8jzal2Znt7uHKoqITqqdCkCTU6uklro',
    appId: '1:1078687193802:android:cc590d3ab4084ca8aab233',
    messagingSenderId: '1078687193802',
    projectId: 'tugas-b9b98',
    storageBucket: 'tugas-b9b98.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBVcOa3QXc2U6pJINBMZIGxTRiYJke4yCk',
    appId: '1:1078687193802:web:1ef230ec1eab65e0aab233',
    messagingSenderId: '1078687193802',
    projectId: 'tugas-b9b98',
    authDomain: 'tugas-b9b98.firebaseapp.com',
    storageBucket: 'tugas-b9b98.firebasestorage.app',
  );
}
