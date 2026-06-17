import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/product_model.dart';
import 'user_activity_state.dart';

class UserActivityCubit extends Cubit<UserActivityState> {
  String? _currentUserId;

  UserActivityCubit() : super(const UserActivityState());

  Future<void> loadRecentlyViewed(String userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('recently_viewed_$_currentUserId');
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final list = jsonList.map((e) => ProductModel.fromMap(e as Map<String, dynamic>, e['productId'] ?? '')).toList();
        emit(state.copyWith(recentlyViewed: list));
      } catch (e) {
        emit(state.copyWith(recentlyViewed: []));
      }
    } else {
      emit(state.copyWith(recentlyViewed: []));
    }
  }

  Future<void> _saveRecentlyViewed(List<ProductModel> list) async {
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((product) => {
      'productId': product.productId,
      'name': product.name,
      'brand': product.brand,
      'basePrice': product.basePrice,
      'description': product.description,
      'images': product.images,
      'availableSizes': product.availableSizes,
      'colors': product.colors,
      'stock': product.stock,
      'salesCount': product.salesCount,
      'averageRating': product.averageRating,
      'reviewCount': product.reviewCount,
      'isActive': product.isActive,
    }).toList();
    await prefs.setString('recently_viewed_$_currentUserId', jsonEncode(jsonList));
  }

  // --- Recently Viewed ---
  void addToRecent(ProductModel product) {
    // Remove if already exists to move it to the front
    final updatedList = List<ProductModel>.from(state.recentlyViewed);
    updatedList.removeWhere((p) => p.productId == product.productId);
    
    // Add to front
    updatedList.insert(0, product);
    
    // Limit to 10 items
    if (updatedList.length > 10) {
      updatedList.removeLast();
    }
    
    emit(state.copyWith(recentlyViewed: updatedList));
    _saveRecentlyViewed(updatedList);
  }

  void removeRecent(String productId) {
    final updatedList = List<ProductModel>.from(state.recentlyViewed);
    updatedList.removeWhere((p) => p.productId == productId);
    emit(state.copyWith(recentlyViewed: updatedList));
    _saveRecentlyViewed(updatedList);
  }

  void clearRecent() {
    emit(state.copyWith(recentlyViewed: []));
    _saveRecentlyViewed([]);
  }

  // --- Compare ---
  void toggleCompare(ProductModel product) {
    final updatedList = List<ProductModel>.from(state.compareList);
    
    final existingIndex = updatedList.indexWhere((p) => p.productId == product.productId);
    if (existingIndex >= 0) {
      // Remove if already in compare list
      updatedList.removeAt(existingIndex);
    } else {
      // Add to compare list, max 2
      if (updatedList.length < 2) {
        updatedList.add(product);
      } else {
        // If already 2, replace the first one (or throw error, but replacing is better UX)
        updatedList[0] = updatedList[1];
        updatedList[1] = product;
      }
    }
    
    emit(state.copyWith(compareList: updatedList));
  }
  
  void clearCompare() {
    emit(state.copyWith(compareList: []));
  }
}
