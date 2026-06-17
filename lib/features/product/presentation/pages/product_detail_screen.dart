import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../../chat/data/repositories/chat_repository.dart';
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
import '../../data/repositories/product_repository.dart';

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

  bool _isLoadingReviews = true;
  List<ReviewModel> _reviews = [];
  
  double _inlineRating = 0.0;
  final TextEditingController _inlineCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReviews();
    context.read<UserActivityCubit>().addToRecent(widget.product);
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final repo = ProductRepository();
      final reviews = await repo.getReviews(widget.product.productId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _submitReview(ReviewModel review) async {
    setState(() => _isLoadingReviews = true);
    try {
      final repo = ProductRepository();
      await repo.addReview(widget.product.productId, review);
      _loadReviews();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
      }
    }
  }

  Future<void> _updateReview(ReviewModel oldReview, ReviewModel newReview) async {
    setState(() => _isLoadingReviews = true);
    try {
      final repo = ProductRepository();
      await repo.updateReview(widget.product.productId, oldReview, newReview);
      _loadReviews();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update review: $e')));
      }
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    setState(() => _isLoadingReviews = true);
    try {
      final repo = ProductRepository();
      await repo.deleteReview(widget.product.productId, review);
      _loadReviews();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete review: $e')));
      }
    }
  }

  void _showReviewOptions(BuildContext context, ReviewModel review, String uid, String userName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Comment'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReviewModal(context, uid, userName, existingReview: review);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Review', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteReview(review);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showEditRatingModal(BuildContext context, ReviewModel review, String uid, String userName) {
    double tempRating = review.rating;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Update Rating', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => tempRating = index + 1.0);
                          },
                          child: Icon(
                            index < tempRating ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 48,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(tempRating == 0 ? 'No rating' : tempRating.toString(), style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final updatedReview = ReviewModel(
                            reviewId: review.reviewId,
                            userId: uid,
                            userName: userName,
                            rating: tempRating,
                            comment: review.comment,
                          );
                          _updateReview(review, updatedReview);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save Rating'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _showReviewModal(BuildContext context, String uid, String userName, {ReviewModel? existingReview}) {
    double rating = existingReview?.rating ?? 0.0;
    final commentController = TextEditingController(text: existingReview?.comment ?? '');

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
              Text(existingReview == null ? 'Add Review' : 'Edit Review', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Row(
                    children: [
                      const Text('Rating: '),
                      Slider(
                        value: rating,
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: rating == 0 ? 'No rating' : rating.toString(),
                        onChanged: (val) {
                          setModalState(() => rating = val);
                        },
                      ),
                      Text(rating == 0 ? 'No rating' : rating.toString()),
                    ],
                  );
                },
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment (Optional if rated)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (rating == 0 && commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a rating or a comment')));
                      return;
                    }
                    final newReview = ReviewModel(
                      reviewId: existingReview?.reviewId ?? const Uuid().v4(),
                      userId: uid,
                      userName: userName,
                      rating: rating,
                      comment: commentController.text.trim(),
                    );
                    
                    if (existingReview == null) {
                      _submitReview(newReview);
                    } else {
                      _updateReview(existingReview, newReview);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(existingReview == null ? 'Submit Review' : 'Save Changes'),
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
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share to Chat',
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
                );
              }
              return const SizedBox.shrink();
            },
          ),
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
                  const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      if (authState is AuthAuthenticated) {
                        // TODO: Future feature - Check if user has purchased this product
                        // final hasPurchased = checkPurchase(authState.user.uid, product.productId);
                        // if (!hasPurchased) return const SizedBox.shrink();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Rating: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...List.generate(5, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _inlineRating = index + 1.0);
                                    },
                                    child: Icon(
                                      index < _inlineRating ? Icons.star : Icons.star_border,
                                      color: Colors.orange,
                                      size: 28,
                                    ),
                                  );
                                }),
                                if (_inlineRating == 0.0)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text('(No rating)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _inlineCommentController,
                                    decoration: InputDecoration(
                                      hintText: 'Write your review...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    maxLines: null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  radius: 24,
                                  child: IconButton(
                                    icon: const Icon(Icons.send, color: Colors.white),
                                    onPressed: () {
                                      if (_inlineRating == 0 && _inlineCommentController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a rating or a comment')));
                                        return;
                                      }
                                      final review = ReviewModel(
                                        reviewId: const Uuid().v4(),
                                        userId: authState.user.uid,
                                        userName: authState.user.fullName,
                                        rating: _inlineRating,
                                        comment: _inlineCommentController.text.trim(),
                                      );
                                      _submitReview(review);
                                      setState(() {
                                        _inlineRating = 0.0;
                                        _inlineCommentController.clear();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  _isLoadingReviews
                      ? const Center(child: CircularProgressIndicator())
                      : _reviews.isEmpty
                          ? const Text('No reviews yet. Be the first!')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reviews.length,
                              itemBuilder: (context, index) {
                                final review = _reviews[index];
                                return BlocBuilder<AuthCubit, AuthState>(
                                  builder: (context, authState) {
                                    final isMyReview = authState is AuthAuthenticated && authState.user.uid == review.userId;
                                    return GestureDetector(
                                      onLongPress: isMyReview ? () => _showReviewOptions(context, review, authState.user.uid, authState.user.fullName) : null,
                                      child: Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: CircleAvatar(child: Text(review.userName[0])),
                                          title: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              GestureDetector(
                                                onTap: isMyReview ? () => _showEditRatingModal(context, review, authState.user.uid, authState.user.fullName) : null,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: isMyReview ? BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(12)
                                                  ) : null,
                                                  child: Row(
                                                    children: [
                                                      if (review.rating > 0) ...[
                                                        const Icon(Icons.star, size: 14, color: Colors.orange),
                                                        const SizedBox(width: 4),
                                                        Text(review.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      ] else
                                                        const Text('No rating', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: review.comment.isNotEmpty ? Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(review.comment),
                                          ) : null,
                                        ),
                                      ),
                                    );
                                  }
                                );
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
