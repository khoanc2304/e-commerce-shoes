import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../../cart/data/models/cart_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<OrderModel>> getOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> executeCheckout({
    required String userId,
    required String customerName,
    required String email,
    required Map<String, dynamic> shippingAddress,
    required List<CartItemModel> cartItems,
    required double subTotal,
    required double discountAmount,
    required double totalPrice,
    String? voucherApplied,
    required String paymentMethod,
  }) async {
    if (cartItems.isEmpty) throw Exception("Cart is empty.");

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Read all product documents to verify stock
        List<DocumentSnapshot> productDocs = [];
        for (var item in cartItems) {
          final productRef = _firestore.collection('products').doc(item.productId);
          final productDoc = await transaction.get(productRef);
          
          if (!productDoc.exists) {
            throw Exception("Product ${item.productName} no longer exists.");
          }
          
          final currentStock = productDoc.data()?['stock'] ?? 0;
          if (currentStock < item.quantity) {
            throw Exception("Insufficient stock for ${item.productName}. Only $currentStock left.");
          }
          
          productDocs.add(productDoc);
        }

        // 2. If we reach here, all items have sufficient stock. Proceed with updates.
        
        // Update Products (decrement stock, increment sales)
        for (int i = 0; i < cartItems.length; i++) {
          final item = cartItems[i];
          final productRef = _firestore.collection('products').doc(item.productId);
          
          final currentStock = productDocs[i].data()?['stock'] ?? 0;
          final currentSales = productDocs[i].data()?['salesCount'] ?? 0;
          
          transaction.update(productRef, {
            'stock': currentStock - item.quantity,
            'salesCount': currentSales + item.quantity,
          });
        }

        // 3. Create the Order Document
        final orderId = const Uuid().v4();
        final orderRef = _firestore.collection('orders').doc(orderId);
        
        final orderItems = cartItems.map((cartItem) => OrderItemModel(
          productId: cartItem.productId,
          productName: cartItem.productName,
          image: cartItem.image,
          selectedSize: cartItem.selectedSize,
          selectedColor: cartItem.selectedColor,
          quantity: cartItem.quantity,
          price: cartItem.price,
        )).toList();

        final orderModel = OrderModel(
          orderId: orderId,
          userId: userId,
          customerName: customerName,
          email: email,
          shippingAddress: shippingAddress,
          items: orderItems,
          subTotal: subTotal,
          voucherApplied: voucherApplied,
          discountAmount: discountAmount,
          totalPrice: totalPrice,
          paymentMethod: paymentMethod,
          status: 'pending',
          createdAt: Timestamp.now(),
        );

        transaction.set(orderRef, orderModel.toMap());

        // 4. Clear the User's Cart
        final cartRef = _firestore.collection('carts').doc(userId);
        transaction.update(cartRef, {
          'items': [],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      // Re-throw to handle in UI
      throw Exception('Checkout failed: $e');
    }
  }
}
