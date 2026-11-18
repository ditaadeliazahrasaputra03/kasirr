import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_config.dart';
import '../models/menu_item.dart';

/// CRUD menu.
///
/// Mode Firebase: data di koleksi Firestore `menus`, dibaca secara
/// real-time lewat snapshots() sehingga perubahan Admin langsung tampil
/// di layar Kasir. Mode Demo: data di memori dengan menu contoh.
class MenuService {
  MenuService._() {
    _demoMenus = <MenuItem>[
      const MenuItem(
        id: 'demo-1',
        name: 'Nasi Goreng Spesial',
        price: 15000,
        category: 'Makanan',
        description: 'Nasi goreng ayam + telur + kerupuk',
        stock: 20,
      ),
      const MenuItem(
        id: 'demo-2',
        name: 'Mie Ayam Bakso',
        price: 13000,
        category: 'Makanan',
        description: 'Mie ayam dengan bakso sapi',
        stock: 15,
      ),
      const MenuItem(
        id: 'demo-3',
        name: 'Ayam Geprek',
        price: 12000,
        category: 'Makanan',
        description: 'Ayam geprek sambal bawang, level 0-3',
        stock: 18,
      ),
      const MenuItem(
        id: 'demo-4',
        name: 'Es Teh Manis',
        price: 5000,
        category: 'Minuman',
        description: 'Teh manis dingin',
        stock: 30,
      ),
      const MenuItem(
        id: 'demo-5',
        name: 'Kopi Susu Gula Aren',
        price: 10000,
        category: 'Minuman',
        description: 'Kopi susu dengan gula aren asli',
        stock: 25,
      ),
      const MenuItem(
        id: 'demo-6',
        name: 'Jus Alpukat',
        price: 12000,
        category: 'Minuman',
        description: 'Jus alpukat + susu kental manis',
        stock: 10,
      ),
      const MenuItem(
        id: 'demo-7',
        name: 'Pisang Goreng Cokelat',
        price: 8000,
        category: 'Snack',
        description: 'Pisang goreng taburan cokelat meses',
        stock: 12,
      ),
      const MenuItem(
        id: 'demo-8',
        name: 'Roti Bakar Keju',
        price: 9000,
        category: 'Snack',
        description: 'Roti bakar isi keju leleh',
        stock: 0,
      ),
    ];
  }

  static final MenuService instance = MenuService._();

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('menus');

  late List<MenuItem> _demoMenus;
  final StreamController<List<MenuItem>> _demoController =
      StreamController<List<MenuItem>>.broadcast();

  /// Stream daftar menu, terurut dari yang terbaru.
  Stream<List<MenuItem>> menusStream() {
    if (AppConfig.isDemoMode) {
      // Kirim isi terbaru begitu ada yang mulai mendengarkan.
      Future.microtask(
        () => _demoController.add(List<MenuItem>.of(_demoMenus)),
      );
      return _demoController.stream;
    }
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                MenuItem.fromFirestore(doc))
            .toList());
  }

  Future<MenuItem> addMenu(MenuItem menu) async {
    if (AppConfig.isDemoMode) {
      final MenuItem created = menu.copyWith(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
      );
      _demoMenus = <MenuItem>[created, ..._demoMenus];
      _demoController.add(List<MenuItem>.of(_demoMenus));
      return created;
    }
    final Map<String, dynamic> data = menu.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    final DocumentReference<Map<String, dynamic>> ref =
        await _collection.add(data);
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    return MenuItem.fromFirestore(doc);
  }

  Future<void> updateMenu(MenuItem menu) async {
    if (AppConfig.isDemoMode) {
      _demoMenus = _demoMenus
          .map((MenuItem e) => e.id == menu.id ? menu : e)
          .toList();
      _demoController.add(List<MenuItem>.of(_demoMenus));
      return;
    }
    final Map<String, dynamic> data = menu.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _collection.doc(menu.id).update(data);
  }

  Future<void> deleteMenu(String id) async {
    if (AppConfig.isDemoMode) {
      _demoMenus =
          _demoMenus.where((MenuItem e) => e.id != id).toList();
      _demoController.add(List<MenuItem>.of(_demoMenus));
      return;
    }
    await _collection.doc(id).delete();
  }

  /// Kurangi stok sesuai item yang terjual (dipanggil setelah bayar lunas).
  Future<void> decreaseStock(Map<String, int> soldQtyByMenuId) async {
    if (AppConfig.isDemoMode) {
      _demoMenus = _demoMenus.map((MenuItem menu) {
        final int sold = soldQtyByMenuId[menu.id] ?? 0;
        if (sold <= 0) {
          return menu;
        }
        final int nextStock = menu.stock - sold;
        return menu.copyWith(stock: nextStock < 0 ? 0 : nextStock);
      }).toList();
      _demoController.add(List<MenuItem>.of(_demoMenus));
      return;
    }
    for (final MapEntry<String, int> entry in soldQtyByMenuId.entries) {
      await _collection.doc(entry.key).update(<String, dynamic>{
        'stock': FieldValue.increment(-entry.value),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
