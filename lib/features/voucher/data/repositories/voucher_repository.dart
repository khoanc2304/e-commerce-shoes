import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../voucher/data/models/coupon_model.dart';

class VoucherRepository {
  final FirebaseFirestore _firestore;

  VoucherRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<CouponModel>> getCouponsStream() {
    return _firestore.collection('coupons').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CouponModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addCoupon(CouponModel coupon) async {
    try {
      await _firestore
          .collection('coupons')
          .doc(coupon.couponId)
          .set(coupon.toMap());
    } catch (e) {
      throw Exception('Failed to add coupon: $e');
    }
  }

  Future<void> updateCoupon(CouponModel coupon) async {
    try {
      await _firestore
          .collection('coupons')
          .doc(coupon.couponId)
          .update(coupon.toMap());
    } catch (e) {
      throw Exception('Failed to update coupon: $e');
    }
  }

  Future<void> deleteCoupon(String couponId) async {
    try {
      await _firestore.collection('coupons').doc(couponId).delete();
    } catch (e) {
      throw Exception('Failed to delete coupon: $e');
    }
  }

  Future<CouponModel?> validateCoupon(String code, double currentSubtotal) async {
    final query = await _firestore
        .collection('coupons')
        .where('code', isEqualTo: code)
        .where('isActive', isEqualTo: true)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid or inactive coupon code.');
    }

    final doc = query.docs.first;
    final coupon = CouponModel.fromMap(doc.data(), doc.id);

    // Validate Expiry
    if (coupon.expiryDate != null && coupon.expiryDate!.toDate().isBefore(DateTime.now())) {
      throw Exception('This coupon has expired.');
    }

    // Validate Max Usage (0 = unlimited)
    if (coupon.maxUsage > 0 && coupon.usageCount >= coupon.maxUsage) {
      throw Exception('This coupon has reached its usage limit.');
    }

    // Validate Min Order
    if (currentSubtotal < coupon.minOrderValue) {
      throw Exception(
        'Minimum order value of \$${coupon.minOrderValue.toStringAsFixed(2)} not met.',
      );
    }

    return coupon;
  }

  /// Atomically increments usageCount on the coupon document.
  /// Uses FieldValue.increment to avoid race conditions when multiple
  /// users redeem the same coupon simultaneously.
  Future<void> incrementCouponUsage(String couponId) async {
    await _firestore.collection('coupons').doc(couponId).update({
      'usageCount': FieldValue.increment(1),
    });
  }
}
