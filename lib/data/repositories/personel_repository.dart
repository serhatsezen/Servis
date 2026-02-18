import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/personel_model.dart';
import '../models/servis_model.dart';
import '../../core/constants/app_constants.dart';

class PersonelRepository {
  final FirebaseFirestore _firestore;

  PersonelRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _personellerRef =>
      _firestore.collection(AppConstants.personellerCollection);

  /// Personel bilgisi getir
  Future<PersonelModel?> getPersonel(String personelId) async {
    final doc = await _personellerRef.doc(personelId).get();
    if (!doc.exists) return null;
    return PersonelModel.fromFirestore(doc);
  }

  /// Personel bilgisi stream
  Stream<PersonelModel?> personelStream(String personelId) {
    return _personellerRef.doc(personelId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PersonelModel.fromFirestore(doc);
    });
  }

  /// Servise ait personelleri getir
  Stream<List<PersonelModel>> getServisPersonelleri(String servisId) {
    return _personellerRef
        .where('servisId', isEqualTo: servisId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PersonelModel.fromFirestore(doc))
            .toList());
  }

  /// Katılım yapan personelleri getir
  Stream<List<PersonelModel>> getKatilimciPersoneller(String servisId) {
    return _personellerRef
        .where('servisId', isEqualTo: servisId)
        .where('katilimDurumu', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PersonelModel.fromFirestore(doc))
            .toList());
  }

  /// Biniş noktası güncelle
  Future<void> binisNoktasiGuncelle(
      String personelId, KonumModel konum) async {
    await _personellerRef.doc(personelId).update({
      'binisNoktasi': konum.toMap(),
    });
  }

  /// Katılım durumunu güncelle
  Future<void> katilimGuncelle(String personelId, bool katilim) async {
    await _personellerRef.doc(personelId).update({
      'katilimDurumu': katilim,
    });
  }

  /// Servise katıl
  Future<void> serviseKatil(String personelId, String servisId) async {
    await _personellerRef.doc(personelId).update({
      'servisId': servisId,
    });
  }

  /// Servisten ayrıl
  Future<void> servistenAyril(String personelId) async {
    await _personellerRef.doc(personelId).update({
      'servisId': null,
    });
  }

  /// Personel güncelle
  Future<void> personelGuncelle(PersonelModel personel) async {
    await _personellerRef.doc(personel.id).update(personel.toMap());
  }

  /// Tüm personelleri getir
  Stream<List<PersonelModel>> getTumPersoneller() {
    return _personellerRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PersonelModel.fromFirestore(doc)).toList());
  }
}
