import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaMiniatura extends StatelessWidget {
  final double latitud;
  final double longitud;
  final double altura;

  const MapaMiniatura({
    super.key,
    required this.latitud,
    required this.longitud,
    this.altura = 160,
  });

  @override
  Widget build(BuildContext context) {
    final punto = LatLng(latitud, longitud);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: altura,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: punto,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.audiscan.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: punto,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
