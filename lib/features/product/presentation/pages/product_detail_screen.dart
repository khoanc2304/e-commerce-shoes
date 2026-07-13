import 'dart:math' as math;
import '../../../../core/widgets/custom_image_view.dart';
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
  int _activeImageIndex = 0;

  bool _isLoadingReviews = true;
  List<ReviewModel> _reviews = [];
  int _visibleReviewsCount = 5;
  
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
                    const Text('Update Rating', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                            size: 44,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(tempRating == 0 ? 'No rating' : tempRating.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            left: 18,
            right: 18,
            top: 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existingReview == null ? 'Add Review' : 'Edit Review', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildCircleAction({
    required Widget icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: icon,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161622) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF232332) : const Color(0xFFEEEEF4);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: _buildCircleAction(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
            tooltip: 'Back',
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return _buildCircleAction(
                  icon: Icon(Icons.share_outlined, color: isDark ? Colors.white : Colors.black87),
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product shared to chat!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e'), backgroundColor: Colors.red));
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
              return _buildCircleAction(
                icon: Icon(
                  isComparing ? Icons.compare_arrows : Icons.compare_arrows_outlined,
                  color: isComparing ? Theme.of(context).primaryColor : (isDark ? Colors.white : Colors.black87),
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
                    return _buildCircleAction(
                      icon: Badge(
                        label: Text(itemCount.toString()),
                        isLabelVisible: itemCount > 0,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Icon(Icons.shopping_cart_outlined, color: isDark ? Colors.white : Colors.black87),
                      ),
                      tooltip: 'Cart',
                      onPressed: () {
                        context.push('/cart');
                      },
                    );
                  },
                );
              }
              return _buildCircleAction(
                icon: Icon(Icons.shopping_cart_outlined, color: isDark ? Colors.white : Colors.black87),
                tooltip: 'Cart',
                onPressed: () {
                  context.push('/cart');
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gallery container
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Expanded(
                      child: product.images.isEmpty
                          ? const Center(child: Icon(Icons.image_outlined, size: 80, color: Colors.grey))
                          : PageView.builder(
                              itemCount: product.images.length,
                              onPageChanged: (idx) {
                                setState(() => _activeImageIndex = idx);
                              },
                              itemBuilder: (context, idx) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  child: Hero(
                                    tag: 'product_img_${product.productId}',
                                    child: CustomImageView(
                                      imageUrl: product.images[idx], 
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Visual Page Indicators
                    if (product.images.length > 1) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(product.images.length, (idx) {
                            final isActive = _activeImageIndex == idx;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: isActive ? 18 : 6,
                              decoration: BoxDecoration(
                                color: isActive ? Theme.of(context).primaryColor : Colors.grey[400],
                                borderRadius: BorderRadius.circular(100),
                              ),
                            );
                          }),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title, Brand & Price
                  Text(
                    product.brand.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1B2D),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '\$${product.basePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Rating score indicators
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              product.averageRating.toStringAsFixed(1),
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '(${product.reviewCount} Reviews)',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${product.salesCount} Sold', 
                          style: const TextStyle(
                            color: Colors.teal, 
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 48),
                  
                  // Description
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF4A4B5D), height: 1.5, fontSize: 13),
                  ),
                  
                  const Divider(height: 48),
                  
                  // Sizes circles selection
                  const Text('Available Sizes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: product.availableSizes.map((size) {
                      final isSelected = _selectedSize == size;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedSize = isSelected ? null : size);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).primaryColor : cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : borderColor,
                              width: 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              size.toString(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : const Color(0xFF1A1B2D)),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const Divider(height: 48),
                  
                  // Colors capsules selection
                  if (product.colors.isNotEmpty) ...[
                    const Text('Available Colors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: product.colors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedColor = isSelected ? null : color);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor : cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : borderColor,
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              color,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : const Color(0xFF1A1B2D)),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 48),
                  ],

                  // Reviews Block
                  const Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      if (authState is AuthAuthenticated) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Your Rating: ', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                                ...List.generate(5, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _inlineRating = index + 1.0);
                                    },
                                    child: Icon(
                                      index < _inlineRating ? Icons.star : Icons.star_border,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                  );
                                }),
                                if (_inlineRating == 0.0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text('(Tap to rate)', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                  )
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _inlineCommentController,
                                    decoration: InputDecoration(
                                      hintText: 'Write your review...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F9),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    maxLines: null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  radius: 22,
                                  child: IconButton(
                                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
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
                          ? Text('No reviews yet. Be the first!', style: TextStyle(color: Colors.grey[500]))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: math.min(_reviews.length, _visibleReviewsCount),
                              itemBuilder: (context, index) {
                                final review = _reviews[index];
                                return BlocBuilder<AuthCubit, AuthState>(
                                  builder: (context, authState) {
                                    final isMyReview = authState is AuthAuthenticated && authState.user.uid == review.userId;
                                    return GestureDetector(
                                      onLongPress: isMyReview ? () => _showReviewOptions(context, review, authState.user.uid, authState.user.fullName) : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: borderColor,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                              radius: 18,
                                              child: Text(
                                                review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                                                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          review.userName, 
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold, 
                                                            color: isDark ? Colors.white : Colors.black,
                                                            fontSize: 13,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: isMyReview ? () => _showEditRatingModal(context, review, authState.user.uid, authState.user.fullName) : null,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F9),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              if (review.rating > 0) ...[
                                                                const Icon(Icons.star, size: 12, color: Colors.orange),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  review.rating.toString(), 
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold, 
                                                                    color: isDark ? Colors.white : Colors.black, 
                                                                    fontSize: 11,
                                                                  ),
                                                                ),
                                                              ] else
                                                                Text(
                                                                  'No rating', 
                                                                  style: TextStyle(
                                                                    fontSize: 10, 
                                                                    color: Colors.grey[500], 
                                                                    fontStyle: FontStyle.italic,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (review.comment.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      review.comment, 
                                                      style: TextStyle(
                                                        color: isDark ? Colors.grey[300] : const Color(0xFF4A4B5D),
                                                        height: 1.4,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                );
                              },
                            ),
                            if (_reviews.length > _visibleReviewsCount)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _visibleReviewsCount += 5;
                                      });
                                    },
                                    child: const Text('Show more comments', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                  ],
                ),
              ),
              _buildSimilarProducts(borderColor, cardColor, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Purchase Quantity', 
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
                  ),
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(Icons.remove, size: 14, color: isDark ? Colors.white : Colors.black),
                          onPressed: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text(
                            '$_quantity', 
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(Icons.add, size: 14, color: isDark ? Colors.white : Colors.black),
                          onPressed: () {
                            setState(() => _quantity++);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add to Cart', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarProducts(Color borderColor, Color cardColor, bool isDark) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductsLoaded) {
          final similarProducts = state.products.where((p) {
            if (p.productId == widget.product.productId) return false;
            final priceDiff = (p.basePrice - widget.product.basePrice).abs() / widget.product.basePrice;
            return p.brand.toLowerCase() == widget.product.brand.toLowerCase() || priceDiff <= 0.2;
          }).toList();

          if (similarProducts.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Similar Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: similarProducts.length,
                  itemBuilder: (context, index) {
                    final p = similarProducts[index];
                    return GestureDetector(
                      onTap: () {
                        context.push('/home/product', extra: p);
                      },
                      child: Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F9),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                ),
                                child: p.images.isEmpty
                                    ? const Center(child: Icon(Icons.image, size: 40, color: Colors.grey))
                                    : ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                        child: CustomImageView(imageUrl: p.images.first, fit: BoxFit.cover, width: double.infinity),
                                      ),
                                width: double.infinity,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.brand.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                      color: Theme.of(context).primaryColor,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '\$${p.basePrice.toStringAsFixed(2)}',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Theme.of(context).primaryColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
