import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import 'product_detail_screen.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({Key? key}) : super(key: key);

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  // Filter State
  RangeValues _priceRange = const RangeValues(0, 2000);
  List<int> _selectedSizes = [];
  List<String> _selectedColors = [];
  List<String> _selectedBrands = [];
  double? _selectedRating;
  String _sortBy = 'latest'; // Default sort

  final List<int> _sizes = [38, 39, 40, 41, 42, 43, 44];
  final List<String> _colors = ['Red', 'Blue', 'Black', 'White', 'Green'];
  final List<String> _brands = ['All', 'Nike', 'Adidas', 'Puma', 'Vans', 'Converse'];

  @override
  void initState() {
    super.initState();
    // Trigger initial fetch
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    context.read<ProductCubit>().searchProducts(
      searchQuery: _searchController.text,
      brands: _selectedBrands.isEmpty ? null : _selectedBrands,
      sizes: _selectedSizes,
      colors: _selectedColors,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      minRating: _selectedRating,
      sortBy: _sortBy,
    );
  }

  void _clearFilters(StateSetter setModalState) {
    setModalState(() {
      _priceRange = const RangeValues(0, 2000);
      _selectedSizes.clear();
      _selectedColors.clear();
      _selectedBrands.clear();
      _selectedRating = null;
    });
    setState(() {
      _priceRange = const RangeValues(0, 2000);
      _selectedSizes.clear();
      _selectedColors.clear();
      _selectedBrands.clear();
      _selectedRating = null;
    });
    _performSearch();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      final status = await Permission.microphone.request();

      if (status.isGranted) {
        bool available = await _speech.initialize(
          onStatus: (val) {
            if (val == 'done' || val == 'notListening') {
              setState(() => _isListening = false);
            }
          },
          onError: (val) => setState(() => _isListening = false),
        );
        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (val) {
              setState(() {
                _searchController.text = val.recognizedWords;
              });
              // Auto trigger search on voice recognition update
              _performSearch();
            },
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable Microphone access in Settings to use Voice Search.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  String _getSortLabel(String value) {
    switch(value) {
      case 'latest': return 'Latest';
      case 'price_asc': return 'Price: Low to High';
      case 'price_desc': return 'Price: High to Low';
      case 'sales': return 'Top Sales';
      default: return 'Latest';
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => _clearFilters(setModalState),
                          child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Brand (Multi-select)
                    const Text('Brand (Multi-select)', style: TextStyle(fontWeight: FontWeight.w600)),
                    Wrap(
                      spacing: 8,
                      children: _brands.map((brand) {
                        final isAll = brand == 'All';
                        final isSelected = isAll ? _selectedBrands.isEmpty : _selectedBrands.contains(brand);

                        return ChoiceChip(
                          label: Text(brand),
                          selected: isSelected,
                          onSelected: (selected) {
                            void updateSelection() {
                              if (isAll) {
                                _selectedBrands.clear();
                              } else {
                                if (selected) {
                                  if (!_selectedBrands.contains(brand)) _selectedBrands.add(brand);
                                  // Auto-select 'All' if all specific brands are selected
                                  if (_selectedBrands.length == _brands.length - 1) {
                                    _selectedBrands.clear();
                                  }
                                } else {
                                  _selectedBrands.remove(brand);
                                }
                              }
                            }
                            setModalState(updateSelection);
                            setState(updateSelection);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price Range
                    const Text('Price Range', style: TextStyle(fontWeight: FontWeight.w600)),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 2000,
                      divisions: 20,
                      labels: RangeLabels('\$${_priceRange.start.round()}', '\$${_priceRange.end.round()}'),
                      onChanged: (values) {
                        setModalState(() => _priceRange = values);
                        setState(() => _priceRange = values);
                      },
                    ),
                    
                    // Rating
                    const SizedBox(height: 16),
                    const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                    Slider(
                      value: _selectedRating ?? 0,
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: '${_selectedRating ?? 0} Stars',
                      onChanged: (val) {
                        setModalState(() => _selectedRating = val == 0 ? null : val);
                        setState(() => _selectedRating = val == 0 ? null : val);
                      },
                    ),

                    // Sizes (Multi-select)
                    const SizedBox(height: 16),
                    const Text('Sizes (Multi-select)', style: TextStyle(fontWeight: FontWeight.w600)),
                    Wrap(
                      spacing: 8,
                      children: _sizes.map((size) {
                        final isSelected = _selectedSizes.contains(size);
                        return ChoiceChip(
                          label: Text(size.toString()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedSizes.add(size);
                              } else {
                                _selectedSizes.remove(size);
                              }
                            });
                            setState(() {
                              if (selected) {
                                if (!_selectedSizes.contains(size)) _selectedSizes.add(size);
                              } else {
                                _selectedSizes.remove(size);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    // Colors (Multi-select)
                    const SizedBox(height: 16),
                    const Text('Colors (Multi-select)', style: TextStyle(fontWeight: FontWeight.w600)),
                    Wrap(
                      spacing: 8,
                      children: _colors.map((color) {
                        final isSelected = _selectedColors.contains(color);
                        return ChoiceChip(
                          label: Text(color),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedColors.add(color);
                              } else {
                                _selectedColors.remove(color);
                              }
                            });
                            setState(() {
                              if (selected) {
                                if (!_selectedColors.contains(color)) _selectedColors.add(color);
                              } else {
                                _selectedColors.remove(color);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performSearch();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filter'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      // Trigger search as user types
                      _performSearch();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search for sneakers (e.g. nike, ike)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : Colors.grey),
                        onPressed: _listen,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.tune),
                  color: Colors.blue,
                  onPressed: _openFilterSheet,
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sort by:', style: TextStyle(fontSize: 16)),
                PopupMenuButton<String>(
                  initialValue: _sortBy,
                  onSelected: (val) {
                    setState(() => _sortBy = val);
                    _performSearch();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'latest', child: Text('Latest')),
                    PopupMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                    PopupMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                    PopupMenuItem(value: 'sales', child: Text('Top Sales')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(_getSortLabel(_sortBy), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Expanded(
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ProductError) {
                  return Center(child: Text(state.message));
                } else if (state is ProductsLoaded) {
                  final products = state.products;
                  if (products.isEmpty) {
                    return const Center(
                      child: Text('No products found matching your criteria.',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  ),
                                  child: product.images.isEmpty
                                      ? const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))
                                      : ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                          child: Image.network(product.images.first, fit: BoxFit.cover, width: double.infinity),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text('\$${product.basePrice.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: Colors.orange),
                                        Text('${product.averageRating.toStringAsFixed(1)} (${product.reviewCount})', style: const TextStyle(fontSize: 12)),
                                      ],
                                    )
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
                return const Center(child: Text('Enter a search term or apply filters.'));
              },
            ),
          )
        ],
      ),
    );
  }
}
