import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/models/cart_model.dart';
import '../../../voucher/data/models/coupon_model.dart';
import '../../../voucher/data/repositories/voucher_repository.dart';
import '../../../orders/data/repositories/order_repository.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartRepository _cartRepository;
  final OrderRepository _orderRepository;
  final VoucherRepository _voucherRepository;

  CouponModel? appliedCoupon;

  CartCubit({
    required CartRepository cartRepository,
    required OrderRepository orderRepository,
    required VoucherRepository voucherRepository,
  })  : _cartRepository = cartRepository,
        _orderRepository = orderRepository,
        _voucherRepository = voucherRepository,
        super(CartInitial());

  Stream<CartModel?> getCartStream(String userId) {
    return _cartRepository.getCartStream(userId);
  }

  Future<void> addToCart(String userId, CartItemModel newItem) async {
    try {
      await _cartRepository.addToCart(userId, newItem);
      emit(const CartOperationSuccess("Item added to cart!"));
    } catch (e) {
      emit(CartError("Failed to add to cart: $e"));
    }
  }

  Future<void> updateQuantity(String userId, String productId, int size, String color, int newQuantity) async {
    if (newQuantity < 1) return;
    try {
      await _cartRepository.updateCartItemQuantity(userId, productId, size, color, newQuantity);
    } catch (e) {
      emit(CartError("Failed to update quantity: $e"));
    }
  }

  Future<void> removeItem(String userId, String productId, int size, String color) async {
    try {
      await _cartRepository.removeCartItem(userId, productId, size, color);
      emit(const CartOperationSuccess("Item removed from cart."));
    } catch (e) {
      emit(CartError("Failed to remove item: $e"));
    }
  }

  Future<void> applyCoupon(String code, double currentSubtotal) async {
    // Use CartCouponLoading — NOT CartLoading — so the Checkout button
    // stays enabled while the coupon is being validated.
    emit(CartCouponLoading());
    try {
      final coupon = await _voucherRepository.validateCoupon(code, currentSubtotal);
      if (coupon != null) {
        appliedCoupon = coupon;
        final discountAmount = coupon.calculateDiscount(currentSubtotal);
        emit(CartCouponApplied(coupon, discountAmount: discountAmount));
      }
    } catch (e) {
      appliedCoupon = null;
      emit(CartError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  void removeCoupon() {
    appliedCoupon = null;
    emit(const CartOperationSuccess("Coupon removed."));
  }

  Future<void> checkout({
    required String userId,
    required String customerName,
    required String email,
    required Map<String, dynamic> shippingAddress,
    required List<CartItemModel> cartItems,
    required double subTotal,
    required double discountAmount,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    emit(CartLoading());
    try {
      final orderId = await _orderRepository.executeCheckout(
        userId: userId,
        customerName: customerName,
        email: email,
        shippingAddress: shippingAddress,
        cartItems: cartItems,
        subTotal: subTotal,
        discountAmount: discountAmount,
        totalPrice: totalPrice,
        voucherApplied: appliedCoupon?.code,
        paymentMethod: paymentMethod,
      );

      // Increment coupon usage count atomically after successful checkout
      if (appliedCoupon != null) {
        try {
          await _voucherRepository.incrementCouponUsage(appliedCoupon!.couponId);
        } catch (_) {
          // Non-critical — don't fail the checkout if increment fails
        }
      }

      // Reset local coupon state after successful checkout
      appliedCoupon = null;
      emit(CartCheckoutSuccess(orderId: orderId, paymentMethod: paymentMethod));
    } catch (e) {
      emit(CartError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> restoreCart(String userId, List<CartItemModel> items) async {
    try {
      await _cartRepository.restoreCart(userId, items);
      emit(const CartOperationSuccess("Cart restored."));
    } catch (e) {
      emit(CartError("Failed to restore cart: $e"));
    }
  }
}
