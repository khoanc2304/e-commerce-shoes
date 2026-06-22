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
import '../../../../core/widgets/custom_image_view.dart';

final GlobalKey<HomeDashboardScreenState> homeDashboardKey = GlobalKey<HomeDashboardScreenState>();

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => HomeDashboardScreenState();
}

class HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final List<String> _brands = ['All', 'Nike', 'Adidas', 'Puma', 'Vans', 'Converse'];
  String _selectedBrand = 'All';
  final ScrollController _scrollController = ScrollController();

  final List<String> _banners = [
    'https://imgs.search.brave.com/ot_sX4oy2xaQQjAZXYyb8NxAsk_K55DfyOl7McCq8tY/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/cHNkLWNhby1jYXAv/Ym8tc3V1LXRhcC1n/aWF5LW1vaS1tYXUt/YmFubmVyLXRyYW5n/LWJpYS1mYWNlYm9v/ay1kb2MtcXV5ZW4t/dHJlbi1tYW5nLXhh/LWhvaV80ODQ2Mjct/MjAwLmpwZz9zZW10/PWFpc19oeWJyaWQm/dz03NDAmcT04MA',
    'https://imgs.search.brave.com/sjaFjQgA1Nbbhmad44cL6pmVGWJeaun-gVboDGBkyLg/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/cHNkLWNhby1jYXAv/bWF1LWJhbm5lci13/ZWItdHJlbi1mYWNl/Ym9vay12YS1iYWkt/ZGFuZy10cmVuLWlu/c3RhZ3JhbS10cmVu/LW1hbmcteGEtaG9p/LXZlLWdpYXktdGhl/LXRoYW8tZ2lhbS1n/aWFfNzAwNTUtOTU4/LmpwZz9zZW10PWFp/c19oeWJyaWQmdz03/NDAmcT04MA',
    'https://imgs.search.brave.com/Khqiez6JsjqfZ5D7mvrXGvqqVu9qGQs0dq2gKqK9n5I/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/cHNkLWNhby1jYXAv/bWF1LWJhbm5lci13/ZWItdHJlbi1mYWNl/Ym9vay12YS1iYWkt/ZGFuZy10cmVuLWlu/c3RhZ3JhbS10cmVu/LW1hbmcteGEtaG9p/LXZlLWdpYXktdGhl/LXRoYW8tZ2lhbS1n/aWFfNzAwNTUtMTQw/Ni5qcGc_c2VtdD1h/aXNfaHlicmlkJnc9/NzQwJnE9ODA',
    'https://imgs.search.brave.com/A4mQOJMCgidPufH1Tu4GJS-BdLF0dvd7w8BBSI3TLZI/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pLnBp/bmltZy5jb20vb3Jp/Z2luYWxzLzA1LzMy/LzcwLzA1MzI3MDIz/MzliOTM2OGYxOTk3/Mzk2N2MwNGIxN2I5/LmpwZw',
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
    
    // Load recently viewed for the current user
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<UserActivityCubit>().loadRecentlyViewed(authState.user.uid);
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<ProductCubit>().loadMoreProducts(
          brand: _selectedBrand == 'All' ? null : _selectedBrand,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void fetchProducts() {
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
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (isAdmin)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: Colors.redAccent, size: 22),
                tooltip: 'Go to Admin',
                onPressed: () {
                  context.push('/admin');
                },
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            fetchProducts();
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
            // Header chào mừng cao cấp
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome to Shoes X,',
                          style: TextStyle(
                            color: Color(0xFF8E8E9E),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authState is AuthAuthenticated ? authState.user.fullName : 'Guest User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1B2D),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEEEEF4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                          ]
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).primaryColor,
                          backgroundImage: (authState is AuthAuthenticated && authState.user.avatarUrl.isNotEmpty)
                              ? NetworkImage(authState.user.avatarUrl)
                              : null,
                          child: (authState is AuthAuthenticated && authState.user.avatarUrl.isNotEmpty)
                              ? null
                              : Text(
                                  authState is AuthAuthenticated 
                                      ? authState.user.fullName[0].toUpperCase() 
                                      : 'G',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Thanh tìm kiếm (Search Bar) bo tròn sang trọng
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEEEEF4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        )
                      ]
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF8E8E9E), size: 22),
                        const SizedBox(width: 14),
                        const Text(
                          'Search your favorite sneakers...',
                          style: TextStyle(
                            color: Color(0xFF8E8E9E),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.tune, color: Theme.of(context).primaryColor, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Banner Carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 160.0,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    enlargeCenterPage: true,
                    viewportFraction: 0.9,
                  ),
                  items: _banners.map((url) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: CustomImageView(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              width: MediaQuery.of(context).size.width,
                            ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recently Viewed', 
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1B2D))
                            ),
                            TextButton(
                              onPressed: () => context.read<UserActivityCubit>().clearRecent(),
                              child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: state.recentlyViewed.length,
                          itemBuilder: (context, index) {
                            final product = state.recentlyViewed[index];
                            return Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 14),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      context.go('/home/product', extra: product);
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 80,
                                          width: 80,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F5F9),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFFEEEEF4), width: 1.2),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: product.images.isNotEmpty
                                                ? CustomImageView(
                                                    imageUrl: product.images.first,
                                                    fit: BoxFit.cover,
                                                  )
                                                : const Icon(Icons.image, color: Colors.grey),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontSize: 12, 
                                            fontWeight: FontWeight.w600, 
                                            color: Color(0xFF1A1B2D)
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () {
                                        context.read<UserActivityCubit>().removeRecent(product.productId);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black12, blurRadius: 4),
                                          ],
                                        ),
                                        child: const Icon(Icons.close, color: Colors.redAccent, size: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),

            // Brand Filter capsules
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  height: 46,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _brands.length,
                    itemBuilder: (context, index) {
                      final brand = _brands[index];
                      final isSelected = _selectedBrand == brand;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBrand = brand;
                          });
                          fetchProducts();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Theme.of(context).primaryColor : const Color(0xFFEEEEF4),
                              width: 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context).primaryColor.withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              brand,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF1A1B2D),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Products Grid
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
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
                        child: Center(child: Text('No products found', style: TextStyle(color: Colors.grey))),
                      );
                    }
                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return GestureDetector(
                            onTap: () {
                              context.go('/home/product', extra: product);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFEEEEF4), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.015),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F5F9),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: product.images.isEmpty
                                              ? const Center(child: Icon(Icons.image, size: 40, color: Colors.grey))
                                              : ClipRRect(
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: CustomImageView(
                                                    imageUrl: product.images.first, 
                                                    fit: BoxFit.cover, 
                                                    width: double.infinity,
                                                  ),
                                                ),
                                        ),
                                        Positioned(
                                          top: 14,
                                          right: 14,
                                          child: BlocBuilder<AuthCubit, AuthState>(
                                            builder: (context, authState) {
                                              if (authState is AuthAuthenticated) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.9),
                                                    shape: BoxShape.circle,
                                                    boxShadow: const [
                                                      BoxShadow(color: Colors.black12, blurRadius: 4),
                                                    ]
                                                  ),
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.brand.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                            color: Theme.of(context).primaryColor,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF1A1B2D)
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '\$${product.basePrice.toStringAsFixed(2)}', 
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                color: Color(0xFF1A1B2D)
                                              )
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, size: 14, color: Colors.orange),
                                                const SizedBox(width: 2),
                                                Text(
                                                  product.averageRating.toStringAsFixed(1), 
                                                  style: const TextStyle(
                                                    fontSize: 12, 
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1A1B2D)
                                                  )
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () {
                                            context.read<UserActivityCubit>().toggleCompare(product);
                                          },
                                          child: BlocBuilder<UserActivityCubit, UserActivityState>(
                                            builder: (context, state) {
                                              final isComparing = state.compareList.any((p) => p.productId == product.productId);
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(isComparing ? Icons.check : Icons.add, size: 14, color: isComparing ? Colors.green : Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isComparing ? 'Đã so sánh' : 'So sánh',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isComparing ? Colors.green : Colors.grey,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
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
      ),
      ),
    );
  }
}
