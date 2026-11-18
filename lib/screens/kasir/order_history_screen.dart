import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/format.dart';
import 'receipt_screen.dart';

/// Riwayat pesanan/transaksi, terbaru di atas.
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  Color _statusColor(String status, BuildContext context) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'failed':
      case 'cancelled':
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService.instance.ordersStream(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<OrderModel>> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat riwayat: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<OrderModel> orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('Belum ada transaksi.'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (BuildContext context, int index) {
              final OrderModel order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: ListTile(
                  title: Text(
                    '${formatRupiah(order.total)}'
                    ' • ${order.items.length} jenis item',
                  ),
                  subtitle: Text(
                    '${formatDateTime(order.createdAt)}'
                    ' • ${order.cashierName.isEmpty ? order.cashierEmail : order.cashierName}'
                    ' • ${order.paymentMethod}',
                  ),
                  trailing: Chip(
                    label: Text(order.statusLabel),
                    backgroundColor:
                        _statusColor(order.paymentStatus, context)
                            .withValues(alpha: 0.15),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReceiptScreen(order: order),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
