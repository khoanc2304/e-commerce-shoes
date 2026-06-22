import 'dart:io';

void main() {
  final files = [
    'lib/features/product/presentation/pages/search_filter_screen.dart',
    'lib/features/product/presentation/pages/product_detail_screen.dart',
    'lib/features/product/presentation/pages/product_comparison_screen.dart',
    'lib/features/orders/presentation/pages/user_orders_screen.dart',
    'lib/features/orders/presentation/pages/order_history_screen.dart',
    'lib/features/chat/presentation/widgets/product_message_bubble.dart',
    'lib/features/cart/presentation/pages/checkout_screen.dart',
    'lib/features/cart/presentation/pages/cart_screen.dart',
    'lib/features/admin/presentation/pages/admin_orders_screen.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    if (content.contains('Image.network')) {
      content = content.replaceAll('Image.network(', 'CustomImageView(imageUrl: ');
      
      // Calculate depth to import custom_image_view.dart
      int depth = path.split('/').length - 2;
      String importPath = "import '${'../' * depth}core/widgets/custom_image_view.dart';\n";
      
      if (!content.contains('custom_image_view.dart')) {
        // Insert after first import
        final firstImportIdx = content.indexOf('import ');
        if (firstImportIdx != -1) {
          content = content.substring(0, firstImportIdx) + importPath + content.substring(firstImportIdx);
        }
      }
      
      file.writeAsStringSync(content);
      print('Updated \$path');
    }
  }
}
