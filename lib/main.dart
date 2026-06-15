import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';

import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/services/imgbb_service.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

import 'features/cart/data/repositories/cart_repository.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';

import 'features/orders/data/repositories/order_repository.dart';
import 'features/orders/presentation/cubit/order_cubit.dart';

import 'features/admin/data/repositories/admin_repository.dart';
import 'features/admin/data/services/multi_imgbb_service.dart';
import 'features/admin/presentation/cubit/admin_cubit.dart';

import 'features/product/data/repositories/product_repository.dart';
import 'features/product/presentation/cubit/product_cubit.dart';

import 'features/chat/data/repositories/chat_repository.dart';
import 'features/chat/presentation/cubit/chat_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  // Initialize Data Layer Dependencies
  final authRepository = AuthRepository();
  final imgBBService = ImgBBService();
  final orderRepository = OrderRepository();
  final cartRepository = CartRepository();
  final adminRepository = AdminRepository();
  final multiImgBBService = MultiImgBBService();
  final productRepository = ProductRepository();
  final chatRepository = ChatRepository();

  runApp(ShuesXApp(
    authRepository: authRepository,
    imgBBService: imgBBService,
    cartRepository: cartRepository,
    orderRepository: orderRepository,
    adminRepository: adminRepository,
    multiImgBBService: multiImgBBService,
    productRepository: productRepository,
    chatRepository: chatRepository,
  ));
}

class ShuesXApp extends StatelessWidget {
  final AuthRepository authRepository;
  final ImgBBService imgBBService;
  final CartRepository cartRepository;
  final OrderRepository orderRepository;
  final AdminRepository adminRepository;
  final MultiImgBBService multiImgBBService;
  final ProductRepository productRepository;
  final ChatRepository chatRepository;

  const ShuesXApp({
    super.key,
    required this.authRepository,
    required this.imgBBService,
    required this.cartRepository,
    required this.orderRepository,
    required this.adminRepository,
    required this.multiImgBBService,
    required this.productRepository,
    required this.chatRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(
            authRepository: authRepository,
            imgBBService: imgBBService,
          ),
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(
            cartRepository: cartRepository,
            orderRepository: orderRepository,
          ),
        ),
        BlocProvider<OrderCubit>(
          create: (context) => OrderCubit(
            orderRepository: orderRepository,
          ),
        ),
        BlocProvider<AdminCubit>(
          create: (context) => AdminCubit(
            adminRepository: adminRepository,
            multiImgBBService: multiImgBBService,
          ),
        ),
        BlocProvider<ProductCubit>(
          create: (context) => ProductCubit(
            productRepository: productRepository,
          ),
        ),
        BlocProvider<ChatCubit>(
          create: (context) => ChatCubit(
            chatRepository: chatRepository,
          ),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Shues X',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
