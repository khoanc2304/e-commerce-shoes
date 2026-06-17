import 'package:flutter/material.dart';
import '../../../product/data/models/store_model.dart';
import '../../../product/data/repositories/store_repository.dart';
import '../widgets/add_store_dialog.dart';

class AdminStoreManagementScreen extends StatefulWidget {
  const AdminStoreManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminStoreManagementScreen> createState() =>
      _AdminStoreManagementScreenState();
}

class _AdminStoreManagementScreenState
    extends State<AdminStoreManagementScreen> {
  final StoreRepository _storeRepository = StoreRepository();

  void _showAddStoreDialog(BuildContext context, {StoreModel? store}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddStoreDialog(
        existingStore: store,
        onSave: (newStore) async {
          if (store == null) {
            await _storeRepository.addStore(newStore);
          } else {
            await _storeRepository.updateStore(newStore);
          }
        },
      ),
    );
  }

  void _deleteStore(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Store'),
        content: const Text('Are you sure you want to delete this store?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storeRepository.deleteStore(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Management'),
      ),
      body: StreamBuilder<List<StoreModel>>(
        stream: _storeRepository.getStoresStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stores = snapshot.data ?? [];

          if (stores.isEmpty) {
            return const Center(
              child: Text(
                'No stores found.\nClick + to add a new store location.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.store, color: Colors.blue),
                  title: Text(store.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(store.address),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(store.phone),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Lat: ${store.latitude}, Lng: ${store.longitude}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddStoreDialog(context, store: store),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteStore(store.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStoreDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
