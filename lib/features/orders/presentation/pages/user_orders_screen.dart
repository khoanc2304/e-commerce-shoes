import '../../../../core/widgets/custom_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../data/models/order_model.dart';

class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Orders')),
            body: const Center(child: Text('Please login to view orders')),
          );
        }

        final userId = authState.user.uid;

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('My Orders'),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Pending'),
                  Tab(text: 'Shipping'),
                  Tab(text: 'Delivered'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
            body: BlocListener<OrderCubit, OrderState>(
              listener: (context, state) {
                if (state is OrderOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.green),
                  );
                } else if (state is OrderError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                  );
                }
              },
              child: StreamBuilder<List<OrderModel>>(
                stream: context.read<OrderCubit>().getOrdersStream(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final orders = snapshot.data ?? [];

                  if (orders.isEmpty) {
                    return const Center(child: Text('You have no orders yet.'));
                  }

                  final pendingOrders = orders.where((o) => o.status == 'pending').toList();
                  final shippingOrders = orders.where((o) => o.status == 'shipping').toList();
                  final deliveredOrders = orders.where((o) => o.status == 'delivered').toList();
                  final cancelledOrders = orders.where((o) => o.status == 'cancelled').toList();

                  return TabBarView(
                    children: [
                      _buildOrderList(context, pendingOrders),
                      _buildOrderList(context, shippingOrders),
                      _buildOrderList(context, deliveredOrders),
                      _buildOrderList(context, cancelledOrders),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderList(BuildContext context, List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders in this category.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order ID: ${order.orderId.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(order.status.toUpperCase(), style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date: ${order.createdAt?.toDate().toString().split('.')[0] ?? ''}'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.isPaid
                            ? Colors.green.withOpacity(0.1)
                            : (order.paymentMethod == 'VNPay' ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.isPaid
                            ? 'Đã thanh toán (VNPay)'
                            : (order.paymentMethod == 'VNPay' ? 'Chờ thanh toán (VNPay)' : 'Thanh toán COD'),
                        style: TextStyle(
                          color: order.isPaid
                              ? Colors.green
                              : (order.paymentMethod == 'VNPay' ? Colors.orange : Colors.blue),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: item.image.isNotEmpty ? CustomImageView(imageUrl: item.image, fit: BoxFit.cover) : const Icon(Icons.image),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('x${item.quantity} | Size: ${item.selectedSize}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                    ],
                  ),
                )).toList(),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${order.totalPrice.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ],
                ),
                if (order.status == 'pending' || order.status == 'shipping') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (order.status == 'pending')
                        OutlinedButton(
                          onPressed: () {
                            _showCancelDialog(context, order.orderId);
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Cancel Order'),
                        ),
                      if (order.status == 'shipping')
                        ElevatedButton(
                          onPressed: () {
                            context.read<OrderCubit>().updateOrderStatus(order.orderId, 'delivered');
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('Received'),
                        ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'shipping': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OrderCubit>().updateOrderStatus(orderId, 'cancelled');
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
