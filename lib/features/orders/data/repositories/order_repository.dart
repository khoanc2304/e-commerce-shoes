import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../../../cart/data/models/cart_model.dart';

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

  Stream<List<OrderModel>> getAllOrdersStream() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    if (newStatus == 'cancelled') {
      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore.collection('orders').doc(orderId);
        final orderDoc = await transaction.get(orderRef);
        
        if (!orderDoc.exists) throw Exception("Order not found.");
        
        final orderData = orderDoc.data()!;
        if (orderData['status'] == 'cancelled') return; // Already cancelled

        // Restore stock
        final items = List<dynamic>.from(orderData['items'] ?? []);
        for (var itemData in items) {
          final productId = itemData['productId'];
          final quantity = itemData['quantity'] ?? 0;
          
          final productRef = _firestore.collection('products').doc(productId);
          final productDoc = await transaction.get(productRef);
          
          if (productDoc.exists) {
            final pData = productDoc.data()!;
            final currentStock = pData['stock'] ?? 0;
            final currentSales = pData['salesCount'] ?? 0;
            
            transaction.update(productRef, {
              'stock': currentStock + quantity,
              'salesCount': currentSales > quantity ? currentSales - quantity : 0,
            });
          }
        }
        
        transaction.update(orderRef, {'status': 'cancelled'});
      });
    } else {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
    }
  }

  Future<void> updatePaymentStatus(String orderId, bool isPaid) async {
    await _firestore.collection('orders').doc(orderId).update({
      'isPaid': isPaid,
    });
  }

  Future<String> executeCheckout({
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

    final orderId = const Uuid().v4();

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Read all product documents to verify stock AND read cart doc
        List<DocumentSnapshot> productDocs = [];
        for (var item in cartItems) {
          final productRef = _firestore.collection('products').doc(item.productId);
          final productDoc = await transaction.get(productRef);
          
          if (!productDoc.exists) {
            throw Exception("Product ${item.productName} no longer exists.");
          }
          
          final currentStock = (productDoc.data() as Map<String, dynamic>?)?['stock'] ?? 0;
          if (currentStock < item.quantity) {
            throw Exception("Insufficient stock for ${item.productName}. Only $currentStock left.");
          }
          
          productDocs.add(productDoc);
        }

        // Read Cart Document before any writes
        final cartRef = _firestore.collection('carts').doc(userId);
        final cartDoc = await transaction.get(cartRef);

        // 2. If we reach here, all reads are done. Proceed with writes.
        
        // Update Products (decrement stock, increment sales)
        for (int i = 0; i < cartItems.length; i++) {
          final item = cartItems[i];
          final productRef = _firestore.collection('products').doc(item.productId);
          
          final currentStock = (productDocs[i].data() as Map<String, dynamic>?)?['stock'] ?? 0;
          final currentSales = (productDocs[i].data() as Map<String, dynamic>?)?['salesCount'] ?? 0;
          
          transaction.update(productRef, {
            'stock': currentStock - item.quantity,
            'salesCount': currentSales + item.quantity,
          });
        }

        // 3. Create the Order Document
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
          isPaid: false,
          createdAt: Timestamp.now(),
        );

        transaction.set(orderRef, orderModel.toMap());

        // 4. Remove only the purchased items from the User's Cart
        if (cartDoc.exists) {
          final data = cartDoc.data()!;
          List<dynamic> currentCartItems = data['items'] ?? [];
          
          for (var purchasedItem in cartItems) {
            currentCartItems.removeWhere((item) => 
                item['productId'] == purchasedItem.productId && 
                item['selectedSize'] == purchasedItem.selectedSize &&
                item['selectedColor'] == purchasedItem.selectedColor);
          }
          
          transaction.update(cartRef, {
            'items': currentCartItems,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      return orderId;
    } catch (e) {
      // Re-throw to handle in UI
      throw Exception('Checkout failed: $e');
    }
  }
}
