import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../cubit/user_activity_cubit.dart';
import '../cubit/user_activity_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../cart/data/models/cart_model.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int? _selectedSize;
  String? _selectedColor; 
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Load reviews when entering
    context.read<ProductCubit>().loadProductReviews(widget.product);
    
    // Add to recently viewed
    context.read<UserActivityCubit>().addToRecent(widget.product);
  }

  void _showAddReviewModal(BuildContext context) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Row(
                    children: [
                      const Text('Rating: '),
                      Slider(
                        value: rating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: rating.toString(),
                        onChanged: (val) {
                          setModalState(() => rating = val);
                        },
                      ),
                      Text(rating.toString()),
                    ],
                  );
                },
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final review = ReviewModel(
                      reviewId: const Uuid().v4(),
                      userId: 'currentUserId', // Ideally from Auth
                      userName: 'Current User', // Ideally from Auth
                      rating: rating,
                      comment: commentController.text,
                    );
                    context.read<ProductCubit>().addReview(widget.product, review);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Submit Review'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          BlocBuilder<UserActivityCubit, UserActivityState>(
            builder: (context, state) {
              final isComparing = state.compareList.any((p) => p.productId == widget.product.productId);
              return IconButton(
                icon: Icon(
                  isComparing ? Icons.compare_arrows : Icons.compare_arrows_outlined,
                  color: isComparing ? Colors.orange : Colors.grey,
                ),
                tooltip: 'Compare',
                onPressed: () {
                  context.read<UserActivityCubit>().toggleCompare(widget.product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isComparing ? 'Removed from comparison' : 'Added to comparison'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return StreamBuilder<CartModel?>(
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
                );
              }
              return IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Cart',
                onPressed: () {
                  context.push('/cart');
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: product.images.isEmpty
                  ? const Center(child: Icon(Icons.image, size: 100, color: Colors.grey))
                  : Image.network(product.images.first, fit: BoxFit.cover),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '\$${product.basePrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${product.averageRating.toStringAsFixed(1)} (${product.reviewCount} Reviews)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      Text('${product.salesCount} Sold', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  // Description
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(product.description),
                  
                  const Divider(height: 32),
                  
                  // Sizes
                  const Text('Available Sizes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: product.availableSizes.map((size) {
                      return ChoiceChip(
                        label: Text(size.toString()),
                        selected: _selectedSize == size,
                        onSelected: (selected) {
                          setState(() => _selectedSize = selected ? size : null);
                        },
                      );
                    }).toList(),
                  ),
                  
                  const Divider(height: 32),

                  const Divider(height: 32),
                  
                  // Colors
                  if (product.colors.isNotEmpty) ...[
                    const Text('Available Colors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: product.colors.map((color) {
                        return ChoiceChip(
                          label: Text(color),
                          selected: _selectedColor == color,
                          onSelected: (selected) {
                            setState(() => _selectedColor = selected ? color : null);
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),
                  ],

                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton(
                        onPressed: () => _showAddReviewModal(context),
                        child: const Text('Add Review'),
                      )
                    ],
                  ),
                  
                  BlocBuilder<ProductCubit, ProductState>(
                    builder: (context, state) {
                      if (state is ProductLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is ProductReviewsLoaded && state.product.productId == product.productId) {
                        final reviews = state.reviews;
                        if (reviews.isEmpty) {
                          return const Text('No reviews yet. Be the first!');
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(child: Text(review.userName[0])),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: Colors.orange),
                                        Text(review.rating.toString()),
                                      ],
                                    ),
                                  ],
                                ),
                                subtitle: Text(review.comment),
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedSize == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a size first.')),
                    );
                    return;
                  }
                  if (product.colors.isNotEmpty && _selectedColor == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a color first.')),
                    );
                    return;
                  }

                  final authState = context.read<AuthCubit>().state;
                  if (authState is! AuthAuthenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in to add to cart.')),
                    );
                    return;
                  }

                  final cartItem = CartItemModel(
                    productId: product.productId,
                    productName: product.name,
                    image: product.images.isNotEmpty ? product.images.first : '',
                    selectedSize: _selectedSize!,
                    selectedColor: _selectedColor ?? '',
                    quantity: _quantity,
                    price: product.basePrice,
                  );

                  context.read<CartCubit>().addToCart(authState.user.uid, cartItem);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added $_quantity items to cart!'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add to Cart', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
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
