import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../product/data/models/product_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class AdminProductManagement extends StatefulWidget {
  final ProductModel? product;
  const AdminProductManagement({Key? key, this.product}) : super(key: key);

  @override
  State<AdminProductManagement> createState() => _AdminProductManagementState();
}

class _AdminProductManagementState extends State<AdminProductManagement> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedBrand = 'Nike'; // Default brand
  final List<String> _brands = ['Nike', 'Adidas', 'Puma', 'Vans', 'Converse'];
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController();
  
  final List<int> _availableSizes = [38, 39, 40, 41, 42, 43, 44];
  List<int> _selectedSizes = [39, 40, 41]; // Default selected sizes
  
  final List<String> _availableColors = ['Black', 'White', 'Red', 'Blue', 'Grey'];
  List<String> _selectedColors = ['Black']; // Default color
  
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _selectedBrand = _brands.contains(widget.product!.brand) ? widget.product!.brand : _brands.first;
      _priceController.text = widget.product!.basePrice.toString();
      _descController.text = widget.product!.description;
      _stockController.text = widget.product!.stock.toString();
      if (widget.product!.availableSizes.isNotEmpty) {
        _selectedSizes = List.from(widget.product!.availableSizes);
        for (var s in _selectedSizes) {
          if (!_availableSizes.contains(s)) _availableSizes.add(s);
        }
        _availableSizes.sort();
      }
      if (widget.product!.colors.isNotEmpty) {
        _selectedColors = List.from(widget.product!.colors);
        for (var c in _selectedColors) {
          if (!_availableColors.contains(c)) _availableColors.add(c);
        }
      }
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((pf) => File(pf.path)));
      });
    }
  }

  Future<void> _showAddDialog(String title, TextInputType keyboardType, Function(String) onAdd) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter value'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _submitProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      final isEditing = widget.product != null;
      if (!isEditing && _selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one image for new product')));
        return;
      }

      if (_selectedSizes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one size')));
        return;
      }

      if (_selectedColors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one color')));
        return;
      }

      if (isEditing) {
        final updatedProduct = widget.product!.copyWith(
          name: _nameController.text.trim(),
          brand: _selectedBrand,
          basePrice: double.parse(_priceController.text.trim()),
          description: _descController.text.trim(),
          stock: int.parse(_stockController.text.trim()),
          availableSizes: _selectedSizes,
          colors: _selectedColors,
        );
        context.read<AdminCubit>().updateProductDetails(updatedProduct);
      } else {
        final newProduct = ProductModel(
          productId: const Uuid().v4(),
          name: _nameController.text.trim(),
          brand: _selectedBrand,
          basePrice: double.parse(_priceController.text.trim()),
          description: _descController.text.trim(),
          images: [], // Will be populated by Cubit
          availableSizes: _selectedSizes,
          colors: _selectedColors,
          stock: int.parse(_stockController.text.trim()),
          salesCount: 0,
          averageRating: 0.0,
          reviewCount: 0,
          isActive: true,
        );

        context.read<AdminCubit>().createProductWithImages(newProduct, _selectedImages);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product != null ? 'Edit Product' : 'Add Product')),
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
                  DropdownButtonFormField<String>(
                    value: _selectedBrand,
                    decoration: const InputDecoration(labelText: 'Brand'),
                    items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBrand = val);
                    },
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
                  const SizedBox(height: 16),
                  const Text('Available Sizes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSizes.map<Widget>((size) {
                      final isSelected = _selectedSizes.contains(size);
                      return ChoiceChip(
                        label: Text(size.toString()),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSizes.add(size);
                              _selectedSizes.sort();
                            } else {
                              _selectedSizes.remove(size);
                            }
                          });
                        },
                      );
                    }).toList()
                      ..add(
                        ActionChip(
                          label: const Text('+ Other'),
                          onPressed: () {
                            _showAddDialog('Add Custom Size', TextInputType.number, (val) {
                              final size = int.tryParse(val);
                              if (size != null && !_availableSizes.contains(size)) {
                                setState(() {
                                  _availableSizes.add(size);
                                  _availableSizes.sort();
                                  _selectedSizes.add(size);
                                  _selectedSizes.sort();
                                });
                              }
                            });
                          },
                        ),
                      ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Available Colors', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableColors.map<Widget>((color) {
                      final isSelected = _selectedColors.contains(color);
                      return ChoiceChip(
                        label: Text(color),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedColors.add(color);
                            } else {
                              _selectedColors.remove(color);
                            }
                          });
                        },
                      );
                    }).toList()
                      ..add(
                        ActionChip(
                          label: const Text('+ Other'),
                          onPressed: () {
                            _showAddDialog('Add Custom Color', TextInputType.text, (val) {
                              if (!_availableColors.contains(val)) {
                                setState(() {
                                  _availableColors.add(val);
                                  _selectedColors.add(val);
                                });
                              }
                            });
                          },
                        ),
                      ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (widget.product == null) ...[
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
                  ],
                  
                  ElevatedButton(
                    onPressed: _submitProduct,
                    child: Text(widget.product != null ? 'Update Product' : 'Create Product'),
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
