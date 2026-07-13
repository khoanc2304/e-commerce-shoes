import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/seed_data.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../../../orders/data/models/order_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedChartIndex = 0; // 0: Revenue Line, 1: Status Donut, 2: Brands Bar
  String _revenueTimeRange = '1W'; // '1W', '1M', '1Y'

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadAnalytics();
  }

  // --- Helpers for formatting & analytics ---
  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  LinearGradient _getAvatarGradient(String name) {
    final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    final index = hash % 5;
    final gradients = [
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)], // Deep Purple
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)], // Sky Blue
      [const Color(0xFF11998E), const Color(0xFF38EF7D)], // Emerald
      [const Color(0xFFFC4A1A), const Color(0xFFF7B733)], // Sunrise Orange
      [const Color(0xFFF2709C), const Color(0xFFFF9472)], // Pink Coral
    ];
    return LinearGradient(
      colors: gradients[index],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'shipping':
      case 'delivering':
        return Colors.blue;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // --- Chart Building Methods ---

  Widget _buildTimeRangeButton(String range, String label, bool isDark) {
    final bool isSelected = _revenueTimeRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _revenueTimeRange = range;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C2C3E) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueLineChart(List<OrderModel> completedOrders, bool isDark) {
    final now = DateTime.now();
    List<FlSpot> spots = [];
    List<FlSpot> targetSpots = [];
    List<String> xLabels = [];
    int xCount = 7;

    bool hasAnyRealData = false;

    if (_revenueTimeRange == '1W') {
      xCount = 7;
      final List<DateTime> dates = List.generate(7, (index) {
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
      });
      xLabels = dates.map((d) => DateFormat('E').format(d)).toList();

      final Map<int, double> dailyRevenue = {};
      for (int i = 0; i < 7; i++) {
        final date = dates[i];
        double total = 0.0;
        for (var order in completedOrders) {
          if (order.createdAt != null) {
            final orderDate = order.createdAt!.toDate();
            if (orderDate.year == date.year &&
                orderDate.month == date.month &&
                orderDate.day == date.day) {
              total += order.totalPrice;
            }
          }
        }
        dailyRevenue[i] = total;
        if (total > 0) hasAnyRealData = true;
      }

      final List<double> mockActualValues = [240, 480, 310, 720, 590, 890, 1100];
      final List<double> mockTargetValues = [300, 400, 500, 600, 700, 800, 900];

      for (int i = 0; i < 7; i++) {
        double val = dailyRevenue[i] ?? 0.0;
        if (!hasAnyRealData && completedOrders.isEmpty) {
          val = mockActualValues[i];
        }
        spots.add(FlSpot(i.toDouble(), val));
        targetSpots.add(FlSpot(i.toDouble(), (!hasAnyRealData && completedOrders.isEmpty) ? mockTargetValues[i] : (val * 1.15 + 100)));
      }
    } else if (_revenueTimeRange == '1M') {
      xCount = 30;
      final List<DateTime> dates = List.generate(30, (index) {
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - index));
      });
      xLabels = dates.map((d) => DateFormat('dd/MM').format(d)).toList();

      final Map<int, double> dailyRevenue = {};
      for (int i = 0; i < 30; i++) {
        final date = dates[i];
        double total = 0.0;
        for (var order in completedOrders) {
          if (order.createdAt != null) {
            final orderDate = order.createdAt!.toDate();
            if (orderDate.year == date.year &&
                orderDate.month == date.month &&
                orderDate.day == date.day) {
              total += order.totalPrice;
            }
          }
        }
        dailyRevenue[i] = total;
        if (total > 0) hasAnyRealData = true;
      }

      for (int i = 0; i < 30; i++) {
        double val = dailyRevenue[i] ?? 0.0;
        if (!hasAnyRealData && completedOrders.isEmpty) {
          val = 300.0 + 100.0 * (i % 7) + 30.0 * (i % 3) + i * 5;
        }
        spots.add(FlSpot(i.toDouble(), val));
        targetSpots.add(FlSpot(i.toDouble(), (!hasAnyRealData && completedOrders.isEmpty) ? (380.0 + 100.0 * (i % 7) + i * 5) : (val * 1.15 + 100)));
      }
    } else {
      // 1Y
      xCount = 12;
      final List<DateTime> dates = List.generate(12, (index) {
        return DateTime(now.year, now.month - (11 - index), 1);
      });
      xLabels = dates.map((d) => DateFormat('MMM').format(d)).toList();

      final Map<int, double> monthlyRevenue = {};
      for (int i = 0; i < 12; i++) {
        final date = dates[i];
        double total = 0.0;
        for (var order in completedOrders) {
          if (order.createdAt != null) {
            final orderDate = order.createdAt!.toDate();
            if (orderDate.year == date.year && orderDate.month == date.month) {
              total += order.totalPrice;
            }
          }
        }
        monthlyRevenue[i] = total;
        if (total > 0) hasAnyRealData = true;
      }

      final List<double> mockActualValues = [4500, 5200, 4800, 6100, 5800, 7200, 6900, 8100, 7800, 9500, 8900, 11200];
      final List<double> mockTargetValues = [5000, 5500, 6000, 6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000, 11000];

      for (int i = 0; i < 12; i++) {
        double val = monthlyRevenue[i] ?? 0.0;
        if (!hasAnyRealData && completedOrders.isEmpty) {
          val = mockActualValues[i];
        }
        spots.add(FlSpot(i.toDouble(), val));
        targetSpots.add(FlSpot(i.toDouble(), (!hasAnyRealData && completedOrders.isEmpty) ? mockTargetValues[i] : (val * 1.15 + 300)));
      }
    }

    double maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    double targetMaxVal = targetSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    double maxLimit = (maxVal > targetMaxVal ? maxVal : targetMaxVal) * 1.2;
    if (maxLimit < 100) maxLimit = 1000;

    final bool isDemoMode = completedOrders.isEmpty && !hasAnyRealData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _revenueTimeRange == '1W'
                        ? 'Revenue Trend (7 Days)'
                        : _revenueTimeRange == '1M'
                            ? 'Revenue Trend (30 Days)'
                            : 'Revenue Trend (12 Months)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    isDemoMode ? 'Showing Demo Trajectory' : 'Calculated from delivered orders',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F2E) : const Color(0xFFF1F1F5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  _buildTimeRangeButton('1W', '1W', isDark),
                  _buildTimeRangeButton('1M', '1M', isDark),
                  _buildTimeRangeButton('1Y', '1Y', isDark),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.8,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFEAEAEA),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final intIndex = value.toInt();
                      if (intIndex < 0 || intIndex >= xCount) return const SizedBox();
                      
                      // For 1M, show labels every 5 days to prevent cluttering
                      if (_revenueTimeRange == '1M' && intIndex % 5 != 0 && intIndex != xCount - 1) {
                        return const SizedBox();
                      }
                      
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          xLabels[intIndex],
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (xCount - 1).toDouble(),
              minY: 0,
              maxY: maxLimit,
              lineBarsData: [
                // Target Trend (Dashed)
                LineChartBarData(
                  spots: targetSpots,
                  isCurved: true,
                  color: Colors.grey.withOpacity(0.5),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  dashArray: [6, 4],
                ),
                // Actual Sales
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).primaryColor,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.25),
                        Theme.of(context).primaryColor.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => isDark ? const Color(0xFF1E1E2F) : Colors.white,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      return LineTooltipItem(
                        '\$${touchedSpot.y.toStringAsFixed(2)}',
                        TextStyle(
                          color: touchedSpot.barIndex == 1 ? Theme.of(context).primaryColor : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDonutChart(List<OrderModel> allOrders, bool isDark) {
    int pendingCount = 0;
    int shippingCount = 0;
    int deliveredCount = 0;
    int cancelledCount = 0;

    for (var order in allOrders) {
      switch (order.status.toLowerCase()) {
        case 'pending':
          pendingCount++;
          break;
        case 'shipping':
        case 'delivering':
          shippingCount++;
          break;
        case 'delivered':
        case 'completed':
          deliveredCount++;
          break;
        case 'cancelled':
          cancelledCount++;
          break;
      }
    }

    final bool hasNoOrders = allOrders.isEmpty;

    // Use Mock Data if empty
    final double pendingVal = hasNoOrders ? 20.0 : pendingCount.toDouble();
    final double shippingVal = hasNoOrders ? 30.0 : shippingCount.toDouble();
    final double deliveredVal = hasNoOrders ? 40.0 : deliveredCount.toDouble();
    final double cancelledVal = hasNoOrders ? 10.0 : cancelledCount.toDouble();

    final totalValue = pendingVal + shippingVal + deliveredVal + cancelledVal;

    List<PieChartSectionData> sections = [
      PieChartSectionData(
        color: Colors.orange,
        value: pendingVal,
        title: '${((pendingVal / totalValue) * 100).toStringAsFixed(0)}%',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.blue,
        value: shippingVal,
        title: '${((shippingVal / totalValue) * 100).toStringAsFixed(0)}%',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.green,
        value: deliveredVal,
        title: '${((deliveredVal / totalValue) * 100).toStringAsFixed(0)}%',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: cancelledVal,
        title: '${((cancelledVal / totalValue) * 100).toStringAsFixed(0)}%',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Status Distribution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  hasNoOrders ? 'Showing Demo Breakdown' : 'Based on real checkout history',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 45,
                        sections: sections,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hasNoOrders ? '100' : '${allOrders.length}',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          ),
                          const Text('Orders', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPieLegendItem('Pending', Colors.orange, hasNoOrders ? 20 : pendingCount),
                  const SizedBox(height: 6),
                  _buildPieLegendItem('Shipping', Colors.blue, hasNoOrders ? 30 : shippingCount),
                  const SizedBox(height: 6),
                  _buildPieLegendItem('Delivered', Colors.green, hasNoOrders ? 40 : deliveredCount),
                  const SizedBox(height: 6),
                  _buildPieLegendItem('Cancelled', Colors.red, hasNoOrders ? 10 : cancelledCount),
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildBrandsBarChart(List<OrderModel> allOrders, bool isDark) {
    final Map<String, int> brandSales = {};
    for (var order in allOrders) {
      for (var item in order.items) {
        String brand = 'Other';
        final nameLower = item.productName.toLowerCase();
        if (nameLower.contains('nike') || item.productId.contains('nike')) {
          brand = 'Nike';
        } else if (nameLower.contains('adidas') || item.productId.contains('adidas')) {
          brand = 'Adidas';
        } else if (nameLower.contains('vans') || item.productId.contains('vans')) {
          brand = 'Vans';
        } else if (nameLower.contains('jordan') || item.productId.contains('jordan')) {
          brand = 'Jordan';
        }
        brandSales[brand] = (brandSales[brand] ?? 0) + item.quantity;
      }
    }

    final bool hasNoSales = brandSales.isEmpty;
    final List<String> brands = ['Nike', 'Adidas', 'Vans', 'Jordan'];
    final Map<String, double> displaySales = {};

    if (hasNoSales) {
      displaySales['Nike'] = 45;
      displaySales['Adidas'] = 32;
      displaySales['Vans'] = 18;
      displaySales['Jordan'] = 27;
    } else {
      for (var b in brands) {
        displaySales[b] = (brandSales[b] ?? 0).toDouble();
      }
    }

    double maxVal = displaySales.values.reduce((a, b) => a > b ? a : b);
    if (maxVal < 10) maxVal = 10;

    final List<BarChartGroupData> barGroups = List.generate(brands.length, (index) {
      final brandName = brands[index];
      final val = displaySales[brandName] ?? 0.0;
      
      Color barColor = Theme.of(context).primaryColor;
      if (brandName == 'Adidas') barColor = Colors.teal;
      if (brandName == 'Vans') barColor = Colors.deepPurple;
      if (brandName == 'Jordan') barColor = Colors.orange;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: val,
            gradient: LinearGradient(
              colors: [barColor, barColor.withOpacity(0.7)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          )
        ],
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Popular Product Brands',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  hasNoSales ? 'Showing Demo Sales' : 'Units sold by brand name',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.8,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.25,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFEAEAEA),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final intIndex = value.toInt();
                      if (intIndex < 0 || intIndex >= brands.length) return const SizedBox();
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          brands[intIndex],
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => isDark ? const Color(0xFF1E1E2F) : Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${brands[groupIndex]}: ${rod.toY.toInt()} units',
                      TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegendItem(String label, Color color, bool isDashed) {
    return Row(
      children: [
        if (isDashed)
          Row(
            children: List.generate(
              3,
              (index) => Container(
                width: 4,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: color,
              ),
            ),
          )
        else
          Container(
            width: 12,
            height: 4,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPieLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ],
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161622) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF232332) : const Color(0xFFEEEEF4);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Dashboard Overview'),
            Text(
              'Welcome Back, Admin',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.storefront_outlined),
          tooltip: 'Back to Shop',
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => context.read<AdminCubit>().loadAnalytics(),
          ),
        ],
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<AdminCubit>().loadAnalytics(),
                      child: const Text('Try Again'),
                    )
                  ],
                ),
              ),
            );
          }
          if (state is AdminAnalyticsLoaded) {
            final double totalRevenue = state.totalRevenue;
            final int totalOrdersCount = state.allOrders.length;
            final double aov = totalOrdersCount > 0 ? (totalRevenue / (state.completedOrders.isEmpty ? 1 : state.completedOrders.length)) : 0.0;
            final int pendingOrders = state.allOrders.where((o) => o.status == 'pending' || o.status == 'shipping').length;

            return RefreshIndicator(
              onRefresh: () => context.read<AdminCubit>().loadAnalytics(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- KPI Cards Grid ---
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            // Revenue Card (Gradient)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Theme.of(context).primaryColor, const Color(0xFFFF7E6B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Revenue',
                                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      const Icon(Icons.monetization_on_outlined, color: Colors.white, size: 20),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FittedBox(
                                        child: Text(
                                          '\$${totalRevenue.toStringAsFixed(2)}',
                                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Delivered sales',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            // Total Orders Card (Gradient Teal)
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.teal, Color(0xFF4DB6AC)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Orders',
                                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$totalOrdersCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'All transactions',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            // Average Order Value Card (Standard Dark/Light Card)
                            Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Avg. Value',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      Icon(Icons.query_stats_outlined, color: Theme.of(context).primaryColor, size: 20),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FittedBox(
                                        child: Text(
                                          '\$${aov.toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Per delivered order',
                                        style: TextStyle(color: Colors.grey, fontSize: 10),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            // Active Orders Card
                            Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Active Orders',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 20),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$pendingOrders',
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Pending shipment',
                                        style: TextStyle(color: Colors.grey, fontSize: 10),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Dynamic Charts Section ---
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Segmented Switcher UI
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F1F2E) : const Color(0xFFF1F1F5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(child: _buildChartTabButton(0, 'Revenue', isDark)),
                                Expanded(child: _buildChartTabButton(1, 'Status', isDark)),
                                Expanded(child: _buildChartTabButton(2, 'Brands', isDark)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Active Chart Rendering
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _selectedChartIndex == 0
                                ? _buildRevenueLineChart(state.completedOrders, isDark)
                                : _selectedChartIndex == 1
                                    ? _buildStatusDonutChart(state.allOrders, isDark)
                                    : _buildBrandsBarChart(state.allOrders, isDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Quick Actions Header ---
                    const Text(
                      'Quick Admin Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // --- Actions Grid ---
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.3,
                      children: [
                        _buildActionTile(
                          context: context,
                          icon: Icons.inventory_2_outlined,
                          iconBg: const Color(0xFFFFEAE6),
                          iconColor: const Color(0xFFFF4C3B),
                          title: 'Products',
                          subtitle: 'Catalog & stocks',
                          onTap: () async {
                            await context.push('/admin/products');
                            if (context.mounted) {
                              context.read<AdminCubit>().loadAnalytics();
                            }
                          },
                        ),
                        _buildActionTile(
                          context: context,
                          icon: Icons.receipt_long_outlined,
                          iconBg: const Color(0xFFE0F2F1),
                          iconColor: Colors.teal,
                          title: 'Orders',
                          subtitle: 'Process deliveries',
                          onTap: () async {
                            await context.push('/admin/orders');
                            if (context.mounted) {
                              context.read<AdminCubit>().loadAnalytics();
                            }
                          },
                        ),
                        _buildActionTile(
                          context: context,
                          icon: Icons.chat_outlined,
                          iconBg: const Color(0xFFE8EAF6),
                          iconColor: Colors.indigo,
                          title: 'Customer Chats',
                          subtitle: 'Live support hub',
                          onTap: () {
                            context.go('/chat');
                          },
                        ),
                        _buildActionTile(
                          context: context,
                          icon: Icons.store_outlined,
                          iconBg: const Color(0xFFEDE7F6),
                          iconColor: Colors.deepPurple,
                          title: 'Store Maps',
                          subtitle: 'Manage branches',
                          onTap: () {
                            context.push('/admin/stores');
                          },
                        ),
                        _buildActionTile(
                          context: context,
                          icon: Icons.local_offer_outlined,
                          iconBg: const Color(0xFFFFF3E0),
                          iconColor: Colors.orange,
                          title: 'Vouchers',
                          subtitle: 'Discounts & coupons',
                          onTap: () {
                            context.push('/admin/vouchers');
                          },
                        ),
                        _buildActionTile(
                          context: context,
                          icon: Icons.cloud_download_outlined,
                          iconBg: const Color(0xFFE1F5FE),
                          iconColor: Colors.lightBlue,
                          title: 'Seed Data',
                          subtitle: 'Populate Firebase',
                          onTap: () {
                            seedFirebaseData(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // --- Recent Completed Orders Header ---
                    const Text(
                      'Recent Orders Activity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // --- Polished Recent Orders List ---
                    if (state.allOrders.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: cardColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text('No orders recorded yet.', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.allOrders.take(5).length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                          itemBuilder: (context, index) {
                            final order = state.allOrders[index];
                            final initials = _getInitials(order.customerName);
                            final avatarGrad = _getAvatarGradient(order.customerName);
                            final statusCol = _getStatusColor(order.status);
                            final formattedDate = order.createdAt != null
                                ? DateFormat('dd MMM, hh:mm a').format(order.createdAt!.toDate())
                                : '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: avatarGrad,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: avatarGrad.colors.first.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                              title: Text(
                                order.customerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: #${order.orderId.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${order.totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  // Soft badge indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusCol.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      order.status.toUpperCase(),
                                      style: TextStyle(color: statusCol, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                              onTap: () {
                                // Direct to orders management page
                                context.push('/admin/orders');
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
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

  // --- Sub-widgets for Segmented Controls & Action Items ---

  Widget _buildChartTabButton(int index, String title, bool isDark) {
    final bool isSelected = _selectedChartIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C2C3E) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161622) : Colors.white,
          border: Border.all(color: isDark ? const Color(0xFF232332) : const Color(0xFFEEEEF4)),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? iconColor.withOpacity(0.12) : iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 16,
            )
          ],
        ),
      ),
    );
  }
}
