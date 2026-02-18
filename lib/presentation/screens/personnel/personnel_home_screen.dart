import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/personel_model.dart';
import '../../../data/models/servis_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/konum/konum_bloc.dart';
import '../../blocs/konum/konum_event.dart';
import '../../blocs/konum/konum_state.dart';
import '../../blocs/personel/personel_bloc.dart';
import '../../blocs/personel/personel_event.dart';
import '../map/map_screen.dart';
import 'binis_noktasi_screen.dart';
import 'servis_sec_screen.dart';

class PersonnelHomeScreen extends StatefulWidget {
  final PersonelModel personel;

  const PersonnelHomeScreen({super.key, required this.personel});

  @override
  State<PersonnelHomeScreen> createState() => _PersonnelHomeScreenState();
}

class _PersonnelHomeScreenState extends State<PersonnelHomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.personel.servisId != null) {
      // Servis konumunu takip etmeye başla
      context.read<KonumBloc>().add(
            ServisKonumTakibiBaslat(widget.personel.servisId!),
          );
      // Personelin biniş noktasını ayarla
      if (widget.personel.binisNoktasi != null) {
        context.read<KonumBloc>().personelBinisNoktasi =
            widget.personel.binisNoktasi;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servis Takip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
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
                    'Hoş geldin, ${widget.personel.adSoyad}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.personel.servisId != null
                        ? 'Servis atanmış'
                        : 'Henüz bir servise katılmadınız',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            if (widget.personel.servisId == null) ...[
              // Servise katıl butonu
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.directions_bus_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Bir servise katılarak başlayın',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServisSecScreen(
                                personelId: widget.personel.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Servise Katıl'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),

              // Kalan süre kartı
              BlocBuilder<KonumBloc, KonumState>(
                builder: (context, state) {
                  if (state is ServisKonumuTakipEdiliyor &&
                      state.kalanSureDakika != null) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Tahmini Varış Süresi',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${state.kalanSureDakika} dk',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Servis yolda',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is KonumLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.access_time, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Servis henüz hareket etmedi',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Katılım durumu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available,
                            color: Color(0xFF1565C0)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Yarın servise binecek misiniz?',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        Switch(
                          value: widget.personel.katilimDurumu,
                          onChanged: (value) {
                            context.read<PersonelBloc>().add(
                                  KatilimDurumuDegisti(
                                    personelId: widget.personel.id,
                                    katilim: value,
                                  ),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Biniş noktası
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      widget.personel.binisNoktasi != null
                          ? Icons.location_on
                          : Icons.location_off,
                      color: widget.personel.binisNoktasi != null
                          ? Colors.green
                          : Colors.grey,
                    ),
                    title: Text(
                      widget.personel.binisNoktasi != null
                          ? 'Biniş noktası belirlenmiş'
                          : 'Biniş noktası belirlenmemiş',
                    ),
                    subtitle: widget.personel.binisNoktasi != null
                        ? Text(
                            '${widget.personel.binisNoktasi!.lat.toStringAsFixed(4)}, '
                            '${widget.personel.binisNoktasi!.lng.toStringAsFixed(4)}',
                          )
                        : const Text('Haritadan biniş noktanızı seçin'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BinisNoktasiScreen(
                            personelId: widget.personel.id,
                            mevcutKonum: widget.personel.binisNoktasi,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Harita butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapScreen(
                            servisId: widget.personel.servisId!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Servisi Haritada Takip Et'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
