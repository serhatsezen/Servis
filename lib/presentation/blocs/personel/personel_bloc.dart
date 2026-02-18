import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/personel_model.dart';
import '../../../data/repositories/personel_repository.dart';
import '../../../data/repositories/servis_repository.dart';
import 'personel_event.dart';
import 'personel_state.dart';

class PersonelBloc extends Bloc<PersonelEvent, PersonelState> {
  final PersonelRepository _personelRepository;
  final ServisRepository _servisRepository;
  StreamSubscription<List<PersonelModel>>? _personellerSubscription;

  PersonelBloc({
    required PersonelRepository personelRepository,
    required ServisRepository servisRepository,
  })  : _personelRepository = personelRepository,
        _servisRepository = servisRepository,
        super(const PersonelInitial()) {
    on<PersonelYuklendi>(_onPersonelYuklendi);
    on<PersonellerGuncellendi>(_onPersonellerGuncellendi);
    on<BinisNoktasiGuncellendi>(_onBinisNoktasiGuncellendi);
    on<KatilimDurumuDegisti>(_onKatilimDurumuDegisti);
    on<ServiseKatilimIstegi>(_onServiseKatilimIstegi);
    on<ServistenAyrilmaIstegi>(_onServistenAyrilmaIstegi);
  }

  void _onPersonelYuklendi(
    PersonelYuklendi event,
    Emitter<PersonelState> emit,
  ) {
    emit(const PersonelLoading());
    _personellerSubscription?.cancel();
    _personellerSubscription =
        _personelRepository.getServisPersonelleri(event.servisId).listen(
              (personeller) => add(PersonellerGuncellendi(personeller)),
            );
  }

  void _onPersonellerGuncellendi(
    PersonellerGuncellendi event,
    Emitter<PersonelState> emit,
  ) {
    emit(PersonelLoaded(event.personeller));
  }

  Future<void> _onBinisNoktasiGuncellendi(
    BinisNoktasiGuncellendi event,
    Emitter<PersonelState> emit,
  ) async {
    try {
      await _personelRepository.binisNoktasiGuncelle(
        event.personelId,
        event.konum,
      );
      emit(const PersonelOperationSuccess('Biniş noktası güncellendi.'));
    } catch (e) {
      emit(PersonelError('Biniş noktası güncellenemedi: ${e.toString()}'));
    }
  }

  Future<void> _onKatilimDurumuDegisti(
    KatilimDurumuDegisti event,
    Emitter<PersonelState> emit,
  ) async {
    try {
      await _personelRepository.katilimGuncelle(
        event.personelId,
        event.katilim,
      );
      emit(PersonelOperationSuccess(
        event.katilim
            ? 'Yarın servise katılacaksınız.'
            : 'Yarın servise katılmayacaksınız.',
      ));
    } catch (e) {
      emit(PersonelError(
          'Katılım durumu güncellenemedi: ${e.toString()}'));
    }
  }

  Future<void> _onServiseKatilimIstegi(
    ServiseKatilimIstegi event,
    Emitter<PersonelState> emit,
  ) async {
    try {
      await _personelRepository.serviseKatil(
        event.personelId,
        event.servisId,
      );
      await _servisRepository.personelEkle(
        event.servisId,
        event.personelId,
      );
      emit(const PersonelOperationSuccess('Servise katılım başarılı.'));
    } catch (e) {
      emit(PersonelError('Servise katılım başarısız: ${e.toString()}'));
    }
  }

  Future<void> _onServistenAyrilmaIstegi(
    ServistenAyrilmaIstegi event,
    Emitter<PersonelState> emit,
  ) async {
    try {
      await _personelRepository.servistenAyril(event.personelId);
      emit(const PersonelOperationSuccess('Servisten ayrıldınız.'));
    } catch (e) {
      emit(PersonelError(
          'Servisten ayrılma başarısız: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _personellerSubscription?.cancel();
    return super.close();
  }
}
