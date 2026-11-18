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

/// Backend Laravel POS (E:\Tugas\pos-backend di laptop DITA).
class BackendConfig {
  /// Base URL API backend, tanpa garis miring di akhir.
  /// IP Tailscale DITA supaya HP yang satu tailnet bisa menjangkaunya.
  /// Kalau backend dijalankan di mesin lain, sesuaikan alamat ini.
  static const String baseUrl = 'http://100.94.209.7:8001/api';

  /// true = checkout memakai backend Laravel.
  /// false = fallback ke jalur langsung MiomiPay / simulasi.
  static const bool useBackend = true;

  static bool get isConfigured => useBackend && baseUrl.isNotEmpty;
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
