const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

// Creates an immutable seller-earnings ledger entry when an order becomes delivered.
// Deploy with: firebase deploy --only functions
exports.createSellerEarningOnDelivered = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after || before.status === 'delivered' || after.status !== 'delivered') return;
  const orderId = event.params.orderId;
  const sellerId = after.vendorId;
  if (!sellerId) return;

  const ref = db.collection('seller_earnings').doc(orderId);
  await ref.set({
    orderId,
    sellerId,
    vendorType: after.vendorType || 'vendor',
    subtotal: Number(after.subtotal || 0),
    commissionRate: Number(after.commissionRate || 0),
    commission: Number(after.commission || 0),
    sellerPayout: Number(after.sellerPayout || 0),
    deliveryFee: Number(after.deliveryFee || 0),
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: false });
});

// Creates a refund-review record when a paid order is cancelled.
// Actual money movement must be performed by the configured payment provider
// and verified server-side; this function never pretends a refund happened.
const { onDocumentUpdated: onOrderUpdated } = require('firebase-functions/v2/firestore');
exports.createRefundReviewOnCancellation = onOrderUpdated('orders/{orderId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after || before.status === 'cancelled' || after.status !== 'cancelled') return;
  if (after.paymentMethod === 'cash_on_delivery') return;
  await db.collection('refund_requests').doc(event.params.orderId).set({
    orderId: event.params.orderId,
    customerId: after.customerId,
    amount: Number(after.total || 0),
    reason: after.cancellationReason || 'Customer cancellation',
    status: 'pending_gateway_refund',
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });
});
