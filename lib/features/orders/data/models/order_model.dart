import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final String image;
  final int selectedSize;
  final String selectedColor;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.image,
    required this.selectedSize,
    required this.selectedColor,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'image': image,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      image: map['image'] ?? '',
      selectedSize: map['selectedSize'] ?? 0,
      selectedColor: map['selectedColor'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }
}

class OrderModel {
  final String orderId;
  final String userId;
  final String customerName;
  final String email;
  final Map<String, dynamic> shippingAddress;
  final List<OrderItemModel> items;
  final double subTotal;
  final String? voucherApplied;
  final double discountAmount;
  final double totalPrice;
  final String paymentMethod;
  final String status; // "pending" | "delivering" | "completed" | "cancelled"
  final Timestamp? createdAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.email,
    required this.shippingAddress,
    required this.items,
    required this.subTotal,
    this.voucherApplied,
    required this.discountAmount,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'customerName': customerName,
      'email': email,
      'shippingAddress': shippingAddress,
      'items': items.map((x) => x.toMap()).toList(),
      'subTotal': subTotal,
      'voucherApplied': voucherApplied,
      'discountAmount': discountAmount,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      orderId: id,
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? '',
      email: map['email'] ?? '',
      shippingAddress: Map<String, dynamic>.from(map['shippingAddress'] ?? {}),
      items: map['items'] != null
          ? List<OrderItemModel>.from((map['items'] as List).map(
              (x) => OrderItemModel.fromMap(x as Map<String, dynamic>),
            ))
          : [],
      subTotal: (map['subTotal'] ?? 0.0).toDouble(),
      voucherApplied: map['voucherApplied'],
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'Cash on Delivery',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] as Timestamp?,
    );
  }
}
