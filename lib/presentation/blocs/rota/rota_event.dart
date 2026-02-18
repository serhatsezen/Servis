import 'package:equatable/equatable.dart';
import '../../../data/models/rota_model.dart';
import '../../../data/models/servis_model.dart';

abstract class RotaEvent extends Equatable {
  const RotaEvent();

  @override
  List<Object?> get props => [];
}

class RotaYuklendi extends RotaEvent {
  final String servisId;

  const RotaYuklendi(this.servisId);

  @override
  List<Object?> get props => [servisId];
}

class RotaGuncellendi extends RotaEvent {
  final RotaModel? rota;

  const RotaGuncellendi(this.rota);

  @override
  List<Object?> get props => [rota];
}

class RotaOptimizeEdildi extends RotaEvent {
  final String servisId;
  final KonumModel baslangic;
  final List<KonumModel> duraklar;
  final List<String> personelIds;

  const RotaOptimizeEdildi({
    required this.servisId,
    required this.baslangic,
    required this.duraklar,
    required this.personelIds,
  });

  @override
  List<Object?> get props => [servisId, baslangic, duraklar, personelIds];
}
