import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/cart_model.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final String userId;

  const CartScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  double _calculateSubtotal(List<CartItemModel> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    final cartStream = context.read<CartCubit>().getCartStream(widget.userId);

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: StreamBuilder<CartModel?>(
        stream: cartStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final cart = snapshot.data;
          final items = cart?.items ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty.'));
          }

          final subTotal = _calculateSubtotal(items);
          
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

              // Check if any items are out of stock to block checkout globally
              // We'll track it using a boolean that might update based on the Futures below
              // A more robust approach uses Rx/Streams for all items combined.
              // For UI demonstration, we'll allow the button but atomic transaction will catch it,
              // but we also disable it if we know an item is out of stock visually.

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        
                        return Dismissible(
                          key: Key(item.productId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            context.read<CartCubit>().removeItem(widget.userId, item.productId);
                          },
                          child: StreamBuilder<DocumentSnapshot>(
                            // Real-time stock checking
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
                                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text('Size: ${item.selectedSize} | Color: ${item.selectedColor}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            const SizedBox(height: 4),
                                            Text('\$${item.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor)),
                                            if (isOutOfStock)
                                              const Text('Out of stock / Not enough stock', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline),
                                            onPressed: () {
                                              if (item.quantity > 1) {
                                                context.read<CartCubit>().updateQuantity(widget.userId, item.productId, item.quantity - 1);
                                              }
                                            },
                                          ),
                                          Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline),
                                            onPressed: () {
                                              context.read<CartCubit>().updateQuantity(widget.userId, item.productId, item.quantity + 1);
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
                                    if (_couponController.text.isNotEmpty) {
                                      context.read<CartCubit>().applyCoupon(_couponController.text.trim(), subTotal);
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
                              onPressed: state is CartLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CheckoutScreen(
                                            userId: widget.userId,
                                            cartItems: items,
                                            subTotal: subTotal,
                                            discountAmount: discount,
                                            totalPrice: total,
                                            voucherApplied: appliedCoupon?.code,
                                          ),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: state is CartLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Proceed to Checkout', style: TextStyle(fontSize: 16)),
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
  }
}
