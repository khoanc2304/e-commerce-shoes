import '../../../../core/widgets/custom_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';
import '../cubit/order_cubit.dart';

class OrderHistoryScreen extends StatelessWidget {
  final String userId;

  const OrderHistoryScreen({Key? key, required this.userId}) : super(key: key);

  Widget _buildOrderList(List<OrderModel> orders, String status) {
    final filteredOrders = orders.where((o) => o.status.toLowerCase() == status.toLowerCase()).toList();

    if (filteredOrders.isEmpty) {
      return Center(child: Text('No $status orders found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final dateStr = order.createdAt != null 
            ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!.toDate()) 
            : 'Unknown Date';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Divider(),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        color: Colors.grey[200],
                        child: item.image.isEmpty ? const Icon(Icons.image, size: 20) : CustomImageView(imageUrl: item.image, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('x${item.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )).toList(),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${order.items.length} items', style: const TextStyle(color: Colors.grey)),
                    Text('Total: \$${order.totalPrice.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order History'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Delivering'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: StreamBuilder<List<OrderModel>>(
          stream: context.read<OrderCubit>().getOrdersStream(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final orders = snapshot.data ?? [];

            return TabBarView(
              children: [
                _buildOrderList(orders, 'pending'),
                _buildOrderList(orders, 'delivering'),
                _buildOrderList(orders, 'completed'),
                _buildOrderList(orders, 'cancelled'),
              ],
            );
          },
        ),
      ),
    );
  }
}
