import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/personel_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/konum/konum_bloc.dart';
import '../../blocs/konum/konum_event.dart';
import '../../blocs/konum/konum_state.dart';
import '../../blocs/servis/servis_bloc.dart';
import '../../blocs/servis/servis_event.dart';
import '../../blocs/servis/servis_state.dart';
import '../map/map_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final PersonelModel sofor;

  const DriverHomeScreen({super.key, required this.sofor});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ServisBloc>().add(const ServislerYuklendi());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şoför Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Hoşgeldin
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1565C0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldin, ${widget.sofor.adSoyad}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Servis şoförü',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Konum Durumu
          BlocBuilder<KonumBloc, KonumState>(
            builder: (context, konumState) {
              final isSharing = konumState is KonumPaylasiliyor;

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSharing ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSharing ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSharing ? Icons.gps_fixed : Icons.gps_off,
                      color: isSharing ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isSharing
                            ? 'Konum paylaşılıyor'
                            : 'Konum paylaşılmıyor',
                        style: TextStyle(
                          color: isSharing
                              ? Colors.green[800]
                              : Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Servis listesi
          Expanded(
            child: BlocBuilder<ServisBloc, ServisState>(
              builder: (context, state) {
                if (state is ServisLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ServisLoaded) {
                  // Şoförün atandığı servisleri göster
                  final soforServisleri = state.servisler
                      .where((s) => s.soforId == widget.sofor.id)
                      .toList();

                  if (soforServisleri.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Henüz bir servise atanmadınız.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: soforServisleri.length,
                    itemBuilder: (context, index) {
                      final servis = soforServisleri[index];
                      return _ServisKarti(
                        servis: servis,
                        sofor: widget.sofor,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServisKarti extends StatelessWidget {
  final dynamic servis;
  final PersonelModel sofor;

  const _ServisKarti({required this.servis, required this.sofor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Text(
                  servis.plaka,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: servis.aktifMi ? Colors.green[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    servis.aktifMi ? 'Aktif' : 'Pasif',
                    style: TextStyle(
                      color: servis.aktifMi ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              servis.rotaAciklama,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '${servis.personelListesi.length} personel',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<KonumBloc, KonumState>(
                    builder: (context, konumState) {
                      final isSharing = konumState is KonumPaylasiliyor;
                      return ElevatedButton.icon(
                        onPressed: () {
                          if (isSharing) {
                            context.read<KonumBloc>().add(
                                  KonumPaylasimDurdur(servis.id),
                                );
                            context.read<ServisBloc>().add(
                                  ServisAktiflikDegisti(
                                    servisId: servis.id,
                                    aktifMi: false,
                                  ),
                                );
                          } else {
                            context.read<KonumBloc>().add(
                                  KonumPaylasimBaslat(servis.id),
                                );
                            context.read<ServisBloc>().add(
                                  ServisAktiflikDegisti(
                                    servisId: servis.id,
                                    aktifMi: true,
                                  ),
                                );
                          }
                        },
                        icon: Icon(
                            isSharing ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          isSharing ? 'Servisi Durdur' : 'Servisi Başlat',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSharing ? Colors.red : Colors.green,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(servisId: servis.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, color: Color(0xFF1565C0)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
