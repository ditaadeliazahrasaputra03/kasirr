import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../services/auth_service.dart';
import '../../services/menu_service.dart';
import '../../utils/format.dart';
import '../kasir/order_history_screen.dart';
import 'menu_form_screen.dart';

/// Layar Admin: CRUD menu lengkap (Create, Read, Update, Delete).
/// Daftar dibaca real-time dari Firestore, jadi perubahan di sini
/// langsung terlihat di layar Kasir.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _search = '';
  String _category = 'Semua';

  Future<void> _confirmDelete(MenuItem menu) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Menu?'),
          content: Text(
            'Menu "${menu.name}" akan dihapus permanen dari daftar.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await MenuService.instance.deleteMenu(menu.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${menu.name}" dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
  }

  List<MenuItem> _filtered(List<MenuItem> menus) {
    return menus.where((MenuItem menu) {
      final bool matchCategory =
          _category == 'Semua' || menu.category == _category;
      final bool matchSearch = _search.isEmpty ||
          menu.name.toLowerCase().contains(_search.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final String name = AuthService.instance.currentUser?.name ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Menu (Admin)'),
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
            onPressed: _logout,
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
                    child: Text('Belum ada menu. Ketuk + untuk menambah.'),
                  );
                }
                return ListView.builder(
                  itemCount: menus.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MenuItem menu = menus[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            menu.name.isEmpty
                                ? '?'
                                : menu.name[0].toUpperCase(),
                          ),
                        ),
                        title: Text(menu.name),
                        subtitle: Text(
                          '${formatRupiah(menu.price)}'
                          ' • Stok: ${menu.stock}'
                          ' • ${menu.category}'
                          '${menu.isActive ? '' : ' • Nonaktif'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Ubah',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => MenuFormScreen(menu: menu),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outlined),
                              tooltip: 'Hapus',
                              onPressed: () => _confirmDelete(menu),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Masuk sebagai $name (Admin) • Data tersimpan real-time di Firebase',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MenuFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_outlined),
        label: const Text('Tambah Menu'),
      ),
    );
  }
}