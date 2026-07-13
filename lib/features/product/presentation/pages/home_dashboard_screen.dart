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
    'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
    'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=800',
    'https://images.unsplash.com/photo-1595950653106-6c9ebd614c3a?w=800',
    'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=800',
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
    
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 18) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.role == 'admin';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161622) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF232332) : const Color(0xFFEEEEF4);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (isAdmin)
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
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
              // Premium Greeting Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              color: Color(0xFF8E8E9E),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authState is AuthAuthenticated ? authState.user.fullName : 'Guest User',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF1A1B2D),
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
                            border: Border.all(color: borderColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
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

              // Elegant Search & Filter Tuner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ]
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_outlined, color: Color(0xFF8E8E9E), size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Search your favorite sneakers...',
                              style: TextStyle(
                                color: Color(0xFF8E8E9E),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.tune_outlined, color: Theme.of(context).primaryColor, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Banner Slider
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 150.0,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 5),
                      enlargeCenterPage: true,
                      viewportFraction: 0.9,
                    ),
                    items: _banners.map((url) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
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
              
              // Recently Viewed Horizontal Panel
              SliverToBoxAdapter(
                child: BlocBuilder<UserActivityCubit, UserActivityState>(
                  builder: (context, state) {
                    if (state.recentlyViewed.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recently Viewed', 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1B2D))
                              ),
                              GestureDetector(
                                onTap: () => context.read<UserActivityCubit>().clearRecent(),
                                child: const Text(
                                  'Clear All', 
                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: state.recentlyViewed.length,
                            itemBuilder: (context, index) {
                              final product = state.recentlyViewed[index];
                              return Container(
                                width: 80,
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
                                            height: 72,
                                            width: 72,
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F9),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: borderColor, width: 1.2),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: product.images.isNotEmpty
                                                  ? CustomImageView(imageUrl: product.images.first, fit: BoxFit.cover)
                                                  : const Icon(Icons.image, color: Colors.grey, size: 24),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            product.name,
                                            style: TextStyle(
                                              fontSize: 11, 
                                              fontWeight: FontWeight.bold, 
                                              color: isDark ? Colors.white : const Color(0xFF1A1B2D)
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: -3,
                                      right: -3,
                                      child: GestureDetector(
                                        onTap: () {
                                          context.read<UserActivityCubit>().removeRecent(product.productId);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Brand Capsules Selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: SizedBox(
                    height: 44,
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
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [Theme.of(context).primaryColor, const Color(0xFFFF8A50)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : borderColor,
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                brand,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : const Color(0xFF1A1B2D)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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
              
              // Sneaker Products Grid
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
                        child: Center(child: Text(state.message, style: const TextStyle(color: Colors.red))),
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
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.65,
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
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: borderColor, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.015),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 1.1,
                                      child: Stack(
                                        children: [
                                          // Product Thumbnail Box
                                          Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            margin: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F9),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: product.images.isEmpty
                                                ? const Center(child: Icon(Icons.image_outlined, size: 36, color: Colors.grey))
                                                : ClipRRect(
                                                    borderRadius: BorderRadius.circular(16),
                                                    child: CustomImageView(
                                                      imageUrl: product.images.first, 
                                                      fit: BoxFit.cover, 
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                                  ),
                                          ),
                                          // Share Overlay icon
                                          Positioned(
                                            top: 14,
                                            right: 14,
                                            child: BlocBuilder<AuthCubit, AuthState>(
                                              builder: (context, authState) {
                                                if (authState is AuthAuthenticated) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: cardColor.withOpacity(0.85),
                                                      shape: BoxShape.circle,
                                                      boxShadow: const [
                                                        BoxShadow(color: Colors.black12, blurRadius: 4),
                                                      ]
                                                    ),
                                                    child: IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                      icon: Icon(Icons.share_outlined, size: 14, color: isDark ? Colors.white : Colors.black87),
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
                                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product shared to chat!'), backgroundColor: Colors.green));
                                                          }
                                                        } catch (e) {
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e'), backgroundColor: Colors.red));
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
                                    // Footer Sneaker Details
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  product.brand.toUpperCase(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 9,
                                                    color: Theme.of(context).primaryColor,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                // Rating score pill
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star, size: 12, color: Colors.orange),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      product.averageRating.toStringAsFixed(1), 
                                                      style: TextStyle(
                                                        fontSize: 10, 
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? Colors.white : const Color(0xFF1A1B2D)
                                                      )
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isDark ? Colors.white : const Color(0xFF1A1B2D)
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '\$${product.basePrice.toStringAsFixed(2)}', 
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                color: Theme.of(context).primaryColor
                                              )
                                            ),
                                            // Toggle comparison button
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
                                                      Icon(
                                                        isComparing ? Icons.compare_arrows : Icons.add_circle_outline_outlined, 
                                                        size: 13, 
                                                        color: isComparing ? Colors.green : Colors.grey
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isComparing ? 'Comparing' : 'Compare',
                                                        style: TextStyle(
                                                          fontSize: 10,
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
