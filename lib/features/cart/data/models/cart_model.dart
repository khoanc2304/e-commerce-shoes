import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String productId;
  final String productName;
  final String image;
  final int selectedSize;
  final String selectedColor;
  int quantity;
  final double price;

  CartItemModel({
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

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
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

class CartModel {
  final String cartId;
  final String userId;
  final List<CartItemModel> items;
  final Timestamp? updatedAt;

  CartModel({
    required this.cartId,
    required this.userId,
    required this.items,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'cartId': cartId,
      'userId': userId,
      'items': items.map((x) => x.toMap()).toList(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory CartModel.fromMap(Map<String, dynamic> map, String id) {
    return CartModel(
      cartId: id,
      userId: map['userId'] ?? '',
      items: map['items'] != null
          ? List<CartItemModel>.from((map['items'] as List).map(
              (x) => CartItemModel.fromMap(x as Map<String, dynamic>),
            ))
          : [],
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }
}
