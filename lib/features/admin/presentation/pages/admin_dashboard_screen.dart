import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/seed_data.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadAnalytics();
  }

  Widget _buildRevenueChart() {
    // A simple mock chart representation using fl_chart
    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 5000,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(days[value.toInt() % 7], style: const TextStyle(fontSize: 10)));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 1200, color: Colors.blueAccent)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 2300, color: Colors.blueAccent)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 3400, color: Colors.blueAccent)]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 1500, color: Colors.blueAccent)]),
            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 4200, color: Colors.blueAccent)]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminError) {
            return Center(child: Text(state.message));
          }
          if (state is AdminAnalyticsLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<AdminCubit>().loadAnalytics(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Theme.of(context).primaryColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('Total Revenue', style: TextStyle(color: Colors.white)),
                                  const SizedBox(height: 8),
                                  Text('\$${state.totalRevenue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('Completed Orders'),
                                  const SizedBox(height: 8),
                                  Text('${state.completedOrders.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.inventory),
                            label: const Text('Manage Products'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () async {
                              await context.push('/admin/products'); 
                              if (context.mounted) {
                                context.read<AdminCubit>().loadAnalytics();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Manage Orders'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              context.push('/admin/orders');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat),
                            label: const Text('Customer Chats'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              context.push('/admin/chats');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    /*
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('AUTO-SEED MOCK DATA (1-Click)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        // Gọi hàm nạp dữ liệu
                        seedFirebaseData(context);
                      },
                    ),
                    */
                    const SizedBox(height: 32),
                    const Text('Revenue Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildRevenueChart(),
                    const SizedBox(height: 32),
                    
                    const Text('Recent Completed Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.completedOrders.take(10).length,
                      itemBuilder: (context, index) {
                        final order = state.completedOrders[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(order.orderId.substring(0, 2).toUpperCase())),
                          title: Text(order.customerName),
                          subtitle: Text(order.createdAt != null ? DateFormat('dd MMM yyyy').format(order.createdAt!.toDate()) : ''),
                          trailing: Text('\$${order.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        );
                      },
                    )
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
