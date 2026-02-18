import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rota_model.dart';
import '../../core/constants/app_constants.dart';

class RotaRepository {
  final FirebaseFirestore _firestore;

  RotaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _rotalarRef =>
      _firestore.collection(AppConstants.rotalarCollection);

  /// Servise ait rotayı getir
  Future<RotaModel?> getServisRotasi(String servisId) async {
    final query = await _rotalarRef
        .where('servisId', isEqualTo: servisId)
        .orderBy('olusturulmaTarihi', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return RotaModel.fromFirestore(query.docs.first);
  }

  /// Servise ait rota stream
  Stream<RotaModel?> servisRotasiStream(String servisId) {
    return _rotalarRef
        .where('servisId', isEqualTo: servisId)
        .orderBy('olusturulmaTarihi', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return RotaModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Rota kaydet
  Future<RotaModel> rotaKaydet(RotaModel rota) async {
    final docRef = await _rotalarRef.add(rota.toMap());
    final doc = await docRef.get();
    return RotaModel.fromFirestore(doc);
  }

  /// Rota güncelle
  Future<void> rotaGuncelle(String rotaId, RotaModel rota) async {
    await _rotalarRef.doc(rotaId).update(rota.toMap());
  }

  /// Servisin eski rotalarını sil
  Future<void> eskiRotalariSil(String servisId) async {
    final query = await _rotalarRef
        .where('servisId', isEqualTo: servisId)
        .orderBy('olusturulmaTarihi', descending: true)
        .get();

    // En son rota hariç hepsini sil
    if (query.docs.length > 1) {
      final batch = _firestore.batch();
      for (var i = 1; i < query.docs.length; i++) {
        batch.delete(query.docs[i].reference);
      }
      await batch.commit();
    }
  }
}
