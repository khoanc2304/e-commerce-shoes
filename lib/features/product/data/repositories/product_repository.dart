import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  Future<List<ProductModel>> getProducts({
    String? brand,
    int? size,
    String? color,
    double? minPrice,
    double? maxPrice,
    String? sortBy, // "latest", "price_asc", "price_desc", "sales"
  }) async {
    try {
      Query query = _firestore.collection('products').where('isActive', isEqualTo: true);

      // Multi-conditional filtering
      if (brand != null && brand.isNotEmpty) {
        query = query.where('brand', isEqualTo: brand);
      }
      if (size != null) {
        query = query.where('availableSizes', arrayContains: size);
      }
      if (color != null && color.isNotEmpty) {
        query = query.where('colors', arrayContains: color);
      }
      if (minPrice != null) {
        query = query.where('basePrice', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        // Warning: Firestore has limitations with multiple inequality filters on different fields.
        // Assuming price filtering is the only inequality here.
        query = query.where('basePrice', isLessThanOrEqualTo: maxPrice);
      }

      // Sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'latest':
            query = query.orderBy('createdAt', descending: true);
            break;
          case 'price_asc':
            query = query.orderBy('basePrice', descending: false);
            break;
          case 'price_desc':
            query = query.orderBy('basePrice', descending: true);
            break;
          case 'sales':
            query = query.orderBy('salesCount', descending: true);
            break;
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Advanced Search & Filter locally in Dart to overcome Firestore limitations
  Future<List<ProductModel>> searchAndFilterProducts({
    String? searchQuery,
    List<String>? brands,
    List<int>? sizes,
    List<String>? colors,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy, // "latest", "price_asc", "price_desc", "sales"
  }) async {
    try {
      // 1. Fetch all active products
      final snapshot = await _firestore.collection('products').where('isActive', isEqualTo: true).get();
      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();

      // 2. Local Filtering
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        products = products.where((p) => p.name.toLowerCase().contains(query)).toList();
      }
      
      if (brands != null && brands.isNotEmpty) {
        products = products.where((p) => brands.any((b) => b.toLowerCase() == p.brand.toLowerCase())).toList();
      }
      
      if (sizes != null && sizes.isNotEmpty) {
        products = products.where((p) => p.availableSizes.any((s) => sizes.contains(s))).toList();
      }
      
      if (colors != null && colors.isNotEmpty) {
        products = products.where((p) => p.colors.any((c) => colors.contains(c))).toList();
      }
      
      if (minPrice != null) {
        products = products.where((p) => p.basePrice >= minPrice).toList();
      }
      
      if (maxPrice != null) {
        products = products.where((p) => p.basePrice <= maxPrice).toList();
      }
      
      if (minRating != null) {
        products = products.where((p) => p.averageRating >= minRating).toList();
      }

      // 3. Local Sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'latest':
            products.sort((a, b) {
              if (a.createdAt == null || b.createdAt == null) return 0;
              return b.createdAt!.compareTo(a.createdAt!);
            });
            break;
          case 'price_asc':
            products.sort((a, b) => a.basePrice.compareTo(b.basePrice));
            break;
          case 'price_desc':
            products.sort((a, b) => b.basePrice.compareTo(a.basePrice));
            break;
          case 'sales':
            products.sort((a, b) => b.salesCount.compareTo(a.salesCount));
            break;
        }
      }

      return products;
    } catch (e) {
      throw Exception('Failed to search and filter products: $e');
    }
  }

  Future<List<ReviewModel>> getReviews(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<void> addReview(String productId, ReviewModel review) async {
    final productRef = _firestore.collection('products').doc(productId);
    final reviewRef = productRef.collection('reviews').doc(review.reviewId);

    try {
      await _firestore.runTransaction((transaction) async {
        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw Exception("Product does not exist!");
        }

        final data = productDoc.data()!;
        final double currentAverage = (data['averageRating'] ?? 0.0).toDouble();
        final int currentReviewCount = data['reviewCount'] ?? 0;

        // Set the review document
        transaction.set(reviewRef, review.toMap());

        // Only affect average rating if the review actually has a rating > 0
        if (review.rating > 0) {
          final int newReviewCount = currentReviewCount + 1;
          final double newAverageRating =
              ((currentAverage * currentReviewCount) + review.rating) / newReviewCount;

          transaction.update(productRef, {
            'averageRating': newAverageRating,
            'reviewCount': newReviewCount,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Future<void> updateReview(String productId, ReviewModel oldReview, ReviewModel newReview) async {
    final productRef = _firestore.collection('products').doc(productId);
    final reviewRef = productRef.collection('reviews').doc(newReview.reviewId);

    try {
      await _firestore.runTransaction((transaction) async {
        final productDoc = await transaction.get(productRef);
        if (!productDoc.exists) throw Exception("Product does not exist!");

        final data = productDoc.data()!;
        double currentAverage = (data['averageRating'] ?? 0.0).toDouble();
        int currentReviewCount = data['reviewCount'] ?? 0;

        double totalRating = currentAverage * currentReviewCount;
        int ratedCount = currentReviewCount;

        // Remove old rating contribution
        if (oldReview.rating > 0) {
          totalRating -= oldReview.rating;
          ratedCount -= 1;
        }
        
        // Add new rating contribution
        if (newReview.rating > 0) {
          totalRating += newReview.rating;
          ratedCount += 1;
        }

        double newAverage = ratedCount > 0 ? totalRating / ratedCount : 0.0;

        transaction.update(productRef, {
          'averageRating': newAverage,
          'reviewCount': ratedCount,
        });
        transaction.update(reviewRef, newReview.toMap());
      });
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  Future<void> deleteReview(String productId, ReviewModel review) async {
    final productRef = _firestore.collection('products').doc(productId);
    final reviewRef = productRef.collection('reviews').doc(review.reviewId);

    try {
      await _firestore.runTransaction((transaction) async {
        final productDoc = await transaction.get(productRef);
        if (!productDoc.exists) return;

        final data = productDoc.data()!;
        double currentAverage = (data['averageRating'] ?? 0.0).toDouble();
        int currentReviewCount = data['reviewCount'] ?? 0;

        if (review.rating > 0) {
          int newReviewCount = currentReviewCount - 1;
          double newAverage = 0.0;
          if (newReviewCount > 0) {
            newAverage = ((currentAverage * currentReviewCount) - review.rating) / newReviewCount;
          }
          transaction.update(productRef, {
            'averageRating': newAverage,
            'reviewCount': newReviewCount,
          });
        }
        transaction.delete(reviewRef);
      });
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
}
