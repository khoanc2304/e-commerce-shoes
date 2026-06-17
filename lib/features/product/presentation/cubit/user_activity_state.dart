import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';

class UserActivityState extends Equatable {
  final List<ProductModel> recentlyViewed;
  final List<ProductModel> compareList;

  const UserActivityState({
    this.recentlyViewed = const [],
    this.compareList = const [],
  });

  UserActivityState copyWith({
    List<ProductModel>? recentlyViewed,
    List<ProductModel>? compareList,
  }) {
    return UserActivityState(
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      compareList: compareList ?? this.compareList,
    );
  }

  @override
  List<Object> get props => [recentlyViewed, compareList];
}
