import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_config.dart';
import '../models/order_model.dart';

/// Penyimpanan pesanan/transaksi.
///
/// Mode Firebase: koleksi Firestore `orders`, dibaca real-time.
/// Mode Demo: daftar di memori selama aplikasi berjalan.
class OrderService {
  OrderService._();

  static final OrderService instance = OrderService._();

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('orders');

  List<OrderModel> _demoOrders = <OrderModel>[];
  final StreamController<List<OrderModel>> _demoController =
      StreamController<List<OrderModel>>.broadcast();

  Stream<List<OrderModel>> ordersStream() {
    if (AppConfig.isDemoMode) {
      Future.microtask(
        () => _demoController.add(List<OrderModel>.of(_demoOrders)),
      );
      return _demoController.stream;
    }
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                OrderModel.fromFirestore(doc))
            .toList());
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    if (AppConfig.isDemoMode) {
      final OrderModel created = order.copyWith(
        id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
      );
      _demoOrders = <OrderModel>[created, ..._demoOrders];
      _demoController.add(List<OrderModel>.of(_demoOrders));
      return created;
    }
    final Map<String, dynamic> data = order.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp();
    final DocumentReference<Map<String, dynamic>> ref =
        await _collection.add(data);
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    return OrderModel.fromFirestore(doc);
  }

  Future<void> updatePaymentStatus(
    String orderId,
    String status, {
    String? paymentId,
  }) async {
    if (AppConfig.isDemoMode) {
      _demoOrders = _demoOrders.map((OrderModel order) {
        if (order.id != orderId) {
          return order;
        }
        return order.copyWith(
          paymentStatus: status,
          paymentId: paymentId ?? order.paymentId,
        );
      }).toList();
      _demoController.add(List<OrderModel>.of(_demoOrders));
      return;
    }
    final Map<String, dynamic> data = <String, dynamic>{
      'paymentStatus': status,
    };
    if (paymentId != null) {
      data['paymentId'] = paymentId;
    }
    await _collection.doc(orderId).update(data);
  }
}
