import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'firebase_options.dart';
import 'models/app_user.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/kasir/kasir_home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase hanya diinisialisasi kalau firebase_options.dart sudah
  // diisi nilai proyek asli. Kalau belum, aplikasi berjalan dalam
  // Mode Demo (data contoh di memori) supaya tetap bisa dicoba.
  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppConfig.firebaseReady = true;
      await AuthService.instance.restoreSession();
    } catch (_) {
      // Gagal init (mis. config salah / tidak ada jaringan saat mulai):
      // tetap jalan dalam Mode Demo, jangan crash di splash.
      AppConfig.firebaseReady = false;
    }
  }

  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Sederhana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Mengarahkan pengguna berdasarkan status login dan rolenya:
/// belum login -> Login, admin -> Kelola Menu, kasir -> POS.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: AuthService.instance.currentUserNotifier,
      builder: (BuildContext context, AppUser? user, Widget? child) {
        if (user == null) {
          return const LoginScreen();
        }
        if (user.isAdmin) {
          return const AdminHomeScreen();
        }
        return const KasirHomeScreen();
      },
    );
  }
}
