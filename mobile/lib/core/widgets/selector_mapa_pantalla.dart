import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SelectorMapaPantalla extends StatefulWidget {
  final LatLng? puntoInicial;

  const SelectorMapaPantalla({super.key, this.puntoInicial});

  @override
  State<SelectorMapaPantalla> createState() => _SelectorMapaPantallaState();
}

class _SelectorMapaPantallaState extends State<SelectorMapaPantalla> {
  static const _centroCochabamba = LatLng(-17.3895, -66.1568);

  late LatLng _puntoSeleccionado;

  @override
  void initState() {
    super.initState();
    _puntoSeleccionado = widget.puntoInicial ?? _centroCochabamba;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_puntoSeleccionado),
            child: const Text('Confirmar'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _puntoSeleccionado,
              initialZoom: 15,
              onTap: (_, punto) => setState(() => _puntoSeleccionado = punto),
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
                    point: _puntoSeleccionado,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Text(
                  'Lat: ${_puntoSeleccionado.latitude.toStringAsFixed(5)}'
                  '   Lng: ${_puntoSeleccionado.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
