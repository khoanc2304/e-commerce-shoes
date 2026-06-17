import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/cart_model.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/data/models/user_model.dart';

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
  ShippingAddress? _selectedAddress;

  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeDefaultAddress();
  }

  void _initializeDefaultAddress() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _currentUser = authState.user;
      if (authState.user.shippingAddresses.isNotEmpty) {
        _selectedAddress = authState.user.shippingAddresses.first;
      }
    }
  }

  void _showAddAddressDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Address'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Receiver Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address Line'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newAddress = ShippingAddress(
                  id: const Uuid().v4(),
                  receiverName: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  addressLine: addressController.text.trim(),
                  city: cityController.text.trim(),
                );
                
                context.read<AuthCubit>().addShippingAddress(newAddress);
                
                setState(() {
                  _selectedAddress = newAddress;
                });
                
                Navigator.pop(ctx); // Close Dialog
                Navigator.pop(context); // Close BottomSheet
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddressSelectionModal(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              final addresses = state.user.shippingAddresses;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (addresses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No addresses found. Please add one.'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final addr = addresses[index];
                          return RadioListTile<ShippingAddress>(
                            title: Text(addr.receiverName),
                            subtitle: Text('${addr.phoneNumber}\n${addr.addressLine}, ${addr.city}'),
                            isThreeLine: true,
                            value: addr,
                            groupValue: _selectedAddress,
                            onChanged: (val) {
                              setState(() {
                                _selectedAddress = val;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Address'),
                        onPressed: () {
                          _showAddAddressDialog(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        );
      },
    );
  }

  void _placeOrder(UserModel user) {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping address.')),
      );
      return;
    }

    context.read<CartCubit>().checkout(
          userId: widget.userId,
          customerName: _selectedAddress!.receiverName,
          email: user.email,
          shippingAddress: _selectedAddress!.toMap(),
          cartItems: widget.cartItems,
          subTotal: widget.subTotal,
          discountAmount: widget.discountAmount,
          totalPrice: widget.totalPrice,
          paymentMethod: _selectedPaymentMethod,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, authState) {
        if (authState is AuthAuthenticated) {
          setState(() {
            _currentUser = authState.user;
          });
        }
      },
      builder: (context, authState) {
        if (_currentUser == null) {
          return const Scaffold(body: Center(child: Text('Please login to checkout')));
        }
        final user = _currentUser!;

        // Fallback initialization if it somehow wasn't caught in initState
        if (_selectedAddress == null && user.shippingAddresses.isNotEmpty) {
          _selectedAddress = user.shippingAddresses.first;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: BlocConsumer<CartCubit, CartState>(
            listener: (context, state) {
              if (state is CartCheckoutSuccess) {
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
                            title: Text(_selectedAddress?.receiverName ?? 'No Address Selected', style: TextStyle(color: _selectedAddress == null ? Colors.red : null)),
                            subtitle: _selectedAddress != null 
                              ? Text('${_selectedAddress!.phoneNumber}\n${_selectedAddress!.addressLine}, ${_selectedAddress!.city}')
                              : const Text('Tap change to add an address'),
                            isThreeLine: _selectedAddress != null,
                            trailing: TextButton(
                              onPressed: () => _showAddressSelectionModal(context, user),
                              child: const Text('Change'),
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
              onPressed: () => _placeOrder(user),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Place Order', style: TextStyle(fontSize: 18)),
            ),
          ),
        );
      },
    );
  }
}
