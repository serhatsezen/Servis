import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'servis_model.dart';

class PersonelModel extends Equatable {
  final String id;
  final String adSoyad;
  final String? servisId;
  final KonumModel? binisNoktasi;
  final bool katilimDurumu;
  final String email;
  final String rol; // 'admin', 'sofor', 'personel'

  const PersonelModel({
    required this.id,
    required this.adSoyad,
    this.servisId,
    this.binisNoktasi,
    required this.katilimDurumu,
    required this.email,
    required this.rol,
  });

  factory PersonelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonelModel(
      id: doc.id,
      adSoyad: data['adSoyad'] ?? '',
      servisId: data['servisId'],
      binisNoktasi: data['binisNoktasi'] != null
          ? KonumModel.fromMap(data['binisNoktasi'] as Map<String, dynamic>)
          : null,
      katilimDurumu: data['katilimDurumu'] ?? false,
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'personel',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adSoyad': adSoyad,
      'servisId': servisId,
      'binisNoktasi': binisNoktasi?.toMap(),
      'katilimDurumu': katilimDurumu,
      'email': email,
      'rol': rol,
    };
  }

  PersonelModel copyWith({
    String? id,
    String? adSoyad,
    String? servisId,
    KonumModel? binisNoktasi,
    bool? katilimDurumu,
    String? email,
    String? rol,
  }) {
    return PersonelModel(
      id: id ?? this.id,
      adSoyad: adSoyad ?? this.adSoyad,
      servisId: servisId ?? this.servisId,
      binisNoktasi: binisNoktasi ?? this.binisNoktasi,
      katilimDurumu: katilimDurumu ?? this.katilimDurumu,
      email: email ?? this.email,
      rol: rol ?? this.rol,
    );
  }

  bool get isAdmin => rol == 'admin';
  bool get isSofor => rol == 'sofor';
  bool get isPersonel => rol == 'personel';

  @override
  List<Object?> get props =>
      [id, adSoyad, servisId, binisNoktasi, katilimDurumu, email, rol];
}
