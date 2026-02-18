import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/servis_model.dart';
import '../../core/constants/app_constants.dart';

class ServisRepository {
  final FirebaseFirestore _firestore;

  ServisRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _servislerRef =>
      _firestore.collection(AppConstants.servislerCollection);

  /// Tüm servisleri getir
  Stream<List<ServisModel>> getServisler() {
    return _servislerRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ServisModel.fromFirestore(doc)).toList());
  }

  /// Tek bir servisi getir
  Future<ServisModel?> getServis(String servisId) async {
    final doc = await _servislerRef.doc(servisId).get();
    if (!doc.exists) return null;
    return ServisModel.fromFirestore(doc);
  }

  /// Yeni servis oluştur
  Future<ServisModel> servisOlustur({
    required String plaka,
    required String rotaAciklama,
  }) async {
    final docRef = await _servislerRef.add(
      ServisModel(
        id: '',
        plaka: plaka,
        rotaAciklama: rotaAciklama,
        aktifMi: false,
        personelListesi: [],
      ).toMap(),
    );

    final doc = await docRef.get();
    return ServisModel.fromFirestore(doc);
  }

  /// Servis güncelle
  Future<void> servisGuncelle(ServisModel servis) async {
    await _servislerRef.doc(servis.id).update(servis.toMap());
  }

  /// Servis sil
  Future<void> servisSil(String servisId) async {
    await _servislerRef.doc(servisId).delete();
  }

  /// Servise personel ekle
  Future<void> personelEkle(String servisId, String personelId) async {
    await _servislerRef.doc(servisId).update({
      'personelListesi': FieldValue.arrayUnion([personelId]),
    });
  }

  /// Servisten personel çıkar
  Future<void> personelCikar(String servisId, String personelId) async {
    await _servislerRef.doc(servisId).update({
      'personelListesi': FieldValue.arrayRemove([personelId]),
    });
  }

  /// Servise şoför ata
  Future<void> soforAta(String servisId, String soforId) async {
    await _servislerRef.doc(servisId).update({'soforId': soforId});
  }

  /// Servis aktiflik durumunu güncelle
  Future<void> aktiflikGuncelle(String servisId, bool aktifMi) async {
    await _servislerRef.doc(servisId).update({'aktifMi': aktifMi});
  }

  /// Servis konumunu güncelle
  Future<void> konumGuncelle(
      String servisId, double lat, double lng) async {
    await _servislerRef.doc(servisId).update({
      'konum': {'lat': lat, 'lng': lng},
    });
  }
}
