import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/app_user.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/miomipay_service.dart';
import '../../services/order_service.dart';
import '../../utils/format.dart';
import 'payment_screen.dart';

/// Layar keranjang + checkout. Kasir mengatur jumlah, lalu membuat
/// tagihan pembayaran lewat MiomiPay.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _customerController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    final CartService cart = CartService.instance;
    if (cart.isEmpty) {
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final String orderRef = 'POS-${DateTime.now().millisecondsSinceEpoch}';
      final List<OrderItem> items = cart.items
          .map(
            (CartItem e) => OrderItem(
              menuId: e.menu.id,
              name: e.menu.name,
              price: e.menu.price,
              qty: e.qty,
            ),
          )
          .toList();

      // 1. Buat tagihan di MiomiPay (atau simulasi).
      final AppUser? cashier = AuthService.instance.currentUser;
      final MiomiPayPayment payment =
          await MiomiPayService.instance.createPayment(
        orderRef: orderRef,
        amount: cart.total,
        items: items,
        customerName: _customerController.text.trim().isEmpty
            ? null
            : _customerController.text.trim(),
        customerEmail: cashier?.email,
      );

      // 2. Simpan pesanan ke Firestore (status: menunggu pembayaran).
      final OrderModel order = await OrderService.instance.createOrder(
        OrderModel(
          id: '',
          items: items,
          total: cart.total,
          paymentMethod: 'MiomiPay',
          paymentId: payment.paymentId,
          paymentStatus: 'pending',
          cashierEmail: cashier?.email ?? '',
          cashierName: cashier?.name ?? '',
          customerName: _customerController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PaymentScreen(order: order, payment: payment),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat tagihan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang & Checkout')),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartService.instance.itemsNotifier,
        builder: (
          BuildContext context,
          List<CartItem> items,
          Widget? child,
        ) {
          final CartService cart = CartService.instance;
          if (items.isEmpty) {
            return const Center(
              child: Text('Keranjang kosong. Kembali dan pilih menu dulu.'),
            );
          }
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    final CartItem item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(item.menu.name),
                        subtitle: Text(
                          '${formatRupiah(item.menu.price)} x ${item.qty}'
                          ' = ${formatRupiah(item.subtotal)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () =>
                                  cart.decrease(item.menu.id),
                            ),
                            Text('${item.qty}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => cart.add(item.menu),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => cart.remove(item.menu.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _customerController,
                  decoration: const InputDecoration(
                    labelText: 'Nama pelanggan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: const Text('MiomiPay'),
                        subtitle: Text(
                          BackendConfig.isConfigured
                              ? 'Backend Laravel + MiomiPay'
                              : AppConfig.isDemoMode ||
                                      !MiomiPayConfig.isConfigured
                                  ? 'Mode simulasi - tidak ada uang sungguhan'
                                  : 'Payment gateway MiomiPay',
                        ),
                        trailing: const Icon(Icons.check_circle),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Total Bayar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formatRupiah(cart.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isProcessing ? null : _checkout,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Buat Tagihan & Bayar via MiomiPay'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
