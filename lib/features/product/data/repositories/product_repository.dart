import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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

        // Calculate new average rating
        final int newReviewCount = currentReviewCount + 1;
        final double newAverageRating =
            ((currentAverage * currentReviewCount) + review.rating) / newReviewCount;

        // Set the review document
        transaction.set(reviewRef, review.toMap());

        // Update the product document
        transaction.update(productRef, {
          'averageRating': newAverageRating,
          'reviewCount': newReviewCount,
        });
      });
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }
}
