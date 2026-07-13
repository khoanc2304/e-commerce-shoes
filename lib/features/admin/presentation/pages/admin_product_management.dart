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
  
  final List<File> _selectedImages = [];
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
          decoration: const InputDecoration(hintText: 'Enter value'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image for new product'), backgroundColor: Colors.red),
        );
        return;
      }

      if (_selectedSizes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one size'), backgroundColor: Colors.red),
        );
        return;
      }

      if (_selectedColors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one color'), backgroundColor: Colors.red),
        );
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

  Widget _buildSectionCard({required String title, required List<Widget> children, required Color cardColor, required Color borderColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161622) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF232332) : const Color(0xFFEEEEF4);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add New Product'),
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context); // Go back
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
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
                  // Section 1: Basic Information
                  _buildSectionCard(
                    title: 'Basic Details',
                    cardColor: cardColor,
                    borderColor: borderColor,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          hintText: 'e.g. Nike Air Max 90',
                        ),
                        validator: (val) => val!.trim().isEmpty ? 'Product name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedBrand,
                        decoration: const InputDecoration(
                          labelText: 'Select Brand',
                        ),
                        items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBrand = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Product Description',
                          hintText: 'Enter detailed features and material details...',
                        ),
                        maxLines: 4,
                        validator: (val) => val!.trim().isEmpty ? 'Description is required' : null,
                      ),
                    ],
                  ),

                  // Section 2: Pricing & Inventory
                  _buildSectionCard(
                    title: 'Pricing & Inventory',
                    cardColor: cardColor,
                    borderColor: borderColor,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price (\$)',
                                hintText: '0.00',
                                prefixIcon: Icon(Icons.attach_money, size: 20),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val!.trim().isEmpty) return 'Required';
                                if (double.tryParse(val.trim()) == null) return 'Invalid price';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: const InputDecoration(
                                labelText: 'Initial Stock',
                                hintText: '10',
                                prefixIcon: Icon(Icons.inventory, size: 20),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val!.trim().isEmpty) return 'Required';
                                if (int.tryParse(val.trim()) == null) return 'Must be integer';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Section 3: Product Attributes (Sizes & Colors)
                  _buildSectionCard(
                    title: 'Product Variants',
                    cardColor: cardColor,
                    borderColor: borderColor,
                    children: [
                      const Text(
                        'Available Shoe Sizes',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
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
                              avatar: const Icon(Icons.add, size: 16),
                              label: const Text('Other'),
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
                      const SizedBox(height: 20),
                      const Text(
                        'Available Colors',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
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
                              avatar: const Icon(Icons.add, size: 16),
                              label: const Text('Other'),
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
                    ],
                  ),

                  // Section 4: Media Upload (Visible on creation only)
                  if (widget.product == null)
                    _buildSectionCard(
                      title: 'Product Media',
                      cardColor: cardColor,
                      borderColor: borderColor,
                      children: [
                        const Text(
                          'Upload high-quality sneaker product images.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ..._selectedImages.map((file) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                                  Positioned(
                                    top: 2, right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedImages.remove(file)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )),
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[200],
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                                    SizedBox(height: 4),
                                    Text('Add', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitProduct,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(
                      widget.product != null ? 'Save Changes' : 'Publish Product',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
