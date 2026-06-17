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
          appBar: AppBar(title: Text(items.isEmpty ? 'My Cart' : 'My Cart (${items.length})')),
          body: items.isEmpty 
            ? const Center(child: Text('Your cart is empty.'))
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
                        Checkbox(
                          value: _selectedItemKeys.length == items.length && items.isNotEmpty,
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
                        const Text('Select All', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final itemKey = _getItemKey(item);
                        
                        return Dismissible(
                          key: Key(itemKey),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
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
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _selectedItemKeys.contains(itemKey),
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
                                      Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: item.image.isEmpty
                                            ? const Icon(Icons.image)
                                            : Image.network(item.image, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text('Size: ${item.selectedSize} | Color: ${item.selectedColor}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            const SizedBox(height: 4),
                                            Text('\$${item.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor)),
                                            if (isOutOfStock)
                                              const Text('Not enough stock', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline),
                                            onPressed: () {
                                              if (item.quantity > 1) {
                                                final currentAuthState = context.read<AuthCubit>().state;
                                                final currentUid = currentAuthState is AuthAuthenticated ? currentAuthState.user.uid : 'guest';
                                                context.read<CartCubit>().updateQuantity(currentUid, item.productId, item.selectedSize, item.selectedColor, item.quantity - 1);
                                              } else {
                                                _showDeleteConfirmDialog(context, item);
                                              }
                                            },
                                          ),
                                          Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline),
                                            onPressed: () {
                                              final currentAuthState = context.read<AuthCubit>().state;
                                              final currentUid = currentAuthState is AuthAuthenticated ? currentAuthState.user.uid : 'guest';
                                              context.read<CartCubit>().updateQuantity(currentUid, item.productId, item.selectedSize, item.selectedColor, item.quantity + 1);
                                            },
                                          ),
                                        ],
                                      )
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: SafeArea(
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
                                    decoration: const InputDecoration(
                                      hintText: 'Enter Voucher Code',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_couponController.text.isNotEmpty && _selectedItemKeys.isNotEmpty) {
                                      context.read<CartCubit>().applyCoupon(_couponController.text.trim(), subTotal);
                                    } else if (_selectedItemKeys.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 item to apply coupon.')));
                                    }
                                  },
                                  child: const Text('Apply'),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_offer, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text('Coupon ${appliedCoupon.code} applied!', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => context.read<CartCubit>().removeCoupon(),
                                )
                              ],
                            ),
                          const SizedBox(height: 16),
                          
                          // Summary
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal:'), Text('\$${subTotal.toStringAsFixed(2)}')]),
                          if (discount > 0)
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Discount:', style: TextStyle(color: Colors.green)), Text('-\$${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green))]),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: state is CartLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('Proceed to Checkout (${_selectedItemKeys.length})', style: const TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              );
            },
          );
        },
      ),
      );
    },
    );
  }
}
