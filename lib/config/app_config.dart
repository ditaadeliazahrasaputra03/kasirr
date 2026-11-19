// Konfigurasi aplikasi.
//
// Firebase: isi lewat lib/firebase_options.dart (hasil `flutterfire
// configure`). Selama file itu masih berisi placeholder, aplikasi berjalan
// dalam Mode Demo (data di memori) supaya semua layar tetap bisa dicoba.
//
// Pembayaran: aplikasi memanggil backend Laravel (BackendConfig), dan
// backend-lah yang memanggil API MiomiPay. API key MiomiPay tinggal di
// file .env backend saja — TIDAK ADA key di dalam aplikasi ini.

class AppConfig {
  /// Diisi di main() setelah Firebase berhasil diinisialisasi.
  static bool firebaseReady = false;

  /// True kalau Firebase belum terkonfigurasi / gagal init.
  static bool get isDemoMode => !firebaseReady;
}

/// Backend Laravel POS (folder `C:\xampp\htdocs\kasirr_backend`).
///
/// Backend dijalankan lewat XAMPP/Apache, jadi alamatnya mengikuti folder
/// di htdocs: `http://<IP-komputer>/kasirr_backend/public/api`.
///
/// Bisa dioverride tanpa mengubah kode, misalnya saat IP komputer berubah
/// atau memakai emulator Android:
///
/// ```powershell
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2/kasirr_backend/public/api
/// flutter build apk --dart-define=API_BASE_URL=http://192.168.1.10/kasirr_backend/public/api
/// ```
class BackendConfig {
  /// Base URL API backend, tanpa garis miring di akhir.
  ///
  /// Default memakai IP LAN komputer ini (192.168.0.5) supaya HP yang
  /// tersambung ke Wi-Fi yang sama bisa langsung mengakses backend.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.5/kasirr_backend/public/api',
  );

  /// true = checkout memakai backend Laravel.
  /// false = fallback ke jalur langsung MiomiPay / simulasi.
  static const bool useBackend = true;

  static bool get isConfigured => useBackend && baseUrl.isNotEmpty;

  /// Endpoint cek kesehatan backend: GET {baseUrl}/health.
  static Uri get healthUri => Uri.parse('$baseUrl/health');
}

/// Jalur langsung ke API MiomiPay (fallback, hanya dipakai kalau
/// [BackendConfig.useBackend] dimatikan).
///
/// Dokumentasi resmi: https://pg.miomidev.com/docs (terverifikasi
/// 2026-11-14). JANGAN menaruh key LIVE (MP-LIVE-) di sini; jalur
/// utama tetap lewat backend Laravel.
class MiomiPayConfig {
  /// Base URL API MiomiPay sesuai dokumentasi resmi.
  static const String baseUrl = 'https://pg.miomidev.com/api/v1';

  /// API key SANDBOX dari dashboard MiomiPay (awalan MP-SB-).
  /// Placeholder = jalur langsung tidak aktif, checkout memakai
  /// simulasi. JANGAN commit key asli ke repo publik.
  static const String apiKey = 'ISI_API_KEY_SANDBOX_MIOMIPAY';

  /// true = checkout memakai simulasi di dalam aplikasi.
  /// false = checkout memanggil API MiomiPay sungguhan (butuh apiKey).
  static const bool useSimulation = false;

  static bool get isConfigured =>
      !useSimulation &&
      baseUrl.isNotEmpty &&
      apiKey.isNotEmpty &&
      apiKey != 'ISI_API_KEY_SANDBOX_MIOMIPAY';
}
