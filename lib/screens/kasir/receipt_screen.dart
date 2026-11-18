import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../utils/format.dart';

/// Struk/bukti transaksi setelah pembayaran selesai,
/// atau detail pesanan dari riwayat.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({
    super.key,
    required this.order,
    this.isNewTransaction = false,
  });

  final OrderModel order;

  /// True kalau layar ini dibuka langsung setelah pembayaran berhasil,
  /// sehingga tombolnya kembali ke layar kasir untuk transaksi baru.
  final bool isNewTransaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Transaksi'),
        automaticallyImplyLeading: !isNewTransaction,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    const Text(
                      'POS SEDERHANA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('ID Pesanan: ${order.id}'),
                    Text('Tanggal: ${formatDateTime(order.createdAt)}'),
                    Text(
                      'Kasir: ${order.cashierName.isEmpty ? order.cashierEmail : order.cashierName}',
                    ),
                    if (order.customerName.isNotEmpty)
                      Text('Pelanggan: ${order.customerName}'),
                    const Divider(height: 24),
                    for (final OrderItem item in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text('${item.name} x${item.qty}'),
                            ),
                            Text(formatRupiah(item.subtotal)),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'TOTAL',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formatRupiah(order.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Pembayaran: ${order.paymentMethod}'),
                    Text('ID Tagihan: ${order.paymentId}'),
                    Text(
                      'Status: ${order.statusLabel}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (isNewTransaction) {
                  Navigator.of(context).popUntil(
                    (Route<dynamic> route) => route.isFirst,
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                isNewTransaction ? 'Transaksi Baru' : 'Kembali',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
