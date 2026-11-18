import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order_model.dart';
import '../../services/cart_service.dart';
import '../../services/menu_service.dart';
import '../../services/miomipay_service.dart';
import '../../services/order_service.dart';
import '../../utils/format.dart';
import 'receipt_screen.dart';

/// Layar pembayaran MiomiPay.
///
/// Mode simulasi: tampilkan kode/QR simulasi + tombol konfirmasi bayar
/// (untuk demo tugas). Mode API sungguhan: buka halaman pembayaran
/// MiomiPay di browser, lalu cek status tagihannya.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.order,
    required this.payment,
  });

  final OrderModel order;
  final MiomiPayPayment payment;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isWorking = false;

  Future<void> _finishAsPaid() async {
    setState(() => _isWorking = true);
    try {
      await OrderService.instance.updatePaymentStatus(
        widget.order.id,
        'paid',
      );
      final Map<String, int> sold = <String, int>{};
      for (final OrderItem item in widget.order.items) {
        sold[item.menuId] = (sold[item.menuId] ?? 0) + item.qty;
      }
      await MenuService.instance.decreaseStock(sold);
      CartService.instance.clear();
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptScreen(
            order: widget.order.copyWith(paymentStatus: 'paid'),
            isNewTransaction: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyelesaikan pembayaran: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _cancelPayment() async {
    setState(() => _isWorking = true);
    try {
      await OrderService.instance.updatePaymentStatus(
        widget.order.id,
        'cancelled',
      );
    } catch (_) {
      // Pembatalan tetap dilanjutkan walau penyimpanan status gagal.
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _openPaymentPage() async {
    final Uri uri = Uri.parse(widget.payment.paymentUrl);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa membuka halaman pembayaran.'),
        ),
      );
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _isWorking = true);
    try {
      final String status = await MiomiPayService.instance.checkStatus(
        widget.payment.paymentId,
      );
      if (!mounted) {
        return;
      }
      if (MiomiPayService.isPaidStatus(status)) {
        await _finishAsPaid();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Belum dibayar (status: $status).')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengecek status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool simulation = widget.payment.isSimulation;
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran MiomiPay')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    const Text('Total yang harus dibayar'),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(widget.order.total),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('ID Tagihan: ${widget.payment.paymentId}'),
                    Text('ID Pesanan: ${widget.order.id}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (simulation) ...<Widget>[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.qr_code_2_outlined, size: 96),
                    const SizedBox(height: 8),
                    const Text(
                      'QRIS Simulasi MiomiPay',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.payment.qrPayload,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ini simulasi untuk keperluan demo tugas: tidak ada uang '
                'sungguhan yang berpindah. Ketuk "Saya Sudah Bayar" untuk '
                'menyelesaikan transaksi seperti setelah pelanggan membayar.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isWorking ? null : _finishAsPaid,
                child: const Text('Saya Sudah Bayar (Simulasi)'),
              ),
            ] else ...<Widget>[
              if (widget.payment.qrImageUrl.isNotEmpty) ...<Widget>[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Image.network(
                    widget.payment.qrImageUrl,
                    height: 220,
                    errorBuilder: (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return const Column(
                        children: <Widget>[
                          Icon(Icons.qr_code_2_outlined, size: 96),
                          Text('QRIS tidak bisa dimuat.'),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pelanggan memindai QRIS di atas dengan aplikasi '
                  'pembayaran apa pun (GoPay, OVO, Dana, m-banking).',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Atau buka halaman pembayaran MiomiPay, selesaikan '
                'pembayaran di sana, lalu kembali ke aplikasi dan cek '
                'statusnya.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isWorking ? null : _openPaymentPage,
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('Buka Halaman Pembayaran MiomiPay'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isWorking ? null : _checkStatus,
                child: const Text('Cek Status Pembayaran'),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isWorking ? null : _cancelPayment,
              child: const Text('Batalkan Pembayaran'),
            ),
          ],
        ),
      ),
    );
  }
}
