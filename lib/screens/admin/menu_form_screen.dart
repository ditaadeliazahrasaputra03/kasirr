import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/menu_item.dart';
import '../../services/menu_service.dart';

/// Form tambah menu baru (Create) atau ubah menu (Update).
/// Tanpa [menu] berarti mode tambah; dengan [menu] berarti mode ubah.
class MenuFormScreen extends StatefulWidget {
  const MenuFormScreen({super.key, this.menu});

  final MenuItem? menu;

  @override
  State<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends State<MenuFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late String _category;
  late bool _isActive;
  bool _isSaving = false;
  String? _error;

  bool get _isEdit => widget.menu != null;

  @override
  void initState() {
    super.initState();
    final MenuItem? menu = widget.menu;
    _nameController = TextEditingController(text: menu?.name ?? '');
    _priceController =
        TextEditingController(text: menu == null ? '' : '${menu.price}');
    _stockController =
        TextEditingController(text: menu == null ? '0' : '${menu.stock}');
    _descriptionController =
        TextEditingController(text: menu?.description ?? '');
    _imageUrlController = TextEditingController(text: menu?.imageUrl ?? '');
    _category = menu?.category ?? menuCategories.first;
    _isActive = menu?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    final int? price = int.tryParse(_priceController.text.trim());
    final int? stock = int.tryParse(_stockController.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Nama menu wajib diisi.');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Harga harus berupa angka (contoh: 15000).');
      return;
    }
    if (stock == null || stock < 0) {
      setState(() => _error = 'Stok harus berupa angka 0 atau lebih.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final MenuItem menu = MenuItem(
        id: widget.menu?.id ?? '',
        name: name,
        price: price,
        category: _category,
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        stock: stock,
        isActive: _isActive,
        createdAt: widget.menu?.createdAt,
      );
      if (_isEdit) {
        await MenuService.instance.updateMenu(menu);
      } else {
        await MenuService.instance.addMenu(menu);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Menu diperbarui.' : 'Menu ditambahkan.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Gagal menyimpan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Menu' : 'Tambah Menu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Menu *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Harga (Rp) *',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: menuCategories
                  .map(
                    (String c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Stok',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL Gambar (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Menu aktif (tampil di kasir)'),
              value: _isActive,
              onChanged: (bool value) => setState(() => _isActive = value),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
