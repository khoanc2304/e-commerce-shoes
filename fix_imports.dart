import 'dart:io';

void main() {
  final files = [
    'lib/features/product/presentation/pages/search_filter_screen.dart',
    'lib/features/product/presentation/pages/product_detail_screen.dart',
    'lib/features/product/presentation/pages/product_comparison_screen.dart',
    'lib/features/product/presentation/pages/home_dashboard_screen.dart',
    'lib/features/orders/presentation/pages/user_orders_screen.dart',
    'lib/features/orders/presentation/pages/order_history_screen.dart',
    'lib/features/chat/presentation/widgets/product_message_bubble.dart',
    'lib/features/cart/presentation/pages/checkout_screen.dart',
    'lib/features/cart/presentation/pages/cart_screen.dart',
    'lib/features/admin/presentation/pages/admin_orders_screen.dart',
    'lib/features/admin/presentation/pages/admin_product_list_screen.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    // Fix imports
    final parts = path.split('/');
    final depth = parts.length - 2; 
    final correctImportPath = "'${'../' * depth}core/widgets/custom_image_view.dart'";
    
    // Find incorrect imports and replace
    final regex = RegExp(r"import \$correctImportPath;");
    if (regex.hasMatch(content)) {
      content = content.replaceAll(regex, "import " + correctImportPath + ";");
      file.writeAsStringSync(content);
      print('Fixed import in \$path');
    }
  }
}
