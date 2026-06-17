import 'package:flutter/material.dart';
import '../../../product/data/models/store_model.dart';
import '../../../auth/presentation/pages/map_picker_screen.dart';

class AddStoreDialog extends StatefulWidget {
  final StoreModel? existingStore;
  final Function(StoreModel) onSave;

  const AddStoreDialog({
    Key? key,
    this.existingStore,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddStoreDialog> createState() => _AddStoreDialogState();
}

class _AddStoreDialogState extends State<AddStoreDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingStore?.name ?? '');
    _phoneController = TextEditingController(text: widget.existingStore?.phone ?? '');
    _addressController = TextEditingController(text: widget.existingStore?.address ?? '');
    
    _latitude = widget.existingStore?.latitude ?? 0.0;
    _longitude = widget.existingStore?.longitude ?? 0.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
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
        _addressController.text = result.fullAddress;
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingStore == null ? 'Add New Store' : 'Edit Store'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Store Name (e.g. Shues X - HN)'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
                readOnly: true,
                onTap: _pickLocation,
                validator: (value) => value == null || value.isEmpty ? 'Please pick a location from map' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.map, color: Colors.blue),
                label: const Text('Pick Location on Map'),
                onPressed: _pickLocation,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (_latitude == 0.0 || _longitude == 0.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please pick a valid location from the map')),
                );
                return;
              }
              
              final newStore = StoreModel(
                id: widget.existingStore?.id ?? '',
                name: _nameController.text.trim(),
                address: _addressController.text.trim(),
                latitude: _latitude,
                longitude: _longitude,
                phone: _phoneController.text.trim(),
              );
              
              widget.onSave(newStore);
              Navigator.pop(context);
            }
          },
          child: const Text('Save Store'),
        ),
      ],
    );
  }
}
