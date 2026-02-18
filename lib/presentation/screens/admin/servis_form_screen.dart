import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/servis_model.dart';
import '../../blocs/servis/servis_bloc.dart';
import '../../blocs/servis/servis_event.dart';
import '../../blocs/servis/servis_state.dart';

class ServisFormScreen extends StatefulWidget {
  final ServisModel? servis;

  const ServisFormScreen({super.key, this.servis});

  @override
  State<ServisFormScreen> createState() => _ServisFormScreenState();
}

class _ServisFormScreenState extends State<ServisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plakaController;
  late final TextEditingController _rotaAciklamaController;

  bool get _isDuzenleme => widget.servis != null;

  @override
  void initState() {
    super.initState();
    _plakaController =
        TextEditingController(text: widget.servis?.plaka ?? '');
    _rotaAciklamaController =
        TextEditingController(text: widget.servis?.rotaAciklama ?? '');
  }

  @override
  void dispose() {
    _plakaController.dispose();
    _rotaAciklamaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isDuzenleme ? 'Servis Düzenle' : 'Yeni Servis'),
      ),
      body: BlocListener<ServisBloc, ServisState>(
        listener: (context, state) {
          if (state is ServisOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is ServisError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Plaka
                TextFormField(
                  controller: _plakaController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Plaka',
                    prefixIcon: Icon(Icons.directions_bus),
                    hintText: '34 ABC 123',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Plaka gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Rota Açıklaması
                TextFormField(
                  controller: _rotaAciklamaController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Güzergah Açıklaması',
                    prefixIcon: Icon(Icons.route),
                    hintText: 'Örn: Kadıköy - Ataşehir - Ümraniye',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Güzergah açıklaması gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Kaydet Butonu
                ElevatedButton.icon(
                  onPressed: _kaydet,
                  icon: Icon(_isDuzenleme ? Icons.save : Icons.add),
                  label: Text(
                    _isDuzenleme ? 'Güncelle' : 'Servis Oluştur',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                if (_isDuzenleme) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _sil,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Servisi Sil',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _kaydet() {
    if (_formKey.currentState!.validate()) {
      if (_isDuzenleme) {
        final updatedServis = widget.servis!.copyWith(
          plaka: _plakaController.text.trim(),
          rotaAciklama: _rotaAciklamaController.text.trim(),
        );
        context
            .read<ServisBloc>()
            .add(ServisGuncellendi(updatedServis));
      } else {
        context.read<ServisBloc>().add(ServisOlusturuldu(
              plaka: _plakaController.text.trim(),
              rotaAciklama: _rotaAciklamaController.text.trim(),
            ));
      }
    }
  }

  void _sil() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servis Sil'),
        content: Text(
            '${widget.servis!.plaka} plakalı servisi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<ServisBloc>()
                  .add(ServisSilindi(widget.servis!.id));
              Navigator.pop(this.context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
