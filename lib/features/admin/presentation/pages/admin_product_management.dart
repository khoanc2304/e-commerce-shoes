import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../product/data/models/product_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class AdminProductManagement extends StatefulWidget {
  const AdminProductManagement({Key? key}) : super(key: key);

  @override
  State<AdminProductManagement> createState() => _AdminProductManagementState();
}

class _AdminProductManagementState extends State<AdminProductManagement> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController();
  
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((pf) => File(pf.path)));
      });
    }
  }

  void _submitProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one image')));
        return;
      }

      final newProduct = ProductModel(
        productId: const Uuid().v4(),
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        basePrice: double.parse(_priceController.text.trim()),
        description: _descController.text.trim(),
        images: [], // Will be populated by Cubit
        availableSizes: [38, 39, 40, 41, 42], // Mock sizes
        colors: ['Black', 'White'], // Mock colors
        stock: int.parse(_stockController.text.trim()),
        salesCount: 0,
        averageRating: 0.0,
        reviewCount: 0,
      );

      context.read<AdminCubit>().createProductWithImages(newProduct, _selectedImages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
            Navigator.pop(context); // Go back
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Product Name'),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Brand'),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: const InputDecoration(labelText: 'Initial Stock'),
                          keyboardType: TextInputType.number,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 4,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // Image Picker
                  const Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._selectedImages.map((file) => Stack(
                        children: [
                          Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                          Positioned(
                            top: 0, right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.remove(file)),
                              child: const Icon(Icons.cancel, color: Colors.red),
                            ),
                          )
                        ],
                      )),
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 80, height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.add_a_photo),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _submitProduct,
                    child: const Text('Create Product'),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
