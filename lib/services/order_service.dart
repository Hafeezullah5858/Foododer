import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createOrder({required String customerId, required String vendorId, required List<Map<String, dynamic>> items, required double total, required String address, required String paymentMethod, double? deliveryLat, double? deliveryLng, double subtotal = 0, double deliveryFee = 0, double platformFee = 0, double commission = 0, double commissionRate = 0.10, double sellerPayout = 0, double discount = 0, String couponCode = ''}) async {
    final ref = await _db.collection('orders').add({
      'customerId': customerId, 'vendorId': vendorId, 'riderId': '', 'status': 'placed',
      'items': items, 'subtotal': subtotal > 0 ? subtotal : total, 'deliveryFee': deliveryFee, 'platformFee': platformFee, 'commission': commission, 'commissionRate': commissionRate, 'sellerPayout': sellerPayout, 'discount': discount, 'couponCode': couponCode, 'total': total, 'address': address, 'paymentMethod': paymentMethod,
      'deliveryLat': deliveryLat, 'deliveryLng': deliveryLng,
      'paymentStatus': paymentMethod == 'cash_on_delivery' ? 'pending_cash' : 'requires_gateway', 'refundStatus': 'not_applicable', 'cancellationReason': '', 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<OrderModel>> watchCustomerOrders(String customerId) => _db.collection('orders').where('customerId', isEqualTo: customerId).orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(OrderModel.fromDoc).toList());

  Stream<List<OrderModel>> watchVendorOrders(String vendorId) => _db.collection('orders').where('vendorId', isEqualTo: vendorId).orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(OrderModel.fromDoc).toList());

  Future<void> cancelOrder(String orderId, String reason) async {
    final ref = _db.collection('orders').doc(orderId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Order not found');
    final data = snap.data()!;
    if (data['customerId'] != FirebaseAuth.instance.currentUser?.uid) throw Exception('Not your order');
    if (data['status'] != 'placed') throw Exception('Order cancellation is only available before vendor acceptance.');
    final paymentMethod = data['paymentMethod'] ?? 'cash_on_delivery';
    await ref.update({
      'status': 'cancelled',
      'cancellationReason': reason.trim(),
      'refundStatus': paymentMethod == 'cash_on_delivery' ? 'not_applicable' : 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String orderId, String status) async {
    final ref = _db.collection('orders').doc(orderId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    await ref.update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
    final customerId = data['customerId']?.toString() ?? '';
    final senderId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (customerId.isNotEmpty && senderId.isNotEmpty && customerId != senderId) {
      await _db.collection('notifications').add({
        'recipientId': customerId,
        'senderId': senderId,
        'title': 'Order update',
        'body': 'Order #${orderId.substring(0, orderId.length > 6 ? 6 : orderId.length)} is now $status.',
        'orderId': orderId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> assignRider(String orderId, String riderId) async {
    final ref = _db.collection('orders').doc(orderId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    await ref.update({'riderId': riderId, 'status': 'picked_up', 'updatedAt': FieldValue.serverTimestamp()});
    final customerId = data['customerId']?.toString() ?? '';
    if (customerId.isNotEmpty) {
      await _db.collection('notifications').add({
        'recipientId': customerId,
        'senderId': riderId,
        'title': 'Rider assigned',
        'body': 'A rider has picked up your order.',
        'orderId': orderId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
