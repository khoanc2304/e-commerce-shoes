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
  final bool isActive;
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
    this.isActive = true,
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
      'isActive': isActive,
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
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  ProductModel copyWith({
    String? productId,
    String? name,
    String? brand,
    double? basePrice,
    String? description,
    List<String>? images,
    List<int>? availableSizes,
    List<String>? colors,
    int? stock,
    int? salesCount,
    double? averageRating,
    int? reviewCount,
    bool? isActive,
    Timestamp? createdAt,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      basePrice: basePrice ?? this.basePrice,
      description: description ?? this.description,
      images: images ?? this.images,
      availableSizes: availableSizes ?? this.availableSizes,
      colors: colors ?? this.colors,
      stock: stock ?? this.stock,
      salesCount: salesCount ?? this.salesCount,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
