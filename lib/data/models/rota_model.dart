import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'servis_model.dart';

class DurakModel extends Equatable {
  final KonumModel konum;
  final String personelId;
  final int sira;

  const DurakModel({
    required this.konum,
    required this.personelId,
    required this.sira,
  });

  factory DurakModel.fromMap(Map<String, dynamic> map) {
    return DurakModel(
      konum: KonumModel.fromMap(map),
      personelId: map['personelId'] ?? '',
      sira: map['sira'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...konum.toMap(),
      'personelId': personelId,
      'sira': sira,
    };
  }

  @override
  List<Object?> get props => [konum, personelId, sira];
}

class RotaModel extends Equatable {
  final String? id;
  final String servisId;
  final List<DurakModel> duraklar;
  final List<String> optimumSira;
  final int tahminiSure;
  final String? polyline;
  final DateTime? olusturulmaTarihi;

  const RotaModel({
    this.id,
    required this.servisId,
    required this.duraklar,
    required this.optimumSira,
    required this.tahminiSure,
    this.polyline,
    this.olusturulmaTarihi,
  });

  factory RotaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RotaModel(
      id: doc.id,
      servisId: data['servisId'] ?? '',
      duraklar: (data['duraklar'] as List<dynamic>?)
              ?.map((d) => DurakModel.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      optimumSira: List<String>.from(data['optimumSira'] ?? []),
      tahminiSure: data['tahminiSure'] ?? 0,
      polyline: data['polyline'],
      olusturulmaTarihi: data['olusturulmaTarihi'] != null
          ? (data['olusturulmaTarihi'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'servisId': servisId,
      'duraklar': duraklar.map((d) => d.toMap()).toList(),
      'optimumSira': optimumSira,
      'tahminiSure': tahminiSure,
      'polyline': polyline,
      'olusturulmaTarihi': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        servisId,
        duraklar,
        optimumSira,
        tahminiSure,
        polyline,
        olusturulmaTarihi,
      ];
}
