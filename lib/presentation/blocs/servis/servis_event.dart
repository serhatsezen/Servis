import 'package:equatable/equatable.dart';
import '../../../data/models/servis_model.dart';

abstract class ServisEvent extends Equatable {
  const ServisEvent();

  @override
  List<Object?> get props => [];
}

class ServislerYuklendi extends ServisEvent {
  const ServislerYuklendi();
}

class ServislerGuncellendi extends ServisEvent {
  final List<ServisModel> servisler;

  const ServislerGuncellendi(this.servisler);

  @override
  List<Object?> get props => [servisler];
}

class ServisOlusturuldu extends ServisEvent {
  final String plaka;
  final String rotaAciklama;

  const ServisOlusturuldu({
    required this.plaka,
    required this.rotaAciklama,
  });

  @override
  List<Object?> get props => [plaka, rotaAciklama];
}

class ServisGuncellendi extends ServisEvent {
  final ServisModel servis;

  const ServisGuncellendi(this.servis);

  @override
  List<Object?> get props => [servis];
}

class ServisSilindi extends ServisEvent {
  final String servisId;

  const ServisSilindi(this.servisId);

  @override
  List<Object?> get props => [servisId];
}

class ServisAktiflikDegisti extends ServisEvent {
  final String servisId;
  final bool aktifMi;

  const ServisAktiflikDegisti({
    required this.servisId,
    required this.aktifMi,
  });

  @override
  List<Object?> get props => [servisId, aktifMi];
}

class ServisPersonelEklendi extends ServisEvent {
  final String servisId;
  final String personelId;

  const ServisPersonelEklendi({
    required this.servisId,
    required this.personelId,
  });

  @override
  List<Object?> get props => [servisId, personelId];
}

class ServisPersonelCikarildi extends ServisEvent {
  final String servisId;
  final String personelId;

  const ServisPersonelCikarildi({
    required this.servisId,
    required this.personelId,
  });

  @override
  List<Object?> get props => [servisId, personelId];
}

class ServisSoforAtandi extends ServisEvent {
  final String servisId;
  final String soforId;

  const ServisSoforAtandi({
    required this.servisId,
    required this.soforId,
  });

  @override
  List<Object?> get props => [servisId, soforId];
}
