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

  Future<void> addToCart(String userId, CartItemModel newItem) async {
    final cartRef = _firestore.collection('carts').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(cartRef);
      if (doc.exists) {
        final data = doc.data()!;
        List<dynamic> items = data['items'] ?? [];
        
        bool itemExists = false;
        for (int i = 0; i < items.length; i++) {
          if (items[i]['productId'] == newItem.productId && 
              items[i]['selectedSize'] == newItem.selectedSize &&
              items[i]['selectedColor'] == newItem.selectedColor) {
            items[i]['quantity'] = (items[i]['quantity'] ?? 0) + newItem.quantity;
            itemExists = true;
            break;
          }
        }
        
        if (!itemExists) {
          items.add(newItem.toMap());
        }
        
        transaction.update(cartRef, {'items': items, 'updatedAt': FieldValue.serverTimestamp()});
      } else {
        // Create new cart
        final newCart = CartModel(
          cartId: userId,
          userId: userId,
          items: [newItem],
        );
        transaction.set(cartRef, newCart.toMap());
      }
    });
  }

  Future<void> updateCartItemQuantity(String userId, String productId, int size, String color, int newQuantity) async {
    final cartRef = _firestore.collection('carts').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(cartRef);
      if (doc.exists) {
        final data = doc.data()!;
        List<dynamic> items = data['items'] ?? [];
        
        for (int i = 0; i < items.length; i++) {
          if (items[i]['productId'] == productId && 
              items[i]['selectedSize'] == size &&
              items[i]['selectedColor'] == color) {
            items[i]['quantity'] = newQuantity;
            break;
          }
        }
        transaction.update(cartRef, {'items': items, 'updatedAt': FieldValue.serverTimestamp()});
      }
    });
  }

  Future<void> removeCartItem(String userId, String productId, int size, String color) async {
    final cartRef = _firestore.collection('carts').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(cartRef);
      if (doc.exists) {
        final data = doc.data()!;
        List<dynamic> items = data['items'] ?? [];
        
        items.removeWhere((item) => 
            item['productId'] == productId && 
            item['selectedSize'] == size &&
            item['selectedColor'] == color);
        
        transaction.update(cartRef, {'items': items, 'updatedAt': FieldValue.serverTimestamp()});
      }
    });
  }

  Future<void> restoreCart(String userId, List<CartItemModel> items) async {
    final cartRef = _firestore.collection('carts').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(cartRef);
      if (doc.exists) {
        final data = doc.data()!;
        List<dynamic> currentItems = data['items'] ?? [];
        for (var item in items) {
          bool exists = currentItems.any((x) =>
              x['productId'] == item.productId &&
              x['selectedSize'] == item.selectedSize &&
              x['selectedColor'] == item.selectedColor);
          if (!exists) {
            currentItems.add(item.toMap());
          }
        }
        transaction.update(cartRef, {'items': currentItems, 'updatedAt': FieldValue.serverTimestamp()});
      } else {
        final newCart = CartModel(
          cartId: userId,
          userId: userId,
          items: items,
        );
        transaction.set(cartRef, newCart.toMap());
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
