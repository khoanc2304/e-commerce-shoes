import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../cubit/voucher_cubit.dart';
import '../cubit/voucher_state.dart';

class VoucherListScreen extends StatelessWidget {
  const VoucherListScreen({Key? key}) : super(key: key);

  void _showDeleteConfirmDialog(BuildContext context, String couponId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Voucher'),
        content: const Text('Are you sure you want to permanently delete this voucher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VoucherCubit>().deleteVoucher(couponId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vouchers'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/vouchers/add_edit'),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<VoucherCubit, VoucherState>(
        listenWhen: (previous, current) => current is VoucherOperationSuccess || (current is VoucherError && previous is VoucherLoaded),
        listener: (context, state) {
          if (state is VoucherOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
          } else if (state is VoucherError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        buildWhen: (previous, current) => current is VoucherLoaded || current is VoucherLoading || current is VoucherError,
        builder: (context, state) {
          if (state is VoucherLoading && state is! VoucherLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VoucherError && state is! VoucherLoaded) {
            return Center(child: Text(state.message));
          }
          if (state is VoucherLoaded) {
            final vouchers = state.vouchers;
            if (vouchers.isEmpty) {
              return const Center(child: Text('No vouchers found. Click + to add one.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // padding for FAB
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                final voucher = vouchers[index];
                
                String discountText = voucher.discountType == 'percentage'
                    ? '${voucher.discountValue.toStringAsFixed(0)}%'
                    : '\$${voucher.discountValue.toStringAsFixed(2)}';

                String usageText = voucher.maxUsage > 0
                    ? '${voucher.usageCount} / ${voucher.maxUsage}'
                    : '${voucher.usageCount} / ∞';

                String expiryText = voucher.expiryDate != null
                    ? DateFormat('dd MMM yyyy').format(voucher.expiryDate!.toDate())
                    : 'No expiry';
                
                bool isExpired = voucher.expiryDate != null && voucher.expiryDate!.toDate().isBefore(DateTime.now());

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_offer, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                Text(
                                  voucher.code,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    decoration: voucher.isActive ? null : TextDecoration.lineThrough,
                                    color: voucher.isActive ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: voucher.isActive,
                              onChanged: (val) {
                                context.read<VoucherCubit>().toggleVoucherStatus(voucher);
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Discount: $discountText', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('Min Order: \$${voucher.minOrderValue.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Usage: $usageText', style: TextStyle(color: voucher.maxUsage > 0 && voucher.usageCount >= voucher.maxUsage ? Colors.red : Colors.black87)),
                            Text('Expires: $expiryText', style: TextStyle(color: isExpired ? Colors.red : Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                context.push('/admin/vouchers/add_edit', extra: voucher);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmDialog(context, voucher.couponId),
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
          return const SizedBox();
        },
      ),
    );
  }
}
