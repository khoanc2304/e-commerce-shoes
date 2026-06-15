import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';
import '../models/coupon_model.dart';

class CartRepository {
  final FirebaseFirestore _firestore;

  CartRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<CartModel?> getCartStream(String userId) {
    return _firestore
        .collection('carts')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return CartModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  Future<void> updateCartItemQuantity(String userId, String productId, int newQuantity) async {
    final cartRef = _firestore.collection('carts').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(cartRef);
      if (doc.exists) {
        final data = doc.data()!;
        List<dynamic> items = data['items'] ?? [];
        
        for (int i = 0; i < items.length; i++) {
          if (items[i]['productId'] == productId) {
            items[i]['quantity'] = newQuantity;
            break;
          }
        }
        transaction.update(cartRef, {'items': items, 'updatedAt': FieldValue.serverTimestamp()});
      }
    });
  }

  Future<void> removeCartItem(String userId, String productId) async {
    final cartRef = _firestore.collection('carts').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(cartRef);
      if (doc.exists) {
        final data = doc.data()!;
        List<dynamic> items = data['items'] ?? [];
        
        items.removeWhere((item) => item['productId'] == productId);
        
        transaction.update(cartRef, {'items': items, 'updatedAt': FieldValue.serverTimestamp()});
      }
    });
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

    // Validate Min Order
    if (currentSubtotal < coupon.minOrderValue) {
      throw Exception('Minimum order value of \$${coupon.minOrderValue} not met.');
    }

    return coupon;
  }
}
