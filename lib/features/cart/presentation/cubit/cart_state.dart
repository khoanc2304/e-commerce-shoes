import 'package:equatable/equatable.dart';
import '../../data/models/coupon_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartOperationSuccess extends CartState {
  final String message;
  const CartOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CartCouponApplied extends CartState {
  final CouponModel coupon;
  const CartCouponApplied(this.coupon);

  @override
  List<Object?> get props => [coupon];
}

class CartCheckoutSuccess extends CartState {}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
