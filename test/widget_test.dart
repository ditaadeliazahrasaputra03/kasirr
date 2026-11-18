import 'package:flutter_test/flutter_test.dart';
import 'package:pos_kasir/models/menu_item.dart';
import 'package:pos_kasir/services/cart_service.dart';
import 'package:pos_kasir/utils/format.dart';

void main() {
  test('formatRupiah memakai pemisah ribuan titik', () {
    expect(formatRupiah(0), 'Rp 0');
    expect(formatRupiah(5000), 'Rp 5.000');
    expect(formatRupiah(12500), 'Rp 12.500');
    expect(formatRupiah(1000000), 'Rp 1.000.000');
  });

  test('formatDateTime memakai format dd/MM/yyyy HH:mm', () {
    expect(
      formatDateTime(DateTime(2026, 11, 14, 13, 5)),
      '14/11/2026 13:05',
    );
    expect(formatDateTime(null), '-');
  });

  test('keranjang menghitung jumlah dan total dengan benar', () {
    final CartService cart = CartService.instance;
    cart.clear();

    const MenuItem nasi = MenuItem(
      id: 'm1',
      name: 'Nasi Goreng',
      price: 15000,
      category: 'Makanan',
      stock: 10,
    );
    const MenuItem teh = MenuItem(
      id: 'm2',
      name: 'Es Teh',
      price: 5000,
      category: 'Minuman',
      stock: 10,
    );

    cart.add(nasi);
    cart.add(nasi);
    cart.add(teh);
    expect(cart.count, 3);
    expect(cart.total, 35000);

    cart.decrease('m1');
    expect(cart.count, 2);
    expect(cart.total, 20000);

    cart.remove('m2');
    expect(cart.count, 1);
    expect(cart.total, 15000);

    cart.clear();
    expect(cart.isEmpty, isTrue);
    expect(cart.total, 0);
  });

  test('keranjang tidak menambah melebihi stok', () {
    final CartService cart = CartService.instance;
    cart.clear();

    const MenuItem roti = MenuItem(
      id: 'm3',
      name: 'Roti Bakar',
      price: 9000,
      category: 'Snack',
      stock: 1,
    );

    cart.add(roti);
    cart.add(roti);
    expect(cart.count, 1);
  });
}
