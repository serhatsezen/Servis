import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/personel/personel_bloc.dart';
import '../../blocs/personel/personel_event.dart';
import '../../blocs/personel/personel_state.dart';
import '../../blocs/servis/servis_bloc.dart';
import '../../blocs/servis/servis_state.dart';

class ServisSecScreen extends StatelessWidget {
  final String personelId;

  const ServisSecScreen({super.key, required this.personelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servis Seç'),
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
          } else if (state is PersonelError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ServisBloc, ServisState>(
          builder: (context, state) {
            if (state is ServisLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ServisLoaded) {
              if (state.servisler.isEmpty) {
                return const Center(
                  child: Text(
                    'Mevcut servis bulunamadı.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.servisler.length,
                itemBuilder: (context, index) {
                  final servis = state.servisler[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF1565C0),
                        child: Icon(Icons.directions_bus,
                            color: Colors.white),
                      ),
                      title: Text(
                        servis.plaka,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(servis.rotaAciklama),
                          const SizedBox(height: 4),
                          Text(
                            '${servis.personelListesi.length} personel',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _serviseKatil(context, servis.id);
                        },
                        child: const Text('Katıl'),
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _serviseKatil(BuildContext context, String servisId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Servise Katıl'),
        content: const Text(
            'Bu servise katılmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PersonelBloc>().add(
                    ServiseKatilimIstegi(
                      personelId: personelId,
                      servisId: servisId,
                    ),
                  );
            },
            child: const Text('Katıl'),
          ),
        ],
      ),
    );
  }
}
