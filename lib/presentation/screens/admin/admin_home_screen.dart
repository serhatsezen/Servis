import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/personel_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/servis/servis_bloc.dart';
import '../../blocs/servis/servis_event.dart';
import '../../blocs/servis/servis_state.dart';
import 'servis_form_screen.dart';
import 'servis_detail_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final PersonelModel admin;

  const AdminHomeScreen({super.key, required this.admin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hoşgeldin kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1565C0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldin, ${admin.adSoyad}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Servis yönetim paneli',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Servis listesi
          Expanded(
            child: BlocBuilder<ServisBloc, ServisState>(
              builder: (context, state) {
                if (state is ServisLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ServisError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<ServisBloc>()
                              .add(const ServislerYuklendi()),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ServisLoaded) {
                  if (state.servisler.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_bus_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Henüz servis eklenmemiş',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '+ butonuna tıklayarak yeni servis ekleyin',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
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
                          leading: CircleAvatar(
                            backgroundColor: servis.aktifMi
                                ? Colors.green
                                : Colors.grey,
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            servis.plaka,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(servis.rotaAciklama),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${servis.personelListesi.length} personel',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: servis.aktifMi
                                          ? Colors.green[50]
                                          : Colors.grey[100],
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      servis.aktifMi
                                          ? 'Aktif'
                                          : 'Pasif',
                                      style: TextStyle(
                                        color: servis.aktifMi
                                            ? Colors.green
                                            : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ServisDetailScreen(servis: servis),
                              ),
                            );
                          },
                        ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ServisFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
