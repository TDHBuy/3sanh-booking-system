import 'package:client_web/models/order_model.dart';

abstract class OrderRepository {
  /// Create new order
  Future<String> createOrder(OrderModel order);

  /// Get orders of reservation
  Future<OrderModel?> getOrderByReservation(String reservationId);

  /// Stream order by reservations
  Stream<OrderModel?> streamOrderByReservation(String reservationId);

  /// Update order
  Future<void> updateOrder(String orderId, OrderModel order);

  /// Complete order
  Future<void> completeOrder(String orderId);

  /// Get completed orders
  Future<List<OrderModel>> getCompletedOrders({int limit});
}
