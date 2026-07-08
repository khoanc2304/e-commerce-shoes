import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../voucher/presentation/cubit/voucher_cubit.dart';
import '../../../voucher/presentation/cubit/voucher_state.dart';
import '../../../voucher/data/models/coupon_model.dart';

class VoucherSelectionBottomSheet extends StatefulWidget {
  final double subTotal;

  const VoucherSelectionBottomSheet({Key? key, required this.subTotal}) : super(key: key);

  @override
  State<VoucherSelectionBottomSheet> createState() => _VoucherSelectionBottomSheetState();
}

class _VoucherSelectionBottomSheetState extends State<VoucherSelectionBottomSheet> {
  final TextEditingController _manualCodeController = TextEditingController();

  void _onApplyManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isNotEmpty) {
      Navigator.pop(context, code);
    }
  }

  void _onSelectVoucher(CouponModel voucher) {
    if (widget.subTotal >= voucher.minOrderValue) {
      Navigator.pop(context, voucher.code);
    }
  }

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Voucher',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Manual Entry
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter Voucher Code',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1C1C2A) : const Color(0xFFF5F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _onApplyManualCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.1), height: 1),
          
          // Voucher List
          Expanded(
            child: BlocBuilder<VoucherCubit, VoucherState>(
              builder: (context, state) {
                if (state is VoucherLoading && state is! VoucherLoaded) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is VoucherError && state is! VoucherLoaded) {
                  return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                } else if (state is VoucherLoaded) {
                  // Filter out inactive or fully used coupons
                  final activeVouchers = state.vouchers.where((v) => v.isActive).toList();
                  
                  if (activeVouchers.isEmpty) {
                    return Center(
                      child: Text(
                        'No vouchers available right now.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: activeVouchers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final voucher = activeVouchers[index];
                      final isEligible = widget.subTotal >= voucher.minOrderValue;
                      final isExpired = voucher.expiryDate != null && voucher.expiryDate!.toDate().isBefore(DateTime.now());
                      final isFullyUsed = voucher.maxUsage > 0 && voucher.usageCount >= voucher.maxUsage;
                      
                      final bool canUse = isEligible && !isExpired && !isFullyUsed;

                      String discountText = voucher.discountType == 'percentage'
                          ? '${voucher.discountValue.toStringAsFixed(0)}%'
                          : '\$${voucher.discountValue.toStringAsFixed(2)}';

                      return InkWell(
                        onTap: canUse ? () => _onSelectVoucher(voucher) : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: canUse 
                                ? (isDark ? const Color(0xFF1C1C2A) : const Color(0xFFF5F5F9))
                                : (isDark ? const Color(0xFF1C1C2A).withOpacity(0.5) : const Color(0xFFF5F5F9).withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: canUse ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: canUse ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.local_offer,
                                  color: canUse ? Theme.of(context).primaryColor : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          voucher.code,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: canUse ? Theme.of(context).colorScheme.onSurface : Colors.grey,
                                          ),
                                        ),
                                        if (canUse)
                                          Text(
                                            'Apply',
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Discount $discountText off',
                                      style: TextStyle(
                                        color: canUse ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (voucher.minOrderValue > 0)
                                      Text(
                                        'Min. spend: \$${voucher.minOrderValue.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: !isEligible ? Colors.red : (canUse ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Colors.grey),
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (isExpired)
                                      const Text(
                                        'Expired',
                                        style: TextStyle(color: Colors.red, fontSize: 12),
                                      )
                                    else if (voucher.expiryDate != null)
                                      Text(
                                        'Expires: ${DateFormat('dd MMM yyyy').format(voucher.expiryDate!.toDate())}',
                                        style: TextStyle(
                                          color: canUse ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (isFullyUsed)
                                      const Text(
                                        'Usage limit reached',
                                        style: TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
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
          ),
        ],
      ),
    );
  }
}
