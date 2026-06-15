import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/services/multi_imgbb_service.dart';
import '../../../product/data/models/product_model.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final AdminRepository _adminRepository;
  final MultiImgBBService _multiImgBBService;

  AdminCubit({
    required AdminRepository adminRepository,
    required MultiImgBBService multiImgBBService,
  })  : _adminRepository = adminRepository,
        _multiImgBBService = multiImgBBService,
        super(AdminInitial());

  Future<void> loadAnalytics() async {
    emit(AdminLoading());
    try {
      final orders = await _adminRepository.getCompletedOrders();
      final totalRevenue = orders.fold(0.0, (sum, order) => sum + order.totalPrice);
      emit(AdminAnalyticsLoaded(orders, totalRevenue));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> createProductWithImages(ProductModel product, List<File> imageFiles) async {
    emit(AdminLoading());
    try {
      // 1. Upload Images
      final imageUrls = await _multiImgBBService.uploadImages(imageFiles);
      
      // 2. Attach URLs to Product
      final newProduct = ProductModel(
        productId: product.productId,
        name: product.name,
        brand: product.brand,
        basePrice: product.basePrice,
        description: product.description,
        images: imageUrls,
        availableSizes: product.availableSizes,
        colors: product.colors,
        stock: product.stock,
        salesCount: 0,
        averageRating: 0.0,
        reviewCount: 0,
        createdAt: product.createdAt,
      );

      // 3. Save to Firestore
      await _adminRepository.addProduct(newProduct);
      
      emit(const AdminOperationSuccess("Product created successfully!"));
      // Reload analytics or return to initial
      loadAnalytics(); 
    } catch (e) {
      emit(AdminError(e.toString()));
      loadAnalytics(); 
    }
  }
}
