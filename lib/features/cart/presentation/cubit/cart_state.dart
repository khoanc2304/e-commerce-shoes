import 'package:equatable/equatable.dart';
import '../../../voucher/data/models/coupon_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

/// Full-screen loading state — used during checkout / heavy operations.
/// Disables the Checkout button.
class CartLoading extends CartState {}

/// Lightweight loading state — used ONLY while validating a coupon code.
/// Does NOT disable the Checkout button.
class CartCouponLoading extends CartState {}

class CartOperationSuccess extends CartState {
  final String message;
  const CartOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CartCouponApplied extends CartState {
  final CouponModel coupon;
  /// Pre-computed discount amount based on the subtotal at apply time.
  final double discountAmount;

  const CartCouponApplied(this.coupon, {required this.discountAmount});

  @override
  List<Object?> get props => [coupon, discountAmount];
}

class CartCheckoutSuccess extends CartState {
  final String orderId;
  final String paymentMethod;
  const CartCheckoutSuccess({required this.orderId, required this.paymentMethod});

  @override
  List<Object?> get props => [orderId, paymentMethod];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
