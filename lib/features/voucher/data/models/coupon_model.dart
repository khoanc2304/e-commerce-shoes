import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String couponId;
  final String code;
  final String discountType; // "percentage" | "fixed"
  final double discountValue;
  final double minOrderValue;
  final Timestamp? expiryDate;
  final bool isActive;
  /// 0 means unlimited usage
  final int maxUsage;
  final int usageCount;

  CouponModel({
    required this.couponId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.isActive,
    this.expiryDate,
    this.maxUsage = 0,
    this.usageCount = 0,
  });

  /// Compute discount amount given a subtotal
  double calculateDiscount(double subtotal) {
    if (discountType == 'percentage') {
      return subtotal * (discountValue / 100);
    }
    return discountValue;
  }

  Map<String, dynamic> toMap() {
    return {
      'couponId': couponId,
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'isActive': isActive,
      'expiryDate': expiryDate,
      'maxUsage': maxUsage,
      'usageCount': usageCount,
    };
  }

  factory CouponModel.fromMap(Map<String, dynamic> map, String id) {
    return CouponModel(
      couponId: id,
      code: map['code'] ?? '',
      discountType: map['discountType'] ?? 'percentage',
      discountValue: (map['discountValue'] ?? 0.0).toDouble(),
      minOrderValue: (map['minOrderValue'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? false,
      expiryDate: map['expiryDate'] as Timestamp?,
      // Gracefully handle Firestore docs that don't yet have these fields
      maxUsage: (map['maxUsage'] ?? 0) as int,
      usageCount: (map['usageCount'] ?? 0) as int,
    );
  }
}
