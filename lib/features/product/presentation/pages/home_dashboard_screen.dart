import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../cubit/user_activity_cubit.dart';
import '../cubit/user_activity_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../chat/data/repositories/chat_repository.dart';
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
    'https://imgs.search.brave.com/ot_sX4oy2xaQQjAZXYyb8NxAsk_K55DfyOl7McCq8tY/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/cHNkLWNhby1jYXAv/Ym8tc3V1LXRhcC1n/aWF5LW1vaS1tYXUt/YmFubmVyLXRyYW5n/LWJpYS1mYWNlYm9v/ay1kb2MtcXV5ZW4t/dHJlbi1tYW5nLXhh/LWhvaV80ODQ2Mjct/MjAwLmpwZz9zZW10/PWFpc19oeWJyaWQm/dz03NDAmcT04MA',
    'https://imgs.search.brave.com/sjaFjQgA1Nbbhmad44cL6pmVGWJeaun-gVboDGBkyLg/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/cHNkLWNhby1jYXAv/bWF1LWJhbm5lci13/ZWItdHJlbi1mYWNl/Ym9vay12YS1iYWkt/ZGFuZy10cmVuLWlu/c3RhZ3JhbS10cmVu/LW1hbmcteGEtaG9p/LXZlLWdpYXktdGhl/LXRoYW8tZ2lhbS1n/aWFfNzAwNTUtOTU4/LmpwZz9zZW10PWFp/c19oeWJyaWQmdz03/NDAmcT04MA',
    'https://imgs.search.brave.com/Khqiez6JsjqfZ5D7mvrXGvqqVu9qGQs0dq2gKqK9n5I/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/cHNkLWNhby1jYXAv/bWF1LWJhbm5lci13/ZWItdHJlbi1mYWNl/Ym9vay12YS1iYWkt/ZGFuZy10cmVuLWlu/c3RhZ3JhbS10cmVu/LW1hbmcteGEtaG9p/LXZlLWdpYXktdGhl/LXRoYW8tZ2lhbS1n/aWFfNzAwNTUtMTQw/Ni5qcGc_c2VtdD1h/aXNfaHlicmlkJnc9/NzQwJnE9ODA',
    'https://imgs.search.brave.com/A4mQOJMCgidPufH1Tu4GJS-BdLF0dvd7w8BBSI3TLZI/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pLnBp/bmltZy5jb20vb3Jp/Z2luYWxzLzA1LzMy/LzcwLzA1MzI3MDIz/MzliOTM2OGYxOTk3/Mzk2N2MwNGIxN2I5/LmpwZw',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    
    // Load recently viewed for the current user
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<UserActivityCubit>().loadRecentlyViewed(authState.user.uid);
    }
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
                  autoPlayInterval: const Duration(seconds: 2),
                  enlargeCenterPage: true,
                  viewportFraction: 0.85,
                ),
                items: _banners.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width,
                        ),
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
                                    context.go('/home/product', extra: product);
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
                            context.go('/home/product', extra: product);
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
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
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: BlocBuilder<AuthCubit, AuthState>(
                                          builder: (context, authState) {
                                            if (authState is AuthAuthenticated) {
                                              return CircleAvatar(
                                                backgroundColor: Colors.white70,
                                                radius: 16,
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: const Icon(Icons.share, size: 16, color: Colors.black87),
                                                  onPressed: () async {
                                                    try {
                                                      await ChatRepository().sendMessage(
                                                        customerId: authState.user.uid,
                                                        customerName: authState.user.fullName,
                                                        customerEmail: authState.user.email,
                                                        text: 'Hi Admin, I have a question about this product.',
                                                        senderId: authState.user.uid,
                                                        senderName: authState.user.fullName,
                                                        isAdmin: false,
                                                        productPayload: {
                                                          'productId': product.productId,
                                                          'name': product.name,
                                                          'price': product.basePrice,
                                                          'imageUrl': product.images.isNotEmpty ? product.images.first : '',
                                                        },
                                                      );
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product shared to chat!')));
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
                                                      }
                                                    }
                                                  },
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                    ],
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          BlocBuilder<UserActivityCubit, UserActivityState>(
            builder: (context, state) {
              if (state.compareList.isEmpty) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  heroTag: 'compare_fab',
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
