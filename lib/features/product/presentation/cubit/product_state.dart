import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<ProductModel> products;
  final bool hasReachedMax;
  final DocumentSnapshot? lastDocument;

  const ProductsLoaded(
    this.products, {
    this.hasReachedMax = false,
    this.lastDocument,
  });

  @override
  List<Object?> get props => [products, hasReachedMax, lastDocument];
}

class ProductReviewsLoaded extends ProductState {
  final ProductModel product;
  final List<ReviewModel> reviews;

  const ProductReviewsLoaded(this.product, this.reviews);

  @override
  List<Object?> get props => [product, reviews];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
