import 'package:equatable/equatable.dart';
import '../../../data/models/personel_model.dart';
import '../../../data/models/servis_model.dart';

abstract class PersonelEvent extends Equatable {
  const PersonelEvent();

  @override
  List<Object?> get props => [];
}

class PersonelYuklendi extends PersonelEvent {
  final String servisId;

  const PersonelYuklendi(this.servisId);

  @override
  List<Object?> get props => [servisId];
}

class PersonellerGuncellendi extends PersonelEvent {
  final List<PersonelModel> personeller;

  const PersonellerGuncellendi(this.personeller);

  @override
  List<Object?> get props => [personeller];
}

class BinisNoktasiGuncellendi extends PersonelEvent {
  final String personelId;
  final KonumModel konum;

  const BinisNoktasiGuncellendi({
    required this.personelId,
    required this.konum,
  });

  @override
  List<Object?> get props => [personelId, konum];
}

class KatilimDurumuDegisti extends PersonelEvent {
  final String personelId;
  final bool katilim;

  const KatilimDurumuDegisti({
    required this.personelId,
    required this.katilim,
  });

  @override
  List<Object?> get props => [personelId, katilim];
}

class ServiseKatilimIstegi extends PersonelEvent {
  final String personelId;
  final String servisId;

  const ServiseKatilimIstegi({
    required this.personelId,
    required this.servisId,
  });

  @override
  List<Object?> get props => [personelId, servisId];
}

class ServistenAyrilmaIstegi extends PersonelEvent {
  final String personelId;

  const ServistenAyrilmaIstegi({required this.personelId});

  @override
  List<Object?> get props => [personelId];
}
