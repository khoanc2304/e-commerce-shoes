import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../voucher/data/models/coupon_model.dart';
import '../cubit/voucher_cubit.dart';
import '../cubit/voucher_state.dart';

class VoucherManagementScreen extends StatefulWidget {
  final CouponModel? voucher;

  const VoucherManagementScreen({Key? key, this.voucher}) : super(key: key);

  @override
  State<VoucherManagementScreen> createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _codeController;
  late TextEditingController _discountValueController;
  late TextEditingController _minOrderValueController;
  late TextEditingController _maxUsageController;
  
  String _discountType = 'percentage';
  bool _isActive = true;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.voucher?.code ?? '');
    _discountValueController = TextEditingController(text: widget.voucher?.discountValue.toString() ?? '');
    _minOrderValueController = TextEditingController(text: widget.voucher?.minOrderValue.toString() ?? '0');
    _maxUsageController = TextEditingController(text: widget.voucher?.maxUsage.toString() ?? '0');
    
    if (widget.voucher != null) {
      _discountType = widget.voucher!.discountType;
      _isActive = widget.voucher!.isActive;
      _expiryDate = widget.voucher!.expiryDate?.toDate();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _minOrderValueController.dispose();
    _maxUsageController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _saveVoucher() {
    if (_formKey.currentState!.validate()) {
      final discountValue = double.tryParse(_discountValueController.text.trim()) ?? 0;
      final minOrderValue = double.tryParse(_minOrderValueController.text.trim()) ?? 0;
      final maxUsage = int.tryParse(_maxUsageController.text.trim()) ?? 0;
      
      final voucher = CouponModel(
        couponId: widget.voucher?.couponId ?? const Uuid().v4(),
        code: _codeController.text.trim().toUpperCase(),
        discountType: _discountType,
        discountValue: discountValue,
        minOrderValue: minOrderValue,
        isActive: _isActive,
        expiryDate: _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        maxUsage: maxUsage,
        usageCount: widget.voucher?.usageCount ?? 0, // preserve usage count on edit
      );

      if (widget.voucher == null) {
        context.read<VoucherCubit>().createVoucher(voucher);
      } else {
        context.read<VoucherCubit>().updateVoucher(voucher);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.voucher != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Voucher' : 'Add Voucher'),
      ),
      body: BlocConsumer<VoucherCubit, VoucherState>(
        listener: (context, state) {
          if (state is VoucherOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
            context.pop(); // Go back to list
          } else if (state is VoucherError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(labelText: 'Voucher Code (e.g. SUMMER10)'),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a code' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _discountType,
                        decoration: const InputDecoration(labelText: 'Discount Type'),
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                          DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (\$)' )),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _discountType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _discountValueController,
                        decoration: const InputDecoration(labelText: 'Discount Value'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter a value';
                          final val = double.tryParse(value);
                          if (val == null || val <= 0) return 'Must be > 0';
                          if (_discountType == 'percentage' && val > 100) return 'Percentage cannot exceed 100';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minOrderValueController,
                        decoration: const InputDecoration(labelText: 'Minimum Order Value (\$)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter a value (0 for no min)';
                          if (double.tryParse(value) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maxUsageController,
                        decoration: const InputDecoration(labelText: 'Max Usage (0 = unlimited)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter a value';
                          if (int.tryParse(value) == null) return 'Invalid integer';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Expiry Date: ${_expiryDate != null ? DateFormat('dd MMM yyyy').format(_expiryDate!) : 'Not set'}', style: const TextStyle(fontSize: 16)),
                          TextButton(
                            onPressed: () => _selectExpiryDate(context),
                            child: const Text('Select Date'),
                          ),
                        ],
                      ),
                      if (_expiryDate != null)
                        TextButton(
                          onPressed: () => setState(() => _expiryDate = null),
                          child: const Text('Clear Expiry Date', style: TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Is Active'),
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state is VoucherLoading ? null : _saveVoucher,
                          child: state is VoucherLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isEditing ? 'Update Voucher' : 'Create Voucher'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state is VoucherLoading)
                 Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator())),
            ],
          );
        },
      ),
    );
  }
}
