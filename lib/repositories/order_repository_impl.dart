import 'package:client_web/models/order_model.dart';
import 'package:client_web/repositories/order_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderRepositoryImplement implements OrderRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'orders';
  OrderRepositoryImplement(this._firestore);
  @override
  Future<String> createOrder(OrderModel order) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(order.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  @override
  Future<OrderModel?> getOrderByReservation(String reservationId) async {
    // TODO: implement getOrderByReservation
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('reservationId', isEqualTo: reservationId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return OrderModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  @override
  Future<void> completeOrder(String orderId) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'completeAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to complete order: $e');
    }
  }

  @override
  Stream<OrderModel?> streamOrderByReservation(String reservationId) {
    return _firestore
        .collection(_collection)
        .where('reservationId', isEqualTo: reservationId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return OrderModel.fromFirestore(snapshot.docs.first);
        });
  }

  @override
  Future<void> updateOrder(String orderId, OrderModel order) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(orderId)
          .update(order.toFirestore());
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  @override
  Future<List<OrderModel>> getCompletedOrders({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('completedAt', isNull: false)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get completed orders: $e');
    }
  }
}
