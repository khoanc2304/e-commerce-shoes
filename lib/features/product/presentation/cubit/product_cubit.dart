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
      final result = await _productRepository.getProducts(
        brand: brand,
        size: size,
        color: color,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
      );
      emit(ProductsLoaded(
        result.$1,
        hasReachedMax: result.$1.length < 10,
        lastDocument: result.$2,
      ));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> searchProducts({
    String? searchQuery,
    List<String>? brands,
    List<int>? sizes,
    List<String>? colors,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
  }) async {
    emit(ProductLoading());
    try {
      final products = await _productRepository.searchAndFilterProducts(
        searchQuery: searchQuery,
        brands: brands,
        sizes: sizes,
        colors: colors,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        sortBy: sortBy,
      );
      emit(ProductsLoaded(products, hasReachedMax: true, lastDocument: null));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> loadMoreProducts({
    String? brand,
    int? size,
    String? color,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    if (state is ProductsLoaded) {
      final currentState = state as ProductsLoaded;
      if (currentState.hasReachedMax) return;

      try {
        final result = await _productRepository.getProducts(
          brand: brand,
          size: size,
          color: color,
          minPrice: minPrice,
          maxPrice: maxPrice,
          sortBy: sortBy,
          startAfter: currentState.lastDocument,
        );

        if (result.$1.isEmpty) {
          emit(ProductsLoaded(
            currentState.products,
            hasReachedMax: true,
            lastDocument: currentState.lastDocument,
          ));
        } else {
          emit(ProductsLoaded(
            currentState.products + result.$1,
            hasReachedMax: result.$1.length < 10,
            lastDocument: result.$2,
          ));
        }
      } catch (e) {
        emit(ProductError(e.toString()));
      }
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
