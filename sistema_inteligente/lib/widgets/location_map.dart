import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ubicacion.dart';

/// Mapa con el marcador del vehículo y, opcionalmente, el recorrido
/// de las ubicaciones compartidas desde el teléfono del conductor.
class LocationMap extends StatelessWidget {
  final double latitud;
  final double longitud;
  final String tituloMarcador;
  final List<Ubicacion>? puntos;

  const LocationMap({
    super.key,
    required this.latitud,
    required this.longitud,
    required this.tituloMarcador,
    this.puntos,
  });

  CameraPosition get _camaraInicial {
    final lista = puntos ?? const <Ubicacion>[];
    if (lista.length < 2) {
      return CameraPosition(
        target: LatLng(latitud, longitud),
        zoom: 15,
      );
    }
    double minLat = latitud, maxLat = latitud;
    double minLng = longitud, maxLng = longitud;
    for (final p in lista) {
      if (p.latitud < minLat) minLat = p.latitud;
      if (p.latitud > maxLat) maxLat = p.latitud;
      if (p.longitud < minLng) minLng = p.longitud;
      if (p.longitud > maxLng) maxLng = p.longitud;
    }
    return CameraPosition(
      target: LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
      zoom: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 280,
        child: GoogleMap(
          initialCameraPosition: _camaraInicial,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          compassEnabled: true,
          mapType: MapType.normal,
          markers: {
            Marker(
              markerId: const MarkerId('vehiculo'),
              position: LatLng(latitud, longitud),
              infoWindow: InfoWindow(title: tituloMarcador),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          },
          polylines: puntos == null || puntos!.length < 2
              ? const {}
              : {
                  Polyline(
                    polylineId: const PolylineId('recorrido'),
                    points: puntos!
                        .map((p) => LatLng(p.latitud, p.longitud))
                        .toList(),
                    color: Colors.blue,
                    width: 4,
                  ),
                },
        ),
      ),
    );
  }
}