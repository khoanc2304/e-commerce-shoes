import '../../../../core/widgets/custom_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/cart_model.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../../core/utils/vnpay_service.dart';
import 'vnpay_webview_screen.dart';

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
  final List<String> _paymentMethods = ['Cash on Delivery', 'Credit Card', 'VNPay'];
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

  void _handleVNPayPayment(BuildContext context, String orderId) async {
    final paymentUrl = VNPayService.generatePaymentUrl(
      txnRef: orderId,
      amountInUsd: widget.totalPrice,
      orderInfo: 'Thanh_toan_don_hang_${orderId.substring(0, 8)}',
    );

    // Capture Blocs và ScaffoldMessenger trước khi bắt đầu phần bất đồng bộ (async gap)
    final orderCubit = context.read<OrderCubit>();
    final cartCubit = context.read<CartCubit>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await Navigator.push<Map<String, String>?>(
      context,
      MaterialPageRoute(
        builder: (context) => VNPayWebViewScreen(paymentUrl: paymentUrl),
      ),
    );

    if (result != null) {
      final isSignatureValid = VNPayService.verifyResponseSignature(result);
      final responseCode = result['vnp_ResponseCode'];

      if (isSignatureValid && responseCode == '00') {
        // Cập nhật trạng thái đã thanh toán trong DB
        await orderCubit.updatePaymentStatus(orderId, true);
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        // Hủy đơn hàng và khôi phục tồn kho sản phẩm
        await orderCubit.updateOrderStatus(orderId, 'cancelled');
        // Khôi phục lại giỏ hàng cho người dùng
        await cartCubit.restoreCart(widget.userId, widget.cartItems);
        
        if (mounted) {
          String errorMsg = 'Thanh toán thất bại hoặc đã bị hủy.';
          if (responseCode == '24') {
            errorMsg = 'Giao dịch thanh toán đã bị hủy bởi người dùng.';
          }
          
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      await orderCubit.updateOrderStatus(orderId, 'cancelled');
      await cartCubit.restoreCart(widget.userId, widget.cartItems);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Giao dịch thanh toán đã bị hủy.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt hàng thành công!'),
        content: const Text('Đơn hàng của bạn đã được đặt thành công.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Đóng popup thông báo
              Navigator.of(context).pop(); // Quay lại màn hình trước checkout (CartScreen)
            },
            child: const Text('OK'),
          )
        ],
      ),
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
          appBar: AppBar(
            title: Text(
              'Checkout',
              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
            ),
          ),
          body: BlocConsumer<CartCubit, CartState>(
            listener: (context, state) {
              if (state is CartCheckoutSuccess) {
                if (state.paymentMethod == 'VNPay') {
                  _handleVNPayPayment(context, state.orderId);
                } else {
                  _showSuccessDialog();
                }
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shipping Details
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, top: 8.0, bottom: 4.0),
                          child: Text(
                            'Shipping Address', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.local_shipping_outlined, color: Theme.of(context).primaryColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedAddress?.receiverName ?? 'No Address Selected',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _selectedAddress == null 
                                              ? Colors.red 
                                              : Theme.of(context).colorScheme.onBackground,
                                        ),
                                      ),
                                      if (_selectedAddress != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedAddress!.phoneNumber,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_selectedAddress!.addressLine}, ${_selectedAddress!.city}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap Change to add or select an address',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _showAddressSelectionModal(context, user),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: Theme.of(context).primaryColor,
                                  ),
                                  child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Order Summary
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                          child: Text(
                            'Order Summary', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: widget.cartItems.length,
                                  itemBuilder: (context, index) {
                                    final item = widget.cartItems[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).brightness == Brightness.light
                                                  ? const Color(0xFFF5F5F9)
                                                  : const Color(0xFF1C1C2A),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: item.image.isEmpty
                                                  ? const Icon(Icons.image, size: 20)
                                                  : CustomImageView(imageUrl: item.image, fit: BoxFit.contain),
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
                                                    color: Theme.of(context).colorScheme.onBackground,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'x${item.quantity}  •  Size: ${item.selectedSize}  •  ${item.selectedColor}',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onBackground,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Subtotal', style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6))),
                                    Text('\$${widget.subTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                                  ],
                                ),
                                if (widget.discountAmount > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Discount (${widget.voucherApplied})', style: const TextStyle(color: Colors.green)),
                                      Text('-\$${widget.discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Shipping Fee', style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6))),
                                    const Text('Free', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Divider(),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onBackground)),
                                    Text(
                                      '\$${widget.totalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Payment Method
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                          child: Text(
                            'Payment Method', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _paymentMethods.map((method) {
                                final isSelected = _selectedPaymentMethod == method;
                                IconData methodIcon = Icons.money;
                                if (method == 'Credit Card') {
                                  methodIcon = Icons.credit_card;
                                } else if (method == 'VNPay') {
                                  methodIcon = Icons.account_balance_wallet_outlined;
                                }

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPaymentMethod = method;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.light
                                          ? (isSelected ? Theme.of(context).primaryColor.withOpacity(0.03) : const Color(0xFFF8F9FB))
                                          : (isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : const Color(0xFF1C1C2A)),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected 
                                            ? Theme.of(context).primaryColor 
                                            : Theme.of(context).dividerColor.withOpacity(0.1),
                                        width: isSelected ? 1.8 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Theme.of(context).primaryColor.withOpacity(0.15),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          methodIcon, 
                                          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            method,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 15,
                                              color: Theme.of(context).colorScheme.onBackground,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.5),
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? Center(
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).primaryColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _placeOrder(user),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Place Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
