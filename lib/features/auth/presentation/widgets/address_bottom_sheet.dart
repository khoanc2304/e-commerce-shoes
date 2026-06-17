import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../pages/map_picker_screen.dart';
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
  late TextEditingController _districtController;
  late TextEditingController _wardController;
  String _selectedLabel = 'Home';
  bool _isDefault = false;
  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void initState() {
    super.initState();
    _receiverNameController =
        TextEditingController(text: widget.existingAddress?.receiverName ?? '');
    _phoneController =
        TextEditingController(text: widget.existingAddress?.phoneNumber ?? '');
    _addressLineController =
        TextEditingController(text: widget.existingAddress?.addressLine ?? '');
    _cityController = TextEditingController(text: widget.existingAddress?.city ?? '');
    _districtController = TextEditingController(text: widget.existingAddress?.district ?? '');
    _wardController = TextEditingController(text: widget.existingAddress?.ward ?? '');
    _selectedLabel = widget.existingAddress?.label ?? 'Home';
    _isDefault = widget.existingAddress?.isDefault ?? false;
    _latitude = widget.existingAddress?.latitude ?? 0.0;
    _longitude = widget.existingAddress?.longitude ?? 0.0;
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _wardController.dispose();
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
        district: _districtController.text.trim(),
        ward: _wardController.text.trim(),
        label: _selectedLabel,
        isDefault: _isDefault,
        latitude: _latitude,
        longitude: _longitude,
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.map, color: Colors.blue),
                label: const Text('Pick From Map'),
                onPressed: () async {
                  final result = await Navigator.push<MapPickerResult>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapPickerScreen(
                        initialLat: _latitude != 0.0 ? _latitude : null,
                        initialLng: _longitude != 0.0 ? _longitude : null,
                      ),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      _addressLineController.text = result.fullAddress;
                      _cityController.text = result.city;
                      _districtController.text = result.district;
                      _wardController.text = result.ward;
                      _latitude = result.latitude;
                      _longitude = result.longitude;
                    });
                  }
                },
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City/Province'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter city'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(labelText: 'District'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _wardController,
                      decoration: const InputDecoration(labelText: 'Ward'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedLabel,
                      decoration: const InputDecoration(labelText: 'Label'),
                      items: ['Home', 'Office', 'Other'].map((label) {
                        return DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLabel = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
