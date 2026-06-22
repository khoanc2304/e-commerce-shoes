import '../../../../core/widgets/custom_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/cart_model.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import 'checkout_screen.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  final Set<String> _selectedItemKeys = {};
  final Set<String> _dismissedItemKeys = {};

  String _getItemKey(CartItemModel item) {
    return '${item.productId}_${item.selectedSize}_${item.selectedColor}';
  }

  double _calculateSubtotal(List<CartItemModel> items) {
    return items.where((item) => _selectedItemKeys.contains(_getItemKey(item)))
                .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void _showDeleteConfirmDialog(BuildContext context, CartItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Product'),
        content: const Text('Do you want to remove this product from the cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final authState = context.read<AuthCubit>().state;
              final currentUserId = authState is AuthAuthenticated ? authState.user.uid : 'guest';
              context.read<CartCubit>().removeItem(currentUserId, item.productId, item.selectedSize, item.selectedColor);
              setState(() {
                _dismissedItemKeys.add(_getItemKey(item));
                _selectedItemKeys.remove(_getItemKey(item));
              });
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final String currentUserId = authState is AuthAuthenticated ? authState.user.uid : 'guest';
    final cartStream = context.read<CartCubit>().getCartStream(currentUserId);

    return StreamBuilder<CartModel?>(
      stream: cartStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(title: const Text('My Cart')), body: const Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(title: const Text('My Cart')), body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final cart = snapshot.data;
        final items = (cart?.items ?? []).where((item) => !_dismissedItemKeys.contains(_getItemKey(item))).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              items.isEmpty ? 'My Cart' : 'My Cart (${items.length})',
              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
            ),
          ),
          body: items.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 64, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
                    ),
                  ],
                ),
              )
            : Builder(
                builder: (context) {
                  final subTotal = _calculateSubtotal(items);
                  final selectedItemsList = items.where((i) => _selectedItemKeys.contains(_getItemKey(i))).toList();
                  
                  return BlocConsumer<CartCubit, CartState>(
                    listener: (context, state) {
                      if (state is CartError) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
                      } else if (state is CartOperationSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                      } else if (state is CartCouponApplied) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Coupon ${state.coupon.code} applied!'), backgroundColor: Colors.green));
                      }
                    },
                    builder: (context, state) {
                      final appliedCoupon = context.read<CartCubit>().appliedCoupon;
                      double discount = 0.0;
                      if (appliedCoupon != null) {
                        if (appliedCoupon.discountType == 'percentage') {
                          discount = subTotal * (appliedCoupon.discountValue / 100);
                        } else {
                          discount = appliedCoupon.discountValue;
                        }
                      }
                      final total = (subTotal - discount) > 0 ? (subTotal - discount) : 0.0;

                      return Column(
                        children: [
                          // Select All row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    checkboxTheme: CheckboxThemeData(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                  child: Checkbox(
                                    value: _selectedItemKeys.length == items.length && items.isNotEmpty,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedItemKeys.addAll(items.map((e) => _getItemKey(e)));
                                        } else {
                                          _selectedItemKeys.clear();
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Select All', 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: Theme.of(context).colorScheme.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final itemKey = _getItemKey(item);
                                
                                return Dismissible(
                                  key: Key(itemKey),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  onDismissed: (direction) {
                                    setState(() {
                                      _dismissedItemKeys.add(itemKey);
                                      _selectedItemKeys.remove(itemKey);
                                    });
                                    final currentAuthState = context.read<AuthCubit>().state;
                                    final currentUid = currentAuthState is AuthAuthenticated ? currentAuthState.user.uid : 'guest';
                                    context.read<CartCubit>().removeItem(currentUid, item.productId, item.selectedSize, item.selectedColor);
                                  },
                                  child: StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance.collection('products').doc(item.productId).snapshots(),
                                    builder: (context, prodSnapshot) {
                                      bool isOutOfStock = false;
                                      if (prodSnapshot.hasData && prodSnapshot.data!.exists) {
                                        final stock = prodSnapshot.data!.get('stock') ?? 0;
                                        isOutOfStock = stock < item.quantity;
                                      }

                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            children: [
                                              Theme(
                                                data: Theme.of(context).copyWith(
                                                  checkboxTheme: CheckboxThemeData(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                  ),
                                                ),
                                                child: Checkbox(
                                                  value: _selectedItemKeys.contains(itemKey),
                                                  activeColor: Theme.of(context).primaryColor,
                                                  onChanged: (val) {
                                                    setState(() {
                                                      if (val == true) {
                                                        _selectedItemKeys.add(itemKey);
                                                      } else {
                                                        _selectedItemKeys.remove(itemKey);
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).brightness == Brightness.light
                                                      ? const Color(0xFFF5F5F9)
                                                      : const Color(0xFF1C1C2A),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: item.image.isEmpty
                                                      ? const Icon(Icons.image, color: Colors.grey)
                                                      : CustomImageView(
                                                          imageUrl: item.image,
                                                          fit: BoxFit.contain,
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.productName,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Theme.of(context).colorScheme.onBackground,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Size: ${item.selectedSize}  •  Color: ${item.selectedColor}',
                                                      style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      '\$${item.price.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: Theme.of(context).primaryColor,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    if (isOutOfStock) ...[
                                                      const SizedBox(height: 2),
                                                      const Text(
                                                        'Not enough stock',
                                                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).brightness == Brightness.light
                                                      ? const Color(0xFFF5F5F9)
                                                      : const Color(0xFF1C1C2A),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        if (item.quantity > 1) {
                                                          final currentAuthState = context.read<AuthCubit>().state;
                                                          final currentUid = currentAuthState is AuthAuthenticated ? currentAuthState.user.uid : 'guest';
                                                          context.read<CartCubit>().updateQuantity(currentUid, item.productId, item.selectedSize, item.selectedColor, item.quantity - 1);
                                                        } else {
                                                          _showDeleteConfirmDialog(context, item);
                                                        }
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Icon(Icons.remove, size: 14, color: Theme.of(context).colorScheme.onBackground),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                                      child: Text(
                                                        item.quantity.toString(),
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).colorScheme.onBackground,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        final currentAuthState = context.read<AuthCubit>().state;
                                                        final currentUid = currentAuthState is AuthAuthenticated ? currentAuthState.user.uid : 'guest';
                                                        context.read<CartCubit>().updateQuantity(currentUid, item.productId, item.selectedSize, item.selectedColor, item.quantity + 1);
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Icon(Icons.add, size: 14, color: Theme.of(context).colorScheme.onBackground),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  ),
                                );
                              },
                            ),
                          ),

                          // Bottom Summary & Coupon
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? Colors.white
                                  : const Color(0xFF161622),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Coupon Field
                                  if (appliedCoupon == null)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _couponController,
                                            decoration: InputDecoration(
                                              hintText: 'Enter Voucher Code',
                                              filled: true,
                                              fillColor: Theme.of(context).brightness == Brightness.light
                                                  ? const Color(0xFFF5F5F9)
                                                  : const Color(0xFF1C1C2A),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onBackground),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (_couponController.text.isNotEmpty && _selectedItemKeys.isNotEmpty) {
                                              context.read<CartCubit>().applyCoupon(_couponController.text.trim(), subTotal);
                                            } else if (_selectedItemKeys.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 item to apply coupon.')));
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: const Text('Apply'),
                                        ),
                                      ],
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.local_offer, color: Colors.green, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Coupon ${appliedCoupon.code} applied!', 
                                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                            onPressed: () => context.read<CartCubit>().removeCoupon(),
                                          )
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  
                                  // Summary
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                    children: [
                                      Text('Subtotal:', style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6))), 
                                      Text('\$${subTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                                    ],
                                  ),
                                  if (discount > 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                      children: [
                                        const Text('Discount:', style: TextStyle(color: Colors.green)), 
                                        Text('-\$${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.0),
                                    child: Divider(height: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onBackground)),
                                      Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Checkout Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: (state is CartLoading || _selectedItemKeys.isEmpty)
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) {
                                                    final currentAuthState = context.read<AuthCubit>().state;
                                                    final currentUid = currentAuthState is AuthAuthenticated ? currentAuthState.user.uid : 'guest';
                                                    return CheckoutScreen(
                                                      userId: currentUid,
                                                      cartItems: selectedItemsList,
                                                    subTotal: subTotal,
                                                    discountAmount: discount,
                                                    totalPrice: total,
                                                      voucherApplied: appliedCoupon?.code,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: state is CartLoading
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : Text('Proceed to Checkout (${_selectedItemKeys.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              ),
        );
      },
    );
  }
}
