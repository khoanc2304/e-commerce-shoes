import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shues X', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to SearchFilterScreen
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              context.push('/profile');
            },
          ),
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
                          // image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                        ),
                        child: const Center(child: Text('Banner Ad', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
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
                            );
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
                                      // image: product.images.isNotEmpty ? DecorationImage(image: NetworkImage(product.images.first), fit: BoxFit.cover) : null,
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
    );
  }
}
