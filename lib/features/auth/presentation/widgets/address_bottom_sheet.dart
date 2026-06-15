import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import 'package:uuid/uuid.dart';

class AddressBottomSheet extends StatefulWidget {
  final ShippingAddress? existingAddress;
  final Function(ShippingAddress) onSave;

  const AddressBottomSheet({
    Key? key,
    this.existingAddress,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddressBottomSheet> createState() => _AddressBottomSheetState();
}

class _AddressBottomSheetState extends State<AddressBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _receiverNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressLineController;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _receiverNameController =
        TextEditingController(text: widget.existingAddress?.receiverName ?? '');
    _phoneController =
        TextEditingController(text: widget.existingAddress?.phoneNumber ?? '');
    _addressLineController =
        TextEditingController(text: widget.existingAddress?.addressLine ?? '');
    _cityController =
        TextEditingController(text: widget.existingAddress?.city ?? '');
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final newAddress = ShippingAddress(
        id: widget.existingAddress?.id ?? const Uuid().v4(),
        receiverName: _receiverNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        addressLine: _addressLineController.text.trim(),
        city: _cityController.text.trim(),
      );
      widget.onSave(newAddress);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existingAddress == null
                    ? 'Add New Address'
                    : 'Edit Address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _receiverNameController,
                decoration: const InputDecoration(labelText: 'Receiver Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a phone number'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressLineController,
                decoration:
                    const InputDecoration(labelText: 'Street Address / Apt'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter an address'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a city'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Address'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
