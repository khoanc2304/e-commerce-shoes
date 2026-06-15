import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';

class ProductComparisonScreen extends StatelessWidget {
  final ProductModel product1;
  final ProductModel product2;

  const ProductComparisonScreen({
    Key? key,
    required this.product1,
    required this.product2,
  }) : super(key: key);

  Widget _buildImageCell(ProductModel product) {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey[200],
      child: product.images.isEmpty
          ? const Icon(Icons.image, size: 50, color: Colors.grey)
          : Image.network(product.images.first, fit: BoxFit.cover),
    );
  }

  Widget _buildAttributeRow(String title, String val1, String val2, {bool isHighlight = false}) {
    return Container(
      color: isHighlight ? Colors.blue.withOpacity(0.05) : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(val1, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(val2, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header row with Images
            Row(
              children: [
                const Expanded(flex: 1, child: SizedBox()), // Empty corner
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildImageCell(product1),
                      const SizedBox(height: 8),
                      Text(product1.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildImageCell(product2),
                      const SizedBox(height: 8),
                      Text(product2.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Attributes Matrix
            _buildAttributeRow(
              'Brand',
              product1.brand,
              product2.brand,
            ),
            const Divider(height: 1),
            _buildAttributeRow(
              'Price',
              '\$${product1.basePrice.toStringAsFixed(2)}',
              '\$${product2.basePrice.toStringAsFixed(2)}',
              isHighlight: true,
            ),
            const Divider(height: 1),
            _buildAttributeRow(
              'Rating',
              '${product1.averageRating.toStringAsFixed(1)} (${product1.reviewCount})',
              '${product2.averageRating.toStringAsFixed(1)} (${product2.reviewCount})',
            ),
            const Divider(height: 1),
            _buildAttributeRow(
              'Sales',
              product1.salesCount.toString(),
              product2.salesCount.toString(),
            ),
            const Divider(height: 1),
            _buildAttributeRow(
              'Sizes',
              product1.availableSizes.join(', '),
              product2.availableSizes.join(', '),
            ),
            const Divider(height: 1),
            _buildAttributeRow(
              'Colors',
              product1.colors.join(', '),
              product2.colors.join(', '),
            ),
            const Divider(height: 1),
            
            // Description (optional depending on space)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Desc.', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(product1.description, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(product2.description, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
