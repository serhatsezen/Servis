import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/servis_model.dart';
import '../../../data/models/personel_model.dart';
import '../../blocs/personel/personel_bloc.dart';
import '../../blocs/personel/personel_event.dart';
import '../../blocs/personel/personel_state.dart';
import '../../blocs/servis/servis_bloc.dart';
import '../../blocs/servis/servis_event.dart';
import 'servis_form_screen.dart';
import '../map/map_screen.dart';

class ServisDetailScreen extends StatefulWidget {
  final ServisModel servis;

  const ServisDetailScreen({super.key, required this.servis});

  @override
  State<ServisDetailScreen> createState() => _ServisDetailScreenState();
}

class _ServisDetailScreenState extends State<ServisDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PersonelBloc>().add(PersonelYuklendi(widget.servis.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.servis.plaka),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ServisFormScreen(servis: widget.servis),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Servis bilgileri kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus,
                            color: Color(0xFF1565C0)),
                        const SizedBox(width: 8),
                        Text(
                          widget.servis.plaka,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: widget.servis.aktifMi,
                          onChanged: (value) {
                            context.read<ServisBloc>().add(
                                  ServisAktiflikDegisti(
                                    servisId: widget.servis.id,
                                    aktifMi: value,
                                  ),
                                );
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text(
                      'Güzergah',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.servis.rotaAciklama),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Harita butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MapScreen(servisId: widget.servis.id),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('Haritada Göster'),
              ),
            ),
            const SizedBox(height: 24),

            // Personel listesi
            const Text(
              'Personeller',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            BlocBuilder<PersonelBloc, PersonelState>(
              builder: (context, state) {
                if (state is PersonelLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PersonelLoaded) {
                  if (state.personeller.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Bu servise henüz personel atanmamış.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: state.personeller.map((personel) {
                      return _PersonelKarti(
                        personel: personel,
                        servisId: widget.servis.id,
                      );
                    }).toList(),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonelKarti extends StatelessWidget {
  final PersonelModel personel;
  final String servisId;

  const _PersonelKarti({
    required this.personel,
    required this.servisId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              personel.katilimDurumu ? Colors.green : Colors.grey,
          child: Text(
            personel.adSoyad.isNotEmpty
                ? personel.adSoyad[0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(personel.adSoyad),
        subtitle: Row(
          children: [
            Icon(
              personel.katilimDurumu
                  ? Icons.check_circle
                  : Icons.cancel,
              size: 14,
              color: personel.katilimDurumu ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              personel.katilimDurumu ? 'Katılacak' : 'Katılmayacak',
              style: TextStyle(
                color:
                    personel.katilimDurumu ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
            if (personel.binisNoktasi != null) ...[
              const SizedBox(width: 12),
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(
                'Nokta belirlenmiş',
                style:
                    TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () {
            context.read<ServisBloc>().add(
                  ServisPersonelCikarildi(
                    servisId: servisId,
                    personelId: personel.id,
                  ),
                );
          },
        ),
      ),
    );
  }
}
