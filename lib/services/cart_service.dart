import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';

/// Satu baris di keranjang: menu + jumlah yang dibeli.
class CartItem {
  final MenuItem menu;
  final int qty;

  const CartItem({required this.menu, required this.qty});

  int get subtotal => menu.price * qty;

  CartItem copyWith({MenuItem? menu, int? qty}) {
    return CartItem(menu: menu ?? this.menu, qty: qty ?? this.qty);
  }
}

/// Keranjang belanja kasir (di memori, satu transaksi berjalan).
class CartService {
  CartService._();

  static final CartService instance = CartService._();

  final ValueNotifier<List<CartItem>> itemsNotifier =
      ValueNotifier<List<CartItem>>(<CartItem>[]);

  List<CartItem> get items => itemsNotifier.value;

  int get total =>
      items.fold<int>(0, (int sum, CartItem e) => sum + e.subtotal);

  int get count => items.fold<int>(0, (int sum, CartItem e) => sum + e.qty);

  bool get isEmpty => items.isEmpty;

  void add(MenuItem menu) {
    final List<CartItem> next = List<CartItem>.of(items);
    final int index = next.indexWhere((CartItem e) => e.menu.id == menu.id);
    if (index >= 0) {
      final CartItem current = next[index];
      if (current.qty >= menu.stock && menu.stock > 0) {
        return;
      }
      next[index] = current.copyWith(qty: current.qty + 1);
    } else {
      next.add(CartItem(menu: menu, qty: 1));
    }
    itemsNotifier.value = next;
  }

  void decrease(String menuId) {
    final List<CartItem> next = List<CartItem>.of(items);
    final int index = next.indexWhere((CartItem e) => e.menu.id == menuId);
    if (index < 0) {
      return;
    }
    final CartItem current = next[index];
    if (current.qty <= 1) {
      next.removeAt(index);
    } else {
      next[index] = current.copyWith(qty: current.qty - 1);
    }
    itemsNotifier.value = next;
  }

  void remove(String menuId) {
    itemsNotifier.value =
        items.where((CartItem e) => e.menu.id != menuId).toList();
  }

  void clear() {
    itemsNotifier.value = <CartItem>[];
  }
}
