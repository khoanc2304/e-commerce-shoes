import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../product/data/models/product_model.dart';
import '../../../cart/data/models/coupon_model.dart';
import '../../../orders/data/models/order_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // --- Financial Analytics ---
  Future<List<OrderModel>> getCompletedOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  // --- Product Management ---
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all products: $e');
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.productId)
          .set(product.toMap());
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.productId)
          .update(product.toMap());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // --- Coupon Management ---
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
}
