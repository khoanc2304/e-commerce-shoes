import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;

  ProductCubit({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(ProductInitial());

  Future<void> loadProducts({
    String? brand,
    int? size,
    String? color,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    emit(ProductLoading());
    try {
      final products = await _productRepository.getProducts(
        brand: brand,
        size: size,
        color: color,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
      );
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> loadProductReviews(ProductModel product) async {
    emit(ProductLoading());
    try {
      final reviews = await _productRepository.getReviews(product.productId);
      emit(ProductReviewsLoaded(product, reviews));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> addReview(ProductModel product, ReviewModel review) async {
    emit(ProductLoading());
    try {
      await _productRepository.addReview(product.productId, review);
      // Reload reviews after adding
      final reviews = await _productRepository.getReviews(product.productId);
      
      // Calculate updated local product logic since we don't have the updated product from firestore yet easily
      // A better way is to refetch the single product, but for UI sake, we just reload the reviews.
      emit(ProductReviewsLoaded(product, reviews));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
