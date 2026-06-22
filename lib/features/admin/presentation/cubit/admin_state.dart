import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../product/data/models/product_model.dart';

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

class AdminProductsLoaded extends AdminState {
  final List<ProductModel> products;
  final bool hasReachedMax;
  final DocumentSnapshot? lastDocument;

  const AdminProductsLoaded(
    this.products, {
    this.hasReachedMax = false,
    this.lastDocument,
  });

  @override
  List<Object?> get props => [products, hasReachedMax, lastDocument];
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
