import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../../../../core/widgets/custom_image_view.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({Key? key}) : super(key: key);

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadAllProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<AdminCubit>().loadMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/admin/products/add_edit');
            },
          )
        ],
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listenWhen: (previous, current) => current is AdminOperationSuccess || (current is AdminError && previous is AdminProductsLoaded),
        listener: (context, state) {
           if (state is AdminOperationSuccess) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
           } else if (state is AdminError) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
           }
        },
        buildWhen: (previous, current) => current is AdminProductsLoaded || current is AdminLoading || current is AdminError,
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminError) {
            return Center(child: Text(state.message));
          }
          if (state is AdminProductsLoaded) {
            final products = state.products;
            if (products.isEmpty) {
              return const Center(child: Text('No products found.'));
            }
            return RefreshIndicator(
              onRefresh: () => context.read<AdminCubit>().loadAllProducts(),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: products.length + (state.hasReachedMax ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index == products.length) {
                    return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                  }
                  final product = products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: product.images.isNotEmpty
                            ? CustomImageView(imageUrl: product.images.first, fit: BoxFit.cover)
                            : const Icon(Icons.image),
                      ),
                      title: Text(product.name, style: TextStyle(
                        decoration: product.isActive ? null : TextDecoration.lineThrough,
                        color: product.isActive ? Colors.black : Colors.grey,
                      )),
                      subtitle: Text('\$${product.basePrice.toStringAsFixed(2)} | Stock: ${product.stock}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: product.isActive,
                            onChanged: (val) {
                              context.read<AdminCubit>().toggleProductStatus(product);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              context.push('/admin/products/add_edit', extra: product);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
