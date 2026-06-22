import '../../../../core/widgets/custom_image_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/product/data/repositories/product_repository.dart';

class ProductMessageBubble extends StatelessWidget {
  final Map<String, dynamic> productPayload;
  final bool isMe;

  const ProductMessageBubble({
    Key? key,
    required this.productPayload,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String productId = productPayload['productId'] ?? '';
    final String name = productPayload['name'] ?? 'Unknown Product';
    final double price = (productPayload['price'] as num?)?.toDouble() ?? 0.0;
    final String imageUrl = productPayload['imageUrl'] ?? '';

    return GestureDetector(
      onTap: () async {
        if (productId.isNotEmpty) {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );
          
          try {
            final product = await ProductRepository().getProductById(productId);
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pop(); // close loading properly
              if (product != null) {
                context.push('/home/product', extra: product);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product not found or unavailable')));
              }
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pop(); // close loading properly
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load product: $e')));
            }
          }
        }
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageView(
                  imageUrl: imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.image)),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.touch_app, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('Tap to view details', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
