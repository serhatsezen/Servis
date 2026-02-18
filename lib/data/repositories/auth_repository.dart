import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/personel_model.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<PersonelModel> girisYap({
    required String email,
    required String sifre,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: sifre,
    );
    final userId = credential.user!.uid;
    final doc = await _firestore
        .collection(AppConstants.personellerCollection)
        .doc(userId)
        .get();

    if (!doc.exists) {
      throw FirebaseException('Kullanıcı profili bulunamadı.');
    }

    return PersonelModel.fromFirestore(doc);
  }

  Future<PersonelModel> kayitOl({
    required String email,
    required String sifre,
    required String adSoyad,
    required String rol,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: sifre,
    );

    final userId = credential.user!.uid;
    final personel = PersonelModel(
      id: userId,
      adSoyad: adSoyad,
      katilimDurumu: true,
      email: email,
      rol: rol,
    );

    await _firestore
        .collection(AppConstants.personellerCollection)
        .doc(userId)
        .set(personel.toMap());

    return personel;
  }

  Future<PersonelModel?> getCurrentPersonel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(AppConstants.personellerCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return PersonelModel.fromFirestore(doc);
  }

  Future<void> cikisYap() async {
    await _auth.signOut();
  }

  Future<void> sifreSifirla(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
