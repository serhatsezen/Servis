import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class KonumModel extends Equatable {
  final double lat;
  final double lng;

  const KonumModel({required this.lat, required this.lng});

  factory KonumModel.fromMap(Map<String, dynamic> map) {
    return KonumModel(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'lat': lat, 'lng': lng};
  }

  @override
  List<Object?> get props => [lat, lng];
}

class ServisModel extends Equatable {
  final String id;
  final String plaka;
  final String rotaAciklama;
  final bool aktifMi;
  final List<String> personelListesi;
  final KonumModel? konum;
  final String? soforId;

  const ServisModel({
    required this.id,
    required this.plaka,
    required this.rotaAciklama,
    required this.aktifMi,
    required this.personelListesi,
    this.konum,
    this.soforId,
  });

  factory ServisModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServisModel(
      id: doc.id,
      plaka: data['plaka'] ?? '',
      rotaAciklama: data['rotaAciklama'] ?? '',
      aktifMi: data['aktifMi'] ?? false,
      personelListesi: List<String>.from(data['personelListesi'] ?? []),
      konum: data['konum'] != null
          ? KonumModel.fromMap(data['konum'] as Map<String, dynamic>)
          : null,
      soforId: data['soforId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plaka': plaka,
      'rotaAciklama': rotaAciklama,
      'aktifMi': aktifMi,
      'personelListesi': personelListesi,
      'konum': konum?.toMap(),
      'soforId': soforId,
    };
  }

  ServisModel copyWith({
    String? id,
    String? plaka,
    String? rotaAciklama,
    bool? aktifMi,
    List<String>? personelListesi,
    KonumModel? konum,
    String? soforId,
  }) {
    return ServisModel(
      id: id ?? this.id,
      plaka: plaka ?? this.plaka,
      rotaAciklama: rotaAciklama ?? this.rotaAciklama,
      aktifMi: aktifMi ?? this.aktifMi,
      personelListesi: personelListesi ?? this.personelListesi,
      konum: konum ?? this.konum,
      soforId: soforId ?? this.soforId,
    );
  }

  @override
  List<Object?> get props =>
      [id, plaka, rotaAciklama, aktifMi, personelListesi, konum, soforId];
}
