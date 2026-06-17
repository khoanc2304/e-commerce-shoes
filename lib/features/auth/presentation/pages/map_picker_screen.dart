import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerResult {
  final String fullAddress;
  final String city;
  final String district;
  final String ward;
  final double latitude;
  final double longitude;

  MapPickerResult({
    required this.fullAddress,
    required this.city,
    required this.district,
    required this.ward,
    required this.latitude,
    required this.longitude,
  });
}

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({Key? key, this.initialLat, this.initialLng}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(21.028511, 105.804817); // Hanoi by default
  bool _isLoading = false;
  String _currentAddress = "Move pin to select location";
  Placemark? _currentPlacemark;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentPosition = LatLng(widget.initialLat!, widget.initialLng!);
      _updateAddress(_currentPosition);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      _mapController.move(_currentPosition, 15.0);
      
      await _updateAddress(_currentPosition);
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    setState(() {
      _isLoading = true;
      _currentAddress = "Loading address...";
    });
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentPlacemark = place;
        
        // Construct full address safely
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
        
        setState(() {
          _currentAddress = addressParts.isEmpty ? "Unknown location" : addressParts.join(', ');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Could not load address details";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 15.0,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture && position.center != null) {
                        _currentPosition = position.center!;
                      }
                    },
                    onMapEvent: (MapEvent event) {
                      if (event is MapEventMoveEnd) {
                        _updateAddress(_currentPosition);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.project_prm93',
                    ),
                  ],
                ),
                // Center Pin Icon
                const Positioned(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40.0), // Adjust for pin pointing
                    child: Icon(
                      Icons.location_on,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                ),
                // Custom loading indicator for reverse geocoding
                if (_isLoading)
                  const Positioned(
                    top: 16,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text("Loading address..."),
                          ],
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Selected Address",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentAddress,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading || _currentPlacemark == null
                      ? null
                      : () {
                          final result = MapPickerResult(
                            fullAddress: _currentAddress,
                            city: _currentPlacemark?.administrativeArea ?? _currentPlacemark?.locality ?? '',
                            district: _currentPlacemark?.subLocality ?? _currentPlacemark?.locality ?? '',
                            ward: _currentPlacemark?.thoroughfare ?? _currentPlacemark?.subThoroughfare ?? '',
                            latitude: _currentPosition.latitude,
                            longitude: _currentPosition.longitude,
                          );
                          Navigator.pop(context, result);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Confirm Location"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
