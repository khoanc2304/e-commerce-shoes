import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

Future<void> seedFirebaseData(BuildContext context) async {
  final firestore = FirebaseFirestore.instance;
  
  // Hiển thị loading
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Đang nạp dữ liệu vào Firebase...⏳'), duration: Duration(seconds: 2)),
  );

  final List<Map<String, dynamic>> mockProducts = [
    {
      "productId": "prod_air_force_1",
      "name": "Nike Air Force 1 '07",
      "brand": "Nike",
      "basePrice": 110.0,
      "description": "Sự rực rỡ tiếp tục sống mãi trong Nike Air Force 1 '07, dòng giày bóng rổ nguyên bản.",
      "images": ["https://images.unsplash.com/photo-1595950653106-6c9ebd614c3a?w=800"],
      "availableSizes": [39, 40, 41, 42],
      "colors": ["White", "Black"],
      "stock": 100,
      "salesCount": 450,
      "averageRating": 4.9,
      "reviewCount": 120,
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp(),
    },
    {
      "productId": "prod_ultraboost_22",
      "name": "Adidas Ultraboost 22",
      "brand": "Adidas",
      "basePrice": 190.0,
      "description": "Giày chạy bộ cực êm ái, đệm boost đàn hồi hoàn trả năng lượng siêu việt.",
      "images": ["https://images.unsplash.com/photo-1587563871167-1ee9c731aefb?w=800"],
      "availableSizes": [40, 41, 42, 43],
      "colors": ["Core Black", "Cloud White"],
      "stock": 45,
      "salesCount": 200,
      "averageRating": 4.7,
      "reviewCount": 85,
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp(),
    },
    {
      "productId": "prod_vans_oldskool",
      "name": "Vans Old Skool",
      "brand": "Vans",
      "basePrice": 60.0,
      "description": "Huyền thoại trượt ván cổ điển, phối đồ cực kỳ dễ dàng và phong cách.",
      "images": ["https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=800"],
      "availableSizes": [36, 37, 38, 39, 40],
      "colors": ["Black/White"],
      "stock": 200,
      "salesCount": 890,
      "averageRating": 4.6,
      "reviewCount": 310,
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp(),
    },
    {
      "productId": "prod_jordan_1_high",
      "name": "Air Jordan 1 Retro High",
      "brand": "Nike",
      "basePrice": 250.0,
      "description": "Biểu tượng của làng sneaker. Phối màu Chicago chuẩn mực.",
      "images": ["https://images.unsplash.com/photo-1515955656352-a1fa3ffcd111?w=800"],
      "availableSizes": [41, 42, 43],
      "colors": ["Red/White/Black"],
      "stock": 10,
      "salesCount": 500,
      "averageRating": 5.0,
      "reviewCount": 420,
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp(),
    }
  ];

  final List<Map<String, dynamic>> mockCoupons = [
    {
      "couponId": "SHUESX50",
      "code": "SHUESX50",
      "discountPercentage": 50.0,
      "isActive": true,
      "expiryDate": Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    },
    {
      "couponId": "FREESHIP",
      "code": "FREESHIP",
      "discountPercentage": 10.0,
      "isActive": true,
      "expiryDate": Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
    }
  ];

  try {
    // 1. Nạp Products
    for (var prod in mockProducts) {
      await firestore.collection('products').doc(prod['productId']).set(prod);
    }
    
    // 2. Nạp Coupons
    for (var coupon in mockCoupons) {
      await firestore.collection('coupons').doc(coupon['couponId']).set(coupon);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Nạp dữ liệu thành công! Hãy Refresh lại app.'), backgroundColor: Colors.green)
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red)
      );
    }
  }
}
