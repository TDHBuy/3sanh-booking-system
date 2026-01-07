import 'package:client_web/models/order_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String reservationId;
  final List<OrderItem> items;
  final int totalAmount;
  final Timestamp? completedAt;

  OrderModel({
    required this.id,
    required this.reservationId,
    required this.items,
    required this.totalAmount,
    this.completedAt,
  });

  /// Convert from Firestore
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      reservationId: data['reservationId'] ?? '',
      items:
          (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: data['totalAmount'] ?? 0,
      completedAt: data['completedAt'],
    );
  }

  /// Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'reservationId': reservationId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'completedAt': completedAt,
    };
  }

  /// Copy with
  OrderModel copyWith({
    String? id,
    String? reservationId,
    List<OrderItem>? items,
    int? totalAmount,
    Timestamp? completedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Tính tổng tiền từ items
  static int calculateTotal(List<OrderItem> items) {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  /// Checking items
  bool get hasItems => items.isNotEmpty;

  /// Completed at
  bool get isPaid => completedAt != null;
}
