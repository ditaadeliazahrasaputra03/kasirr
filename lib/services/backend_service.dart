import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Hasil pengecekan koneksi ke backend Laravel.
class BackendHealth {
  final bool online;
  final String message;

  const BackendHealth({required this.online, required this.message});
}

/// Pemeriksaan koneksi ke backend Laravel.
///
/// Dipakai di layar login supaya pengguna tahu apakah backend (XAMPP +
/// Laravel) sudah bisa dijangkau sebelum melakukan checkout MiomiPay.
class BackendService {
  BackendService._();

  static final BackendService instance = BackendService._();

  Future<BackendHealth> checkHealth() async {
    if (!BackendConfig.isConfigured) {
      return const BackendHealth(
        online: false,
        message: 'Backend belum dikonfigurasi (BackendConfig.baseUrl kosong).',
      );
    }

    try {
      final http.Response response = await http.get(
        BackendConfig.healthUri,
        headers: <String, String>{'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return BackendHealth(
          online: false,
          message: 'Backend membalas HTTP ${response.statusCode}.',
        );
      }

      String message = 'Backend terhubung.';
      try {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String? serverMessage = body['message'] as String?;
        if (serverMessage != null && serverMessage.isNotEmpty) {
          message = serverMessage;
        }
      } catch (_) {
        // Badan respons bukan JSON: status 200 sudah cukup.
      }
      return BackendHealth(online: true, message: message);
    } catch (e) {
      return BackendHealth(
        online: false,
        message: 'Tidak bisa menghubungi backend di '
            '${BackendConfig.baseUrl}. Pastikan Apache/XAMPP berjalan dan '
            'HP berada di Wi-Fi yang sama.',
      );
    }
  }
}
