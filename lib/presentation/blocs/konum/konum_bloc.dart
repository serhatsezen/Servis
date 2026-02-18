import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/servis_model.dart';
import '../../../data/repositories/konum_repository.dart';
import '../../../data/repositories/directions_repository.dart';
import 'konum_event.dart';
import 'konum_state.dart';

class KonumBloc extends Bloc<KonumEvent, KonumState> {
  final KonumRepository _konumRepository;
  final DirectionsRepository _directionsRepository;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<KonumModel?>? _servisKonumSubscription;

  // Personelin biniş noktası (kalan süre hesabı için)
  KonumModel? _personelBinisNoktasi;

  KonumBloc({
    required KonumRepository konumRepository,
    required DirectionsRepository directionsRepository,
  })  : _konumRepository = konumRepository,
        _directionsRepository = directionsRepository,
        super(const KonumInitial()) {
    on<KonumPaylasimBaslat>(_onKonumPaylasimBaslat);
    on<KonumPaylasimDurdur>(_onKonumPaylasimDurdur);
    on<ServisKonumTakibiBaslat>(_onServisKonumTakibiBaslat);
    on<ServisKonumTakibiDurdur>(_onServisKonumTakibiDurdur);
    on<KonumGuncellendi>(_onKonumGuncellendi);
    on<KalanSureHesaplandi>(_onKalanSureHesaplandi);
  }

  void set personelBinisNoktasi(KonumModel? konum) {
    _personelBinisNoktasi = konum;
  }

  /// Şoför: konum paylaşımı başlat
  Future<void> _onKonumPaylasimBaslat(
    KonumPaylasimBaslat event,
    Emitter<KonumState> emit,
  ) async {
    emit(const KonumLoading());

    final izinVar = await _konumRepository.konumIzniKontrol();
    if (!izinVar) {
      emit(const KonumHatasi(
          'Konum izni verilmedi. Lütfen ayarlardan konum iznini etkinleştirin.'));
      return;
    }

    // İlk konum al
    final position = await _konumRepository.anlıkKonumAl();
    await _konumRepository.konumGuncelle(
      event.servisId,
      position.latitude,
      position.longitude,
    );

    emit(KonumPaylasiliyor(
      mevcutKonum: KonumModel(
        lat: position.latitude,
        lng: position.longitude,
      ),
    ));

    // Konum değişikliklerini dinle
    _positionSubscription?.cancel();
    _positionSubscription = _konumRepository.konumTakibi().listen(
      (position) async {
        await _konumRepository.konumGuncelle(
          event.servisId,
          position.latitude,
          position.longitude,
        );
        add(KonumGuncellendi(KonumModel(
          lat: position.latitude,
          lng: position.longitude,
        )));
      },
    );
  }

  /// Şoför: konum paylaşımını durdur
  Future<void> _onKonumPaylasimDurdur(
    KonumPaylasimDurdur event,
    Emitter<KonumState> emit,
  ) async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    await _konumRepository.konumSil(event.servisId);
    emit(const KonumPaylasimDurduruldu());
  }

  /// Personel: servis konumunu takip et
  void _onServisKonumTakibiBaslat(
    ServisKonumTakibiBaslat event,
    Emitter<KonumState> emit,
  ) {
    emit(const KonumLoading());
    _servisKonumSubscription?.cancel();
    _servisKonumSubscription =
        _konumRepository.konumStream(event.servisId).listen(
      (konum) async {
        if (konum != null) {
          add(KonumGuncellendi(konum));

          // Kalan süreyi hesapla
          if (_personelBinisNoktasi != null) {
            try {
              final sure = await _directionsRepository.sureTahmini(
                baslangic: konum,
                bitis: _personelBinisNoktasi!,
              );
              add(KalanSureHesaplandi(sure));
            } catch (_) {
              // Süre hesaplanamadıysa sadece konumu güncelle
            }
          }
        }
      },
    );
  }

  /// Personel: servis konum takibini durdur
  void _onServisKonumTakibiDurdur(
    ServisKonumTakibiDurdur event,
    Emitter<KonumState> emit,
  ) {
    _servisKonumSubscription?.cancel();
    _servisKonumSubscription = null;
    emit(const KonumInitial());
  }

  void _onKonumGuncellendi(
    KonumGuncellendi event,
    Emitter<KonumState> emit,
  ) {
    final currentState = state;
    if (currentState is KonumPaylasiliyor) {
      emit(KonumPaylasiliyor(mevcutKonum: event.konum));
    } else {
      emit(ServisKonumuTakipEdiliyor(
        servisKonumu: event.konum,
        kalanSureDakika:
            currentState is ServisKonumuTakipEdiliyor
                ? currentState.kalanSureDakika
                : null,
      ));
    }
  }

  void _onKalanSureHesaplandi(
    KalanSureHesaplandi event,
    Emitter<KonumState> emit,
  ) {
    final currentState = state;
    if (currentState is ServisKonumuTakipEdiliyor) {
      emit(ServisKonumuTakipEdiliyor(
        servisKonumu: currentState.servisKonumu,
        kalanSureDakika: event.dakika,
      ));
    }
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _servisKonumSubscription?.cancel();
    return super.close();
  }
}
