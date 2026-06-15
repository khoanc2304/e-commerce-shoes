import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/cart_model.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';

class CheckoutScreen extends StatefulWidget {
  final String userId;
  final List<CartItemModel> cartItems;
  final double subTotal;
  final double discountAmount;
  final double totalPrice;
  final String? voucherApplied;

  const CheckoutScreen({
    Key? key,
    required this.userId,
    required this.cartItems,
    required this.subTotal,
    required this.discountAmount,
    required this.totalPrice,
    this.voucherApplied,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'Cash on Delivery';
  final List<String> _paymentMethods = ['Cash on Delivery', 'Credit Card'];

  // Mocked details for demo since they ideally come from UserModel via AuthCubit
  final String _customerName = "John Doe";
  final String _email = "john.doe@example.com";
  final Map<String, dynamic> _shippingAddress = {
    'receiverName': 'John Doe',
    'phoneNumber': '+1 234 567 890',
    'addressLine': '123 Sneaker Street',
    'city': 'New York',
  };

  void _placeOrder() {
    context.read<CartCubit>().checkout(
          userId: widget.userId,
          customerName: _customerName,
          email: _email,
          shippingAddress: _shippingAddress,
          cartItems: widget.cartItems,
          subTotal: widget.subTotal,
          discountAmount: widget.discountAmount,
          totalPrice: widget.totalPrice,
          paymentMethod: _selectedPaymentMethod,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state is CartCheckoutSuccess) {
            // Show success dialog and navigate back to Home Dashboard or Orders
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Order Placed!'),
                content: const Text('Your order has been successfully placed.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // pop dialog
                      Navigator.of(context).pop(); // pop checkout
                      Navigator.of(context).pop(); // pop cart
                      // In a real app, maybe navigate to Order History
                    },
                    child: const Text('OK'),
                  )
                ],
              ),
            );
          } else if (state is CartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shipping Details
                    const Text('Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(_shippingAddress['receiverName']),
                        subtitle: Text('${_shippingAddress['phoneNumber']}\n${_shippingAddress['addressLine']}, ${_shippingAddress['city']}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // Edit address logic
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order Summary
                    const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = widget.cartItems[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[200],
                            child: item.image.isEmpty ? const Icon(Icons.image) : Image.network(item.image, fit: BoxFit.cover),
                          ),
                          title: Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('x${item.quantity}  |  Size: ${item.selectedSize}'),
                          trailing: Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('\$${widget.subTotal.toStringAsFixed(2)}')]),
                    if (widget.discountAmount > 0)
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Discount (${widget.voucherApplied})', style: const TextStyle(color: Colors.green)), Text('-\$${widget.discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green))]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Shipping Fee'), const Text('Free')]), // Mocked free shipping
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('\$${widget.totalPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Payment Method
                    const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._paymentMethods.map((method) => RadioListTile<String>(
                          title: Text(method),
                          value: method,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (val) {
                            setState(() {
                              _selectedPaymentMethod = val!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        )),
                    const SizedBox(height: 80), // Padding for bottom button
                  ],
                ),
              ),

              // Loading Overlay
              if (state is CartLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: _placeOrder,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('Place Order', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
