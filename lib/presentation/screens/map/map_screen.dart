import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/servis_model.dart';
import '../../blocs/konum/konum_bloc.dart';
import '../../blocs/konum/konum_event.dart';
import '../../blocs/konum/konum_state.dart';
import '../../blocs/rota/rota_bloc.dart';
import '../../blocs/rota/rota_event.dart';
import '../../blocs/rota/rota_state.dart';

class MapScreen extends StatefulWidget {
  final String servisId;

  const MapScreen({super.key, required this.servisId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    context.read<RotaBloc>().add(RotaYuklendi(widget.servisId));
    context.read<KonumBloc>().add(ServisKonumTakibiBaslat(widget.servisId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harita'),
        actions: [
          // Rota bilgi butonu
          BlocBuilder<RotaBloc, RotaState>(
            builder: (context, state) {
              if (state is RotaLoaded) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: const Icon(Icons.access_time, size: 16),
                    label: Text('${state.rota.tahminiSure} dk'),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Harita
          BlocListener<KonumBloc, KonumState>(
            listener: (context, state) {
              if (state is ServisKonumuTakipEdiliyor) {
                _updateServisMarker(state.servisKonumu);
              }
            },
            child: BlocListener<RotaBloc, RotaState>(
              listener: (context, state) {
                if (state is RotaLoaded) {
                  _updateRouteOnMap(state);
                }
              },
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(
                      AppConstants.defaultLat, AppConstants.defaultLng),
                  zoom: AppConstants.defaultZoom,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              ),
            ),
          ),

          // Alt bilgi paneli
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInfoPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return BlocBuilder<KonumBloc, KonumState>(
      builder: (context, konumState) {
        return BlocBuilder<RotaBloc, RotaState>(
          builder: (context, rotaState) {
            String konumDurumu = 'Bekleniyor...';
            String? sureBilgisi;

            if (konumState is ServisKonumuTakipEdiliyor) {
              konumDurumu = 'Servis yolda';
              if (konumState.kalanSureDakika != null) {
                sureBilgisi =
                    'Tahmini varış: ${konumState.kalanSureDakika} dk';
              }
            } else if (konumState is KonumPaylasiliyor) {
              konumDurumu = 'Konum paylaşılıyor';
            } else if (konumState is KonumLoading) {
              konumDurumu = 'Konum alınıyor...';
            }

            int? durakSayisi;
            if (rotaState is RotaLoaded) {
              durakSayisi = rotaState.rota.duraklar.length;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: konumState is ServisKonumuTakipEdiliyor ||
                                  konumState is KonumPaylasiliyor
                              ? Colors.green
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        konumDurumu,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (sureBilgisi != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      sureBilgisi,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                  if (durakSayisi != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$durakSayisi durak',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateServisMarker(KonumModel konum) {
    setState(() {
      _markers.removeWhere(
          (m) => m.markerId == const MarkerId('servis'));
      _markers.add(
        Marker(
          markerId: const MarkerId('servis'),
          position: LatLng(konum.lat, konum.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Servis'),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(konum.lat, konum.lng)),
    );
  }

  void _updateRouteOnMap(RotaLoaded state) {
    setState(() {
      // Durak markerları ekle
      for (final durak in state.rota.duraklar) {
        _markers.add(
          Marker(
            markerId: MarkerId('durak_${durak.sira}'),
            position: LatLng(durak.konum.lat, durak.konum.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: 'Durak ${durak.sira + 1}',
            ),
          ),
        );
      }

      // Polyline (rota çizgisi)
      if (state.rota.polyline != null && state.rota.polyline!.isNotEmpty) {
        final points = _decodePolyline(state.rota.polyline!);
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('rota'),
            points: points,
            color: const Color(0xFF1565C0),
            width: 4,
          ),
        );
      }
    });

    // Tüm markerları kapsayan kamera konumu
    if (_markers.isNotEmpty) {
      final bounds = _calculateBounds(_markers);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    }
  }

  /// Google Encoded Polyline decode
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  LatLngBounds _calculateBounds(Set<Marker> markers) {
    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;

    for (final marker in markers) {
      if (marker.position.latitude < minLat) {
        minLat = marker.position.latitude;
      }
      if (marker.position.latitude > maxLat) {
        maxLat = marker.position.latitude;
      }
      if (marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
