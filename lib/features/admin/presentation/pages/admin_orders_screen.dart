import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/cubit/order_state.dart';
import '../../../orders/data/models/order_model.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Orders'),
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
            stream: context.read<OrderCubit>().getAllOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final orders = snapshot.data ?? [];

              if (orders.isEmpty) {
                return const Center(child: Text('No orders found.'));
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
                Text('Customer: ${order.customerName}'),
                Text('Email: ${order.email}'),
                Text('Date: ${order.createdAt?.toDate().toString().split('.')[0] ?? ''}'),
                const Divider(),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: item.image.isNotEmpty ? Image.network(item.image, fit: BoxFit.cover) : const Icon(Icons.image),
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Admin can cancel if pending
                    OutlinedButton(
                      onPressed: order.status == 'pending' ? () {
                        _showCancelDialog(context, order.orderId);
                      } : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        disabledForegroundColor: Colors.grey,
                      ),
                      child: const Text('Cancel Order'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: order.status == 'pending' ? () {
                        context.read<OrderCubit>().updateOrderStatus(order.orderId, 'shipping');
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, 
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                      ),
                      child: const Text('Approve to Ship'),
                    ),
                  ],
                )
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
        content: const Text('Are you sure you want to cancel this order? This action will restore stock.'),
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
