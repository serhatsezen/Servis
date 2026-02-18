import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/servis_model.dart';
import '../../../data/repositories/servis_repository.dart';
import 'servis_event.dart';
import 'servis_state.dart';

class ServisBloc extends Bloc<ServisEvent, ServisState> {
  final ServisRepository _servisRepository;
  StreamSubscription<List<ServisModel>>? _servislerSubscription;

  ServisBloc({required ServisRepository servisRepository})
      : _servisRepository = servisRepository,
        super(const ServisInitial()) {
    on<ServislerYuklendi>(_onServislerYuklendi);
    on<ServislerGuncellendi>(_onServislerGuncellendi);
    on<ServisOlusturuldu>(_onServisOlusturuldu);
    on<ServisGuncellendi>(_onServisGuncellendi);
    on<ServisSilindi>(_onServisSilindi);
    on<ServisAktiflikDegisti>(_onServisAktiflikDegisti);
    on<ServisPersonelEklendi>(_onServisPersonelEklendi);
    on<ServisPersonelCikarildi>(_onServisPersonelCikarildi);
    on<ServisSoforAtandi>(_onServisSoforAtandi);
  }

  void _onServislerYuklendi(
    ServislerYuklendi event,
    Emitter<ServisState> emit,
  ) {
    emit(const ServisLoading());
    _servislerSubscription?.cancel();
    _servislerSubscription = _servisRepository.getServisler().listen(
          (servisler) => add(ServislerGuncellendi(servisler)),
        );
  }

  void _onServislerGuncellendi(
    ServislerGuncellendi event,
    Emitter<ServisState> emit,
  ) {
    emit(ServisLoaded(event.servisler));
  }

  Future<void> _onServisOlusturuldu(
    ServisOlusturuldu event,
    Emitter<ServisState> emit,
  ) async {
    try {
      await _servisRepository.servisOlustur(
        plaka: event.plaka,
        rotaAciklama: event.rotaAciklama,
      );
      emit(const ServisOperationSuccess('Servis başarıyla oluşturuldu.'));
      add(const ServislerYuklendi());
    } catch (e) {
      emit(ServisError('Servis oluşturulamadı: ${e.toString()}'));
    }
  }

  Future<void> _onServisGuncellendi(
    ServisGuncellendi event,
    Emitter<ServisState> emit,
  ) async {
    try {
      await _servisRepository.servisGuncelle(event.servis);
      emit(const ServisOperationSuccess('Servis güncellendi.'));
      add(const ServislerYuklendi());
    } catch (e) {
      emit(ServisError('Servis güncellenemedi: ${e.toString()}'));
    }
  }

  Future<void> _onServisSilindi(
    ServisSilindi event,
    Emitter<ServisState> emit,
  ) async {
    try {
      await _servisRepository.servisSil(event.servisId);
      emit(const ServisOperationSuccess('Servis silindi.'));
      add(const ServislerYuklendi());
    } catch (e) {
      emit(ServisError('Servis silinemedi: ${e.toString()}'));
    }
  }

  Future<void> _onServisAktiflikDegisti(
    ServisAktiflikDegisti event,
    Emitter<ServisState> emit,
  ) async {
    try {
      await _servisRepository.aktiflikGuncelle(
          event.servisId, event.aktifMi);
    } catch (e) {
      emit(ServisError('Aktiflik güncellenemedi: ${e.toString()}'));
    }
  }

  Future<void> _onServisPersonelEklendi(
    ServisPersonelEklendi event,
    Emitter<ServisState> emit,
  ) async {
    try {
      await _servisRepository.personelEkle(
          event.servisId, event.personelId);
    } catch (e) {
      emit(ServisError('Personel eklenemedi: ${e.toString()}'));
    }
  }

  Future<void> _onServisPersonelCikarildi(
    ServisPersonelCikarildi event,
    Emitter<ServisState> emit,
  ) async {
    try {
      await _servisRepository.personelCikar(
          event.servisId, event.personelId);
    } catch (e) {
      emit(ServisError('Personel çıkarılamadı: ${e.toString()}'));
    }
  }

  Future<void> _onServisSoforAtandi(
    ServisSoforAtandi event,
    Emitter<ServisState> emit,
  ) async {
    try {
      await _servisRepository.soforAta(event.servisId, event.soforId);
      emit(const ServisOperationSuccess('Şoför atandı.'));
    } catch (e) {
      emit(ServisError('Şoför atanamadı: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _servislerSubscription?.cancel();
    return super.close();
  }
}
