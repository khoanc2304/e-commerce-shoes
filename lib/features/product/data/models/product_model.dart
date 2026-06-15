import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String name;
  final String brand;
  final double basePrice;
  final String description;
  final List<String> images;
  final List<int> availableSizes;
  final List<String> colors;
  final int stock;
  final int salesCount;
  final double averageRating;
  final int reviewCount; // Added to help calculate math accurately
  final Timestamp? createdAt;

  ProductModel({
    required this.productId,
    required this.name,
    required this.brand,
    required this.basePrice,
    required this.description,
    required this.images,
    required this.availableSizes,
    required this.colors,
    required this.stock,
    required this.salesCount,
    required this.averageRating,
    required this.reviewCount,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'brand': brand,
      'basePrice': basePrice,
      'description': description,
      'images': images,
      'availableSizes': availableSizes,
      'colors': colors,
      'stock': stock,
      'salesCount': salesCount,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      productId: id,
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      basePrice: (map['basePrice'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      availableSizes: List<int>.from(map['availableSizes'] ?? []),
      colors: List<String>.from(map['colors'] ?? []),
      stock: map['stock'] ?? 0,
      salesCount: map['salesCount'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      createdAt: map['createdAt'] as Timestamp?,
    );
  }
}
