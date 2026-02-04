import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLon;

  const MapPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLon,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.initialLat, widget.initialLon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegir ubicación'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: (position, hasGesture) {
                _center = position.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lf.carritodecompras',
              ),
            ],
          ),
          const Center(
            child: Icon(Icons.location_pin, size: 40, color: Colors.red),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, _center);
        },
        icon: const Icon(Icons.check),
        label: const Text('Usar esta ubicación'),
      ),
    );
  }
}
