import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../cart/data/models/cart_model.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../product/presentation/cubit/product_cubit.dart';
import '../../../product/presentation/pages/home_dashboard_screen.dart';
import '../../../chat/presentation/widgets/chat_bubble_overlay.dart';

class MainLayoutScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({Key? key, required this.navigationShell})
      : super(key: key);

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  final _chatRepository = ChatRepository();

  void _goBranch(int index) {
    if (index == 0) {
      homeDashboardKey.currentState?.fetchProducts();
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.role == 'admin';
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return Scaffold(
      body: Stack(
        children: [
          widget.navigationShell,
          if (widget.navigationShell.currentIndex != 3)
            const ChatBubbleOverlay(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: authState is AuthAuthenticated
                ? StreamBuilder<CartModel?>(
                    stream: context.read<CartCubit>().getCartStream(userId),
                    builder: (context, snapshot) {
                      final itemCount = snapshot.data?.items.length ?? 0;
                      return Badge(
                        label: Text(itemCount.toString()),
                        isLabelVisible: itemCount > 0,
                        child: const Icon(Icons.shopping_cart_outlined),
                      );
                    },
                  )
                : const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: authState is AuthAuthenticated
                ? StreamBuilder<int>(
                    stream: isAdmin
                        ? _chatRepository.getUnreadAdminChatsCountStream()
                        : _chatRepository.getUnreadCustomerMessagesCountStream(userId),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return Badge(
                        label: Text(unreadCount.toString()),
                        isLabelVisible: unreadCount > 0,
                        child: const Icon(Icons.chat_bubble_outline),
                      );
                    },
                  )
                : const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
