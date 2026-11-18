import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/menu_service.dart';
import '../../utils/format.dart';
import 'checkout_screen.dart';
import 'order_history_screen.dart';

/// Layar utama Kasir: daftar menu real-time + masukkan ke keranjang.
class KasirHomeScreen extends StatefulWidget {
  const KasirHomeScreen({super.key});

  @override
  State<KasirHomeScreen> createState() => _KasirHomeScreenState();
}

class _KasirHomeScreenState extends State<KasirHomeScreen> {
  String _search = '';
  String _category = 'Semua';

  void _addToCart(MenuItem menu) {
    if (menu.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${menu.name}" sedang habis.')),
      );
      return;
    }
    CartService.instance.add(menu);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${menu.name}" masuk keranjang.'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  List<MenuItem> _filtered(List<MenuItem> menus) {
    return menus.where((MenuItem menu) {
      if (!menu.isActive) {
        return false;
      }
      final bool matchCategory =
          _category == 'Semua' || menu.category == _category;
      final bool matchSearch = _search.isEmpty ||
          menu.name.toLowerCase().contains(_search.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Makanan':
        return Icons.restaurant_outlined;
      case 'Minuman':
        return Icons.local_drink_outlined;
      case 'Snack':
        return Icons.cookie_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = AuthService.instance.currentUser?.name ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Kasir'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Riwayat Pesanan',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Keluar',
            onPressed: () => AuthService.instance.logout(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cari menu...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search_outlined),
              ),
              onChanged: (String value) => setState(() => _search = value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: <Widget>[
                for (final String category in <String>[
                  'Semua',
                  ...menuCategories,
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) =>
                          setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MenuItem>>(
              stream: MenuService.instance.menusStream(),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<MenuItem>> snapshot,
              ) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal memuat menu: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final List<MenuItem> menus = _filtered(snapshot.data!);
                if (menus.isEmpty) {
                  return const Center(
                    child: Text('Belum ada menu aktif dari Admin.'),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: menus.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MenuItem menu = menus[index];
                    final bool outOfStock = menu.stock <= 0;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: outOfStock ? null : () => _addToCart(menu),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                _categoryIcon(menu.category),
                                size: 40,
                                color: outOfStock
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                menu.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatRupiah(menu.price),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    outOfStock
                                        ? 'Habis'
                                        : 'Stok: ${menu.stock}',
                                    style: TextStyle(
                                      color: outOfStock
                                          ? Theme.of(context)
                                              .colorScheme
                                              .error
                                          : null,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: outOfStock
                                        ? null
                                        : () => _addToCart(menu),
                                    tooltip: 'Tambah ke keranjang',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: CartService.instance.itemsNotifier,
            builder: (
              BuildContext context,
              List<CartItem> items,
              Widget? child,
            ) {
              final CartService cart = CartService.instance;
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        cart.isEmpty
                            ? 'Kasir: $name\nKeranjang masih kosong.'
                            : 'Kasir: $name\n${cart.count} item • '
                                '${formatRupiah(cart.total)}',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: cart.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const CheckoutScreen(),
                                ),
                              );
                            },
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Keranjang'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
