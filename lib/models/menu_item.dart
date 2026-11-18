import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu produk/menu yang dijual. Disimpan di koleksi Firestore `menus`.
class MenuItem {
  final String id;
  final String name;
  final int price;
  final String category;
  final String description;
  final String imageUrl;
  final int stock;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.description = '',
    this.imageUrl = '',
    this.stock = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MenuItem.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) {
    return MenuItem(
      id: id,
      name: (map['name'] as String?) ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      category: (map['category'] as String?) ?? 'Lainnya',
      description: (map['description'] as String?) ?? '',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'price': price,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'stock': stock,
      'isActive': isActive,
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    int? price,
    String? category,
    String? description,
    String? imageUrl,
    int? stock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Kategori menu yang dipakai di filter dan form.
const List<String> menuCategories = <String>[
  'Makanan',
  'Minuman',
  'Snack',
  'Lainnya',
];
