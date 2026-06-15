import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/sign_in_screen.dart';
import '../../features/auth/presentation/pages/sign_up_screen.dart';
import '../../features/auth/presentation/pages/profile_screen.dart';
import '../../features/product/presentation/pages/home_dashboard_screen.dart';
import '../../features/cart/presentation/pages/cart_screen.dart';
import '../../features/orders/presentation/pages/order_history_screen.dart';
import '../../features/admin/presentation/pages/admin_dashboard_screen.dart';
import '../../features/admin/presentation/pages/admin_product_list_screen.dart';
import '../../features/admin/presentation/pages/admin_product_management.dart';
import '../../features/product/data/models/product_model.dart';

class AppRouter {
  // Pass the AuthCubit or Auth state stream here if doing real redirection
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (BuildContext context, GoRouterState state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) => const HomeDashboardScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (BuildContext context, GoRouterState state) {
          // Normally fetch userId from Auth context
          final userId = "mock_user_id"; 
          return CartScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (BuildContext context, GoRouterState state) {
          final userId = "mock_user_id";
          return OrderHistoryScreen(userId: userId);
        },
      ),
      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (BuildContext context, GoRouterState state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (BuildContext context, GoRouterState state) => const AdminProductListScreen(),
      ),
      GoRoute(
        path: '/admin/products/add_edit',
        builder: (BuildContext context, GoRouterState state) {
          final product = state.extra as ProductModel?;
          return AdminProductManagement(product: product);
        },
      ),
    ],
    // redirect: (context, state) {
    //   // Implement role-based redirection here based on Auth state
    //   return null;
    // },
  );
}
