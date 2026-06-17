import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/sign_in_screen.dart';
import '../../features/auth/presentation/pages/sign_up_screen.dart';
import '../../features/auth/presentation/pages/profile_screen.dart';
import '../../features/product/presentation/pages/home_dashboard_screen.dart';
import '../../features/cart/presentation/pages/cart_screen.dart';
import '../../features/orders/presentation/pages/user_orders_screen.dart';
import '../../features/admin/presentation/pages/admin_dashboard_screen.dart';
import '../../features/admin/presentation/pages/admin_product_list_screen.dart';
import '../../features/admin/presentation/pages/admin_product_management.dart';
import '../../features/admin/presentation/pages/admin_orders_screen.dart';
import '../../features/admin/presentation/pages/admin_chat_hub_screen.dart';
import '../../features/admin/presentation/pages/admin_chat_screen.dart';
import '../../features/chat/presentation/pages/customer_chat_screen.dart';
import '../../features/main_layout/presentation/pages/main_layout_screen.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/presentation/pages/product_detail_screen.dart';
import '../../features/product/presentation/pages/search_filter_screen.dart';
import '../../features/product/presentation/pages/product_comparison_screen.dart';

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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayoutScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            initialLocation: '/home',
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'product',
                    builder: (context, state) {
                      final product = state.extra as ProductModel;
                      return ProductDetailScreen(product: product);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/cart',
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/orders',
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is! AuthAuthenticated) return const Scaffold(body: Center(child: Text('Login required')));
                  return const UserOrdersScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/chat',
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) {
                  final authState = context.read<AuthCubit>().state;
                  final isAdmin = authState is AuthAuthenticated && authState.user.role == 'admin';
                  return isAdmin ? const AdminChatHubScreen() : const CustomerChatScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/profile',
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
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
        path: '/admin/orders',
        builder: (BuildContext context, GoRouterState state) => const AdminOrdersScreen(),
      ),
      // Admin Chat Detail (AdminChatHubScreen is now at /chat)
      GoRoute(
        path: '/admin/chats/:id',
        builder: (BuildContext context, GoRouterState state) {
          final customerId = state.pathParameters['id']!;
          final customerName = state.extra as String? ?? 'Customer';
          return AdminChatScreen(customerId: customerId, customerName: customerName);
        },
      ),
      GoRoute(
        path: '/admin/products/add_edit',
        builder: (BuildContext context, GoRouterState state) {
          final product = state.extra as ProductModel?;
          return AdminProductManagement(product: product);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (BuildContext context, GoRouterState state) => const SearchFilterScreen(),
      ),
      GoRoute(
        path: '/compare',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra as Map<String, dynamic>;
          return ProductComparisonScreen(
            product1: extra['product1'] as ProductModel,
            product2: extra['product2'] as ProductModel,
          );
        },
      ),
    ],
    // redirect: (context, state) {
    //   // Implement role-based redirection here based on Auth state
    //   return null;
    // },
  );
}
