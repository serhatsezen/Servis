import 'package:equatable/equatable.dart';
import '../../../data/models/servis_model.dart';

abstract class KonumEvent extends Equatable {
  const KonumEvent();

  @override
  List<Object?> get props => [];
}

/// Şoför: konum paylaşımını başlat
class KonumPaylasimBaslat extends KonumEvent {
  final String servisId;

  const KonumPaylasimBaslat(this.servisId);

  @override
  List<Object?> get props => [servisId];
}

/// Şoför: konum paylaşımını durdur
class KonumPaylasimDurdur extends KonumEvent {
  final String servisId;

  const KonumPaylasimDurdur(this.servisId);

  @override
  List<Object?> get props => [servisId];
}

/// Personel: servis konumunu takip et
class ServisKonumTakibiBaslat extends KonumEvent {
  final String servisId;

  const ServisKonumTakibiBaslat(this.servisId);

  @override
  List<Object?> get props => [servisId];
}

/// Personel: servis konum takibini durdur
class ServisKonumTakibiDurdur extends KonumEvent {
  const ServisKonumTakibiDurdur();
}

/// Konum güncellemesi alındı
class KonumGuncellendi extends KonumEvent {
  final KonumModel konum;

  const KonumGuncellendi(this.konum);

  @override
  List<Object?> get props => [konum];
}

/// Kalan süre hesaplandı
class KalanSureHesaplandi extends KonumEvent {
  final int dakika;

  const KalanSureHesaplandi(this.dakika);

  @override
  List<Object?> get props => [dakika];
}
