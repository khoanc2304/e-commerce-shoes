import 'package:equatable/equatable.dart';
import '../../../orders/data/models/order_model.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminAnalyticsLoaded extends AdminState {
  final List<OrderModel> completedOrders;
  final double totalRevenue;

  const AdminAnalyticsLoaded(this.completedOrders, this.totalRevenue);

  @override
  List<Object?> get props => [completedOrders, totalRevenue];
}

class AdminOperationSuccess extends AdminState {
  final String message;

  const AdminOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
