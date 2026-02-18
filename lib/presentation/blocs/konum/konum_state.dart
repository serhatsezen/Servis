import 'package:equatable/equatable.dart';
import '../../../data/models/servis_model.dart';

abstract class KonumState extends Equatable {
  const KonumState();

  @override
  List<Object?> get props => [];
}

class KonumInitial extends KonumState {
  const KonumInitial();
}

class KonumLoading extends KonumState {
  const KonumLoading();
}

/// Şoför: konum paylaşılıyor
class KonumPaylasiliyor extends KonumState {
  final KonumModel mevcutKonum;

  const KonumPaylasiliyor({required this.mevcutKonum});

  @override
  List<Object?> get props => [mevcutKonum];
}

/// Personel: servis konumu takip ediliyor
class ServisKonumuTakipEdiliyor extends KonumState {
  final KonumModel servisKonumu;
  final int? kalanSureDakika;

  const ServisKonumuTakipEdiliyor({
    required this.servisKonumu,
    this.kalanSureDakika,
  });

  @override
  List<Object?> get props => [servisKonumu, kalanSureDakika];
}

class KonumPaylasimDurduruldu extends KonumState {
  const KonumPaylasimDurduruldu();
}

class KonumHatasi extends KonumState {
  final String message;

  const KonumHatasi(this.message);

  @override
  List<Object?> get props => [message];
}
