import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import 'user_activity_state.dart';

class UserActivityCubit extends Cubit<UserActivityState> {
  UserActivityCubit() : super(const UserActivityState());

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
  }

  void removeRecent(String productId) {
    final updatedList = List<ProductModel>.from(state.recentlyViewed);
    updatedList.removeWhere((p) => p.productId == productId);
    emit(state.copyWith(recentlyViewed: updatedList));
  }

  void clearRecent() {
    emit(state.copyWith(recentlyViewed: []));
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
