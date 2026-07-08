import 'package:equatable/equatable.dart';
import '../../../voucher/data/models/coupon_model.dart';

abstract class VoucherState extends Equatable {
  const VoucherState();

  @override
  List<Object?> get props => [];
}

class VoucherInitial extends VoucherState {}

class VoucherLoading extends VoucherState {}

class VoucherLoaded extends VoucherState {
  final List<CouponModel> vouchers;

  const VoucherLoaded(this.vouchers);

  @override
  List<Object?> get props => [vouchers];
}

class VoucherOperationSuccess extends VoucherState {
  final String message;

  const VoucherOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class VoucherError extends VoucherState {
  final String message;

  const VoucherError(this.message);

  @override
  List<Object?> get props => [message];
}
