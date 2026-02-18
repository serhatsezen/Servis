import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/servis_model.dart';
import '../../blocs/personel/personel_bloc.dart';
import '../../blocs/personel/personel_event.dart';
import '../../blocs/personel/personel_state.dart';

class BinisNoktasiScreen extends StatefulWidget {
  final String personelId;
  final KonumModel? mevcutKonum;

  const BinisNoktasiScreen({
    super.key,
    required this.personelId,
    this.mevcutKonum,
  });

  @override
  State<BinisNoktasiScreen> createState() => _BinisNoktasiScreenState();
}

class _BinisNoktasiScreenState extends State<BinisNoktasiScreen> {
  GoogleMapController? _mapController;
  LatLng? _secilenKonum;

  @override
  void initState() {
    super.initState();
    if (widget.mevcutKonum != null) {
      _secilenKonum = LatLng(
        widget.mevcutKonum!.lat,
        widget.mevcutKonum!.lng,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = _secilenKonum ??
        const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biniş Noktası Seç'),
        actions: [
          if (_secilenKonum != null)
            TextButton(
              onPressed: _kaydet,
              child: const Text(
                'Kaydet',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
      body: BlocListener<PersonelBloc, PersonelState>(
        listener: (context, state) {
          if (state is PersonelOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: (latLng) {
                setState(() {
                  _secilenKonum = latLng;
                });
              },
              markers: _secilenKonum != null
                  ? {
                      Marker(
                        markerId: const MarkerId('binis_noktasi'),
                        position: _secilenKonum!,
                        infoWindow:
                            const InfoWindow(title: 'Biniş Noktası'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen),
                      ),
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),

            // Alt bilgi çubuğu
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_secilenKonum == null)
                      const Text(
                        'Haritaya tıklayarak biniş noktanızı seçin',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    else
                      Text(
                        'Konum: ${_secilenKonum!.latitude.toStringAsFixed(5)}, '
                        '${_secilenKonum!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _secilenKonum != null ? _kaydet : null,
                        child: const Text('Biniş Noktasını Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _kaydet() {
    if (_secilenKonum == null) return;
    context.read<PersonelBloc>().add(
          BinisNoktasiGuncellendi(
            personelId: widget.personelId,
            konum: KonumModel(
              lat: _secilenKonum!.latitude,
              lng: _secilenKonum!.longitude,
            ),
          ),
        );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
