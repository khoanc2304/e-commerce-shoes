import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/store_model.dart';
import '../../data/repositories/store_repository.dart';

class StoreLocationScreen extends StatefulWidget {
  const StoreLocationScreen({Key? key}) : super(key: key);

  @override
  State<StoreLocationScreen> createState() => _StoreLocationScreenState();
}

class _StoreLocationScreenState extends State<StoreLocationScreen> {
  final MapController _mapController = MapController();
  final StoreRepository _storeRepository = StoreRepository();
  List<StoreModel> _stores = [];

  // Default center if no stores exist
  final LatLng _defaultCenter = const LatLng(21.028511, 105.804817); // Hanoi

  void _moveToStore(StoreModel store) {
    _mapController.move(LatLng(store.latitude, store.longitude), 16.0);
  }

  Future<void> _openGoogleMaps(StoreModel store) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Locations'),
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

          _stores = snapshot.data ?? [];

          final initialCenter = _stores.isNotEmpty
              ? LatLng(_stores.first.latitude, _stores.first.longitude)
              : _defaultCenter;

          return Column(
            children: [
              Expanded(
                flex: 2,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.project_prm93',
                    ),
                    MarkerLayer(
                      markers: _stores.map((store) {
                        return Marker(
                          point: LatLng(store.latitude, store.longitude),
                          width: 80,
                          height: 80,
                          child: GestureDetector(
                            onTap: () {
                              _showStoreDetails(context, store);
                            },
                            child: const Column(
                              children: [
                                Icon(Icons.store, color: Colors.blue, size: 30),
                                Icon(Icons.location_on, color: Colors.red, size: 30),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.white,
                  child: _stores.isEmpty
                      ? const Center(child: Text("No store locations available right now."))
                      : ListView.builder(
                          itemCount: _stores.length,
                          itemBuilder: (context, index) {
                            final store = _stores[index];
                            return ListTile(
                              leading: const Icon(Icons.store, color: Colors.blue),
                              title: Text(store.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${store.address}\nPhone: ${store.phone}'),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.directions, color: Colors.green),
                                onPressed: () => _openGoogleMaps(store),
                              ),
                              onTap: () => _moveToStore(store),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStoreDetails(BuildContext context, StoreModel store) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(store.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(store.address)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(store.phone),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openGoogleMaps(store);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
