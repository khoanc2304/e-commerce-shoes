import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String couponId;
  final String code;
  final String discountType; // "percentage" | "fixed"
  final double discountValue;
  final double minOrderValue;
  final Timestamp? expiryDate;
  final bool isActive;

  CouponModel({
    required this.couponId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.isActive,
    this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'couponId': couponId,
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'isActive': isActive,
      'expiryDate': expiryDate,
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
    );
  }
}
