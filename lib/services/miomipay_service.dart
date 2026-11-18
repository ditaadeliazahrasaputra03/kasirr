import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/order_model.dart';

/// Hasil pembuatan tagihan pembayaran.
class MiomiPayPayment {
  /// Reference tagihan (mis. MP-INV-...) atau ID simulasi (SIM-).
  final String paymentId;

  /// URL halaman checkout hosted MiomiPay (checkout_url).
  /// Kosong pada mode simulasi.
  final String paymentUrl;

  /// Isi QRIS (qr_string) dari MiomiPay, atau kode simulasi.
  final String qrPayload;

  /// URL gambar QRIS (qr_image_url) dari MiomiPay.
  /// Kosong pada mode simulasi.
  final String qrImageUrl;

  /// Status awal dari gateway, mis. 'PENDING'.
  final String status;

  final bool isSimulation;

  const MiomiPayPayment({
    required this.paymentId,
    required this.paymentUrl,
    required this.qrPayload,
    this.qrImageUrl = '',
    required this.status,
    required this.isSimulation,
  });
}

/// Integrasi pembayaran: aplikasi -> backend Laravel -> API MiomiPay.
///
/// Jalur utama memakai [BackendConfig] (endpoint backend:
/// POST /api/payments, GET /api/payments/{reference}/status). Backend
/// Laravel-lah yang memegang API key MiomiPay dan memanggil
/// https://pg.miomidev.com/api/v1 sesuai dokumentasi resmi
/// (terverifikasi 2026-11-14, tagihan sandbox sungguhan).
///
/// Fallback: kalau backend dimatikan, service ini memanggil API
/// MiomiPay langsung bila [MiomiPayConfig] terisi, atau memakai
/// simulasi di dalam aplikasi bila tidak ada konfigurasi sama sekali.
class MiomiPayService {
  MiomiPayService._();

  static final MiomiPayService instance = MiomiPayService._();

  /// Buat tagihan pembayaran untuk satu pesanan.
  Future<MiomiPayPayment> createPayment({
    required String orderRef,
    required int amount,
    required List<OrderItem> items,
    String? customerName,
    String? customerEmail,
  }) async {
    if (BackendConfig.isConfigured) {
      return _createViaBackend(
        orderRef: orderRef,
        amount: amount,
        items: items,
        customerName: customerName,
        customerEmail: customerEmail,
      );
    }

    if (!MiomiPayConfig.isConfigured) {
      // Mode simulasi: tidak ada panggilan jaringan.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final String paymentId =
          'SIM-${DateTime.now().millisecondsSinceEpoch}';
      return MiomiPayPayment(
        paymentId: paymentId,
        paymentUrl: '',
        qrPayload: 'MIOMIPAY-SIMULASI|$paymentId|$orderRef|$amount',
        status: 'PENDING',
        isSimulation: true,
      );
    }

    return _createDirect(
      orderRef: orderRef,
      amount: amount,
      items: items,
      customerName: customerName,
      customerEmail: customerEmail,
    );
  }

  Future<MiomiPayPayment> _createViaBackend({
    required String orderRef,
    required int amount,
    required List<OrderItem> items,
    String? customerName,
    String? customerEmail,
  }) async {
    final Uri uri = Uri.parse('${BackendConfig.baseUrl}/payments');
    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'external_id': orderRef,
              'amount': amount,
              if (customerName != null && customerName.isNotEmpty)
                'customer_name': customerName,
              if (customerEmail != null && customerEmail.isNotEmpty)
                'customer_email': customerEmail,
              'description': _description(items),
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on Exception catch (e) {
      throw Exception(
        'Backend Laravel tidak terjangkau di ${BackendConfig.baseUrl} '
        '(jalankan `php artisan serve --host=0.0.0.0 --port=8001` di '
        'laptop DITA, pastikan HP satu jaringan Tailscale). Error: $e',
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Backend menolak tagihan (HTTP ${response.statusCode}): '
        '${response.body}',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic> data =
        (body['data'] as Map<String, dynamic>?) ?? body;
    return _paymentFromData(data);
  }

  Future<MiomiPayPayment> _createDirect({
    required String orderRef,
    required int amount,
    required List<OrderItem> items,
    String? customerName,
    String? customerEmail,
  }) async {
    final Uri uri = Uri.parse('${MiomiPayConfig.baseUrl}/payment/create');
    final http.Response response = await http
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${MiomiPayConfig.apiKey}',
          },
          body: jsonEncode(<String, dynamic>{
            'external_id': orderRef,
            'amount': amount,
            'customer_name': customerName ?? 'Pelanggan POS',
            if (customerEmail != null && customerEmail.isNotEmpty)
              'customer_email': customerEmail,
            'description': _description(items),
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'MiomiPay menolak tagihan (HTTP ${response.statusCode}): '
        '${response.body}',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic> data =
        (body['data'] as Map<String, dynamic>?) ?? body;
    return _paymentFromData(data);
  }

  MiomiPayPayment _paymentFromData(Map<String, dynamic> data) {
    final String reference = (data['reference'] ?? '').toString();
    if (reference.isEmpty) {
      throw Exception('Respons tidak berisi reference tagihan: $data');
    }
    return MiomiPayPayment(
      paymentId: reference,
      paymentUrl: (data['checkout_url'] ?? '').toString(),
      qrPayload: (data['qr_string'] ?? '').toString(),
      qrImageUrl: (data['qr_image_url'] ?? '').toString(),
      status: (data['status'] ?? 'PENDING').toString(),
      isSimulation: false,
    );
  }

  String _description(List<OrderItem> items) {
    final String joined =
        items.map((OrderItem e) => '${e.name} x${e.qty}').join(', ');
    return joined.isEmpty ? 'Pembayaran POS' : 'Pembayaran POS: $joined';
  }

  /// Cek status tagihan. Mengembalikan status mentah: 'PENDING',
  /// 'PAID', atau 'EXPIRED'.
  Future<String> checkStatus(String paymentId) async {
    if (BackendConfig.isConfigured) {
      final Uri uri = Uri.parse(
        '${BackendConfig.baseUrl}/payments/$paymentId/status',
      );
      late final http.Response response;
      try {
        response = await http.get(
          uri,
          headers: <String, String>{'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 30));
      } on Exception catch (e) {
        throw Exception(
          'Backend Laravel tidak terjangkau di ${BackendConfig.baseUrl}. '
          'Error: $e',
        );
      }
      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengecek status lewat backend '
          '(HTTP ${response.statusCode}).',
        );
      }
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> data =
          (body['data'] as Map<String, dynamic>?) ?? body;
      return (data['status'] ?? 'PENDING').toString();
    }

    if (!MiomiPayConfig.isConfigured) {
      return 'PENDING';
    }
    final Uri uri = Uri.parse(
      '${MiomiPayConfig.baseUrl}/payment/$paymentId/status',
    );
    final http.Response response = await http.get(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer ${MiomiPayConfig.apiKey}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengecek status MiomiPay (HTTP ${response.statusCode}).',
      );
    }
    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic> data =
        (body['data'] as Map<String, dynamic>?) ?? body;
    return (data['status'] ?? 'PENDING').toString();
  }

  /// True kalau status mentah gateway berarti "sudah dibayar".
  static bool isPaidStatus(String rawStatus) {
    final String status = rawStatus.toUpperCase();
    return status == 'PAID' ||
        status == 'SUCCESS' ||
        status == 'SUCCESSFUL' ||
        status == 'SETTLEMENT' ||
        status == 'COMPLETED';
  }
}
