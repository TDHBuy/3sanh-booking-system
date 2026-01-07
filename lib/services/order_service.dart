import 'package:client_web/models/order_model.dart';
import 'package:client_web/models/order_item.dart';
import 'package:client_web/models/enum/reservation_status.dart';
import 'package:client_web/repositories/order_repository.dart';
import 'package:client_web/repositories/reservation_repository.dart';

class OrderService {
  final OrderRepository _orderRepo;
  final ReservationRepository _reservationRepo;
  OrderService(this._orderRepo, this._reservationRepo);
  Future<String> createOrderForReservation({
    required String reservationId,
    List<OrderItem>? initialItems,
  }) async {
    final existingOrder = await _orderRepo.getOrderByReservation(reservationId);
    if (existingOrder != null) {
      throw Exception('Reservation already has an order');
    }

    final order = OrderModel(
      id: '',
      reservationId: reservationId,
      items: initialItems ?? [],
      totalAmount: OrderModel.calculateTotal(initialItems ?? []),
      completedAt: null,
    );

    return await _orderRepo.createOrder(order);
  }

  /// Get order for repository
  Future<OrderModel?> getOrderByReservation(String reservationId) async {
    return await _orderRepo.getOrderByReservation(reservationId);
  }

  /// Stream order của reservation (realtime)
  Stream<OrderModel?> streamOrderByReservation(String reservationId) {
    return _orderRepo.streamOrderByReservation(reservationId);
  }

  /// Add to order
  Future<void> addItemsToOrder({
    required String reservationId,
    required List<OrderItem> newItems,
  }) async {
    final order = await _orderRepo.getOrderByReservation(reservationId);

    if (order == null) {
      throw Exception('No order found for this reservation');
    }

    if (order.isPaid) {
      throw Exception('Cannot add items to paid order');
    }

    final updatedItems = [...order.items, ...newItems];
    final updatedOrder = order.copyWith(
      items: updatedItems,
      totalAmount: OrderModel.calculateTotal(updatedItems),
    );

    await _orderRepo.updateOrder(order.id, updatedOrder);
  }

  /// Update order
  Future<void> updateItemQuantity({
    required String reservationId,
    required String itemName,
    required int newQuantity,
  }) async {
    final order = await _orderRepo.getOrderByReservation(reservationId);
    if (order == null) throw Exception('Order not found');

    if (order.isPaid) {
      throw Exception('Cannot update paid order');
    }

    if (newQuantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    final updatedItems = order.items.map((item) {
      if (item.name == itemName) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    final updatedOrder = order.copyWith(
      items: updatedItems,
      totalAmount: OrderModel.calculateTotal(updatedItems),
    );

    await _orderRepo.updateOrder(order.id, updatedOrder);
  }

  /// Remove item from order
  Future<void> removeItemFromOrder({
    required String reservationId,
    required String itemName,
  }) async {
    final order = await _orderRepo.getOrderByReservation(reservationId);
    if (order == null) throw Exception('Order not found');

    if (order.isPaid) {
      throw Exception('Cannot remove items from paid order');
    }

    final updatedItems = order.items
        .where((item) => item.name != itemName)
        .toList();

    final updatedOrder = order.copyWith(
      items: updatedItems,
      totalAmount: OrderModel.calculateTotal(updatedItems),
    );

    await _orderRepo.updateOrder(order.id, updatedOrder);
  }

  /// Payment for order
  Future<void> completeOrder(String reservationId) async {
    // 1. Lấy reservation
    final reservation = await _reservationRepo.getById(reservationId);
    if (reservation == null) {
      throw Exception('Reservation not found');
    }

    if (reservation.status != ReservationStatus.arrived) {
      throw Exception('Can only pay for arrived reservations');
    }

    final order = await _orderRepo.getOrderByReservation(reservationId);
    if (order == null) {
      throw Exception('No order found');
    }

    if (!order.hasItems) {
      throw Exception('Order must have at least one item');
    }

    if (order.isPaid) {
      throw Exception('Order already paid');
    }

    await _orderRepo.completeOrder(order.id);
  }
}
