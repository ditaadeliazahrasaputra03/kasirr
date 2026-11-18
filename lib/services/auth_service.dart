import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/app_user.dart';

/// Akun demo untuk Mode Demo (Firebase belum dikonfigurasi).
class _DemoAccount {
  final String password;
  final AppUser user;

  const _DemoAccount({required this.password, required this.user});
}

/// Autentikasi + pembaca role.
///
/// Mode Firebase: login memakai Firebase Authentication (email/password),
/// lalu role dibaca dari dokumen Firestore `users/{uid}`.
/// Mode Demo: dua akun bawaan di bawah, tanpa jaringan.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ValueNotifier<AppUser?> currentUserNotifier =
      ValueNotifier<AppUser?>(null);

  AppUser? get currentUser => currentUserNotifier.value;

  final Map<String, _DemoAccount> _demoAccounts = <String, _DemoAccount>{
    'admin@pos.demo': const _DemoAccount(
      password: '123456',
      user: AppUser(
        uid: 'demo-admin',
        email: 'admin@pos.demo',
        name: 'Admin Demo',
        role: 'admin',
      ),
    ),
    'kasir@pos.demo': const _DemoAccount(
      password: '123456',
      user: AppUser(
        uid: 'demo-kasir',
        email: 'kasir@pos.demo',
        name: 'Kasir Demo',
        role: 'kasir',
      ),
    ),
  };

  /// Dipanggil sekali saat aplikasi mulai (mode Firebase saja) supaya
  /// sesi login yang masih berlaku langsung masuk tanpa login ulang.
  Future<void> restoreSession() async {
    if (AppConfig.isDemoMode) {
      return;
    }
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return;
    }
    currentUserNotifier.value = await _readUserDoc(firebaseUser);
  }

  Future<AppUser> login(String email, String password) async {
    final String cleanEmail = email.trim();
    if (AppConfig.isDemoMode) {
      final _DemoAccount? account = _demoAccounts[cleanEmail];
      if (account == null || account.password != password) {
        throw Exception('Email atau kata sandi salah (akun demo).');
      }
      currentUserNotifier.value = account.user;
      return account.user;
    }

    try {
      final UserCredential credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Login gagal, pengguna tidak ditemukan.');
      }
      final AppUser user = await _readUserDoc(firebaseUser);
      currentUserNotifier.value = user;
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseAuthMessage(e.code));
    }
  }

  /// Mendaftarkan akun baru beserta rolenya.
  ///
  /// Mode Firebase: akun dibuat di Authentication, lalu dokumen
  /// `users/{uid}` dibuat di Firestore. Mode Demo: akun ditambah ke
  /// daftar akun demo selama aplikasi berjalan.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final String cleanEmail = email.trim();
    if (AppConfig.isDemoMode) {
      if (_demoAccounts.containsKey(cleanEmail)) {
        throw Exception('Email sudah terdaftar (akun demo).');
      }
      final AppUser user = AppUser(
        uid: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        email: cleanEmail,
        name: name.trim(),
        role: role,
      );
      _demoAccounts[cleanEmail] =
          _DemoAccount(password: password, user: user);
      currentUserNotifier.value = user;
      return user;
    }

    try {
      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Pendaftaran gagal, pengguna tidak ditemukan.');
      }
      final AppUser user = AppUser(
        uid: firebaseUser.uid,
        email: cleanEmail,
        name: name.trim(),
        role: role,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap());
      currentUserNotifier.value = user;
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseAuthMessage(e.code));
    }
  }

  Future<void> logout() async {
    if (!AppConfig.isDemoMode) {
      await FirebaseAuth.instance.signOut();
    }
    currentUserNotifier.value = null;
  }

  Future<AppUser> _readUserDoc(User firebaseUser) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
    if (doc.exists) {
      return AppUser.fromMap(firebaseUser.uid, doc.data()!);
    }
    // Akun dibuat langsung dari Firebase Console tanpa dokumen role:
    // perlakukan sebagai kasir supaya tetap bisa masuk.
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      role: 'kasir',
    );
  }

  String _firebaseAuthMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar, silakan login.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
      default:
        return 'Terjadi kesalahan saat autentikasi ($code).';
    }
  }
}
