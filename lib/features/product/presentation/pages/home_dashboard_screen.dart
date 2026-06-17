import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../cubit/user_activity_cubit.dart';
import '../cubit/user_activity_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../cart/data/models/cart_model.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import 'product_detail_screen.dart';
import 'package:go_router/go_router.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final List<String> _brands = ['All', 'Nike', 'Adidas', 'Puma', 'Vans', 'Converse'];
  String _selectedBrand = 'All';

  final List<String> _banners = [
    'https://i.ibb.co/banner1.jpg', // Placeholder
    'https://i.ibb.co/banner2.jpg',
    'https://i.ibb.co/banner3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() {
    context.read<ProductCubit>().loadProducts(
      brand: _selectedBrand == 'All' ? null : _selectedBrand,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shues X', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.push('/search');
            },
          ),
          if (authState is AuthAuthenticated)
            StreamBuilder<CartModel?>(
              stream: context.read<CartCubit>().getCartStream(authState.user.uid),
              builder: (context, snapshot) {
                final int itemCount = snapshot.data?.items.length ?? 0;
                return IconButton(
                  icon: Badge(
                    label: Text(itemCount.toString()),
                    isLabelVisible: itemCount > 0,
                    child: const Icon(Icons.shopping_cart),
                  ),
                  tooltip: 'Cart',
                  onPressed: () {
                    context.push('/cart');
                  },
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Cart',
              onPressed: () {
                context.push('/cart');
              },
            ),
          if (authState is AuthAuthenticated)
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'My Orders',
              onPressed: () {
                context.push('/orders');
              },
            ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              context.push('/profile');
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
              tooltip: 'Go to Admin',
              onPressed: () {
                context.push('/admin');
              },
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Banners
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 150.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.85,
                ),
                items: _banners.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Banner Ad', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Recently Viewed Section
          SliverToBoxAdapter(
            child: BlocBuilder<UserActivityCubit, UserActivityState>(
              builder: (context, state) {
                if (state.recentlyViewed.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recently Viewed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => context.read<UserActivityCubit>().clearRecent(),
                            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.recentlyViewed.length,
                        itemBuilder: (context, index) {
                          final product = state.recentlyViewed[index];
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(product: product),
                                      ),
                                    ).then((_) => _fetchProducts());
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                            child: product.images.isNotEmpty
                                                ? Image.network(product.images.first, fit: BoxFit.cover)
                                                : const Icon(Icons.image, color: Colors.grey),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(
                                            product.name,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      context.read<UserActivityCubit>().removeRecent(product.productId);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),

          // Brand Filter
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _brands.length,
                itemBuilder: (context, index) {
                  final brand = _brands[index];
                  final isSelected = _selectedBrand == brand;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(brand),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedBrand = brand;
                        });
                        _fetchProducts();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Products Grid
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is ProductError) {
                  return SliverFillRemaining(
                    child: Center(child: Text(state.message)),
                  );
                } else if (state is ProductsLoaded) {
                  final products = state.products;
                  if (products.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No products found')),
                    );
                  }
                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: product),
                              ),
                            ).then((_) => _fetchProducts());
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    child: product.images.isEmpty
                                        ? const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))
                                        : ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            child: Image.network(product.images.first, fit: BoxFit.cover, width: double.infinity),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text('\$${product.basePrice.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, size: 14, color: Colors.orange),
                                          Text('${product.averageRating.toStringAsFixed(1)} (${product.reviewCount})', style: const TextStyle(fontSize: 12)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: products.length,
                    ),
                  );
                }
                return const SliverFillRemaining(child: SizedBox());
              },
            ),
          )
        ],
      ),
      floatingActionButton: BlocBuilder<UserActivityCubit, UserActivityState>(
        builder: (context, state) {
          if (state.compareList.isEmpty) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: () {
              if (state.compareList.length == 2) {
                context.push('/compare', extra: {
                  'product1': state.compareList[0],
                  'product2': state.compareList[1],
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select one more product to compare.')),
                );
              }
            },
            backgroundColor: state.compareList.length == 2 ? Theme.of(context).primaryColor : Colors.orange,
            child: Badge(
              label: Text(state.compareList.length.toString()),
              child: const Icon(Icons.compare_arrows),
            ),
          );
        },
      ),
    );
  }
}
