import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/voucher_repository.dart';
import '../../../voucher/data/models/coupon_model.dart';
import 'voucher_state.dart';

class VoucherCubit extends Cubit<VoucherState> {
  final VoucherRepository _voucherRepository;
  StreamSubscription<List<CouponModel>>? _vouchersSubscription;

  VoucherCubit({required VoucherRepository voucherRepository})
      : _voucherRepository = voucherRepository,
        super(VoucherInitial()) {
    _initVouchersStream();
  }

  void _initVouchersStream() {
    emit(VoucherLoading());
    _vouchersSubscription?.cancel();
    try {
      _vouchersSubscription = _voucherRepository.getCouponsStream().listen(
        (vouchers) {
          emit(VoucherLoaded(vouchers));
        },
        onError: (e) {
          emit(VoucherError(e.toString()));
        },
      );
    } catch (e) {
      emit(VoucherError(e.toString()));
    }
  }

  Future<void> createVoucher(CouponModel voucher) async {
    emit(VoucherLoading());
    try {
      await _voucherRepository.addCoupon(voucher);
      emit(const VoucherOperationSuccess("Voucher created successfully!"));
      // _initVouchersStream will push the new state automatically
    } catch (e) {
      emit(VoucherError(e.toString()));
    }
  }

  Future<void> updateVoucher(CouponModel voucher) async {
    emit(VoucherLoading());
    try {
      await _voucherRepository.updateCoupon(voucher);
      emit(const VoucherOperationSuccess("Voucher updated successfully!"));
    } catch (e) {
      emit(VoucherError(e.toString()));
    }
  }

  Future<void> toggleVoucherStatus(CouponModel voucher) async {
    emit(VoucherLoading());
    try {
      final updatedVoucher = CouponModel(
        couponId: voucher.couponId,
        code: voucher.code,
        discountType: voucher.discountType,
        discountValue: voucher.discountValue,
        minOrderValue: voucher.minOrderValue,
        expiryDate: voucher.expiryDate,
        maxUsage: voucher.maxUsage,
        usageCount: voucher.usageCount,
        isActive: !voucher.isActive, // toggle
      );
      await _voucherRepository.updateCoupon(updatedVoucher);
      // No success message needed for simple toggles
    } catch (e) {
      emit(VoucherError(e.toString()));
    }
  }

  Future<void> deleteVoucher(String couponId) async {
    emit(VoucherLoading());
    try {
      await _voucherRepository.deleteCoupon(couponId);
      emit(const VoucherOperationSuccess("Voucher deleted successfully!"));
    } catch (e) {
      emit(VoucherError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _vouchersSubscription?.cancel();
    return super.close();
  }
}
