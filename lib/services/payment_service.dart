import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment gateway abstraction. COD is active. Online gateways intentionally
/// remain disabled until merchant credentials + server-side verification are configured.
class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createPaymentRecord({required String orderId, required String customerId, required double amount, required String method}) async {
    final ref = await _db.collection('payments').add({
      'orderId': orderId,
      'customerId': customerId,
      'amount': amount,
      'method': method,
      'status': method == 'cash_on_delivery' ? 'pending_cash' : 'requires_gateway',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> requestRefund({required String orderId, required String customerId, required double amount, required String reason}) async {
    await _db.collection('refund_requests').doc(orderId).set({
      'orderId': orderId,
      'customerId': customerId,
      'amount': amount,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
