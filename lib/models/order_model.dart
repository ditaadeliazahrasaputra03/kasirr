import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu baris item di dalam pesanan.
class OrderItem {
  final String menuId;
  final String name;
  final int price;
  final int qty;

  const OrderItem({
    required this.menuId,
    required this.name,
    required this.price,
    required this.qty,
  });

  int get subtotal => price * qty;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuId: (map['menuId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      qty: (map['qty'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'menuId': menuId,
      'name': name,
      'price': price,
      'qty': qty,
    };
  }
}

/// Satu transaksi/pesanan. Disimpan di koleksi Firestore `orders`.
class OrderModel {
  final String id;
  final List<OrderItem> items;
  final int total;
  final String paymentMethod;
  final String paymentId;
  final String paymentStatus;
  final String cashierEmail;
  final String cashierName;
  final String customerName;
  final DateTime? createdAt;

  const OrderModel({
    required this.id,
    required this.items,
    required this.total,
    this.paymentMethod = 'MiomiPay',
    this.paymentId = '',
    this.paymentStatus = 'pending',
    this.cashierEmail = '',
    this.cashierName = '',
    this.customerName = '',
    this.createdAt,
  });

  bool get isPaid => paymentStatus == 'paid';

  String get statusLabel {
    switch (paymentStatus) {
      case 'paid':
        return 'Lunas';
      case 'failed':
        return 'Gagal';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Menunggu Pembayaran';
    }
  }

  factory OrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return OrderModel.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = (map['items'] as List<dynamic>?) ?? <dynamic>[];
    return OrderModel(
      id: id,
      items: rawItems
          .map((dynamic e) =>
              OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: (map['total'] as num?)?.toInt() ?? 0,
      paymentMethod: (map['paymentMethod'] as String?) ?? 'MiomiPay',
      paymentId: (map['paymentId'] as String?) ?? '',
      paymentStatus: (map['paymentStatus'] as String?) ?? 'pending',
      cashierEmail: (map['cashierEmail'] as String?) ?? '',
      cashierName: (map['cashierName'] as String?) ?? '',
      customerName: (map['customerName'] as String?) ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'items': items.map((OrderItem e) => e.toMap()).toList(),
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'paymentStatus': paymentStatus,
      'cashierEmail': cashierEmail,
      'cashierName': cashierName,
      'customerName': customerName,
    };
  }

  OrderModel copyWith({
    String? id,
    List<OrderItem>? items,
    int? total,
    String? paymentMethod,
    String? paymentId,
    String? paymentStatus,
    String? cashierEmail,
    String? cashierName,
    String? customerName,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      items: items ?? this.items,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      cashierEmail: cashierEmail ?? this.cashierEmail,
      cashierName: cashierName ?? this.cashierName,
      customerName: customerName ?? this.customerName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
