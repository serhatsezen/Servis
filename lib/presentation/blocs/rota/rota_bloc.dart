import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/rota_model.dart';
import '../../../data/repositories/rota_repository.dart';
import '../../../data/repositories/directions_repository.dart';
import 'rota_event.dart';
import 'rota_state.dart';

class RotaBloc extends Bloc<RotaEvent, RotaState> {
  final RotaRepository _rotaRepository;
  final DirectionsRepository _directionsRepository;
  StreamSubscription<RotaModel?>? _rotaSubscription;

  RotaBloc({
    required RotaRepository rotaRepository,
    required DirectionsRepository directionsRepository,
  })  : _rotaRepository = rotaRepository,
        _directionsRepository = directionsRepository,
        super(const RotaInitial()) {
    on<RotaYuklendi>(_onRotaYuklendi);
    on<RotaGuncellendi>(_onRotaGuncellendi);
    on<RotaOptimizeEdildi>(_onRotaOptimizeEdildi);
  }

  void _onRotaYuklendi(
    RotaYuklendi event,
    Emitter<RotaState> emit,
  ) {
    emit(const RotaLoading());
    _rotaSubscription?.cancel();
    _rotaSubscription =
        _rotaRepository.servisRotasiStream(event.servisId).listen(
      (rota) => add(RotaGuncellendi(rota)),
    );
  }

  void _onRotaGuncellendi(
    RotaGuncellendi event,
    Emitter<RotaState> emit,
  ) {
    if (event.rota != null) {
      emit(RotaLoaded(event.rota!));
    } else {
      emit(const RotaEmpty());
    }
  }

  Future<void> _onRotaOptimizeEdildi(
    RotaOptimizeEdildi event,
    Emitter<RotaState> emit,
  ) async {
    emit(const RotaLoading());
    try {
      // Google Directions API ile optimize edilmiş rota hesapla
      final result = await _directionsRepository.rotaHesapla(
        baslangic: event.baslangic,
        duraklar: event.duraklar,
      );

      // Durakları optimize edilmiş sırada oluştur
      final duraklar = <DurakModel>[];
      for (var i = 0; i < result.optimizedWaypoints.length; i++) {
        final waypointIndex = result.waypointOrder[i];
        duraklar.add(DurakModel(
          konum: result.optimizedWaypoints[i],
          personelId: waypointIndex < event.personelIds.length
              ? event.personelIds[waypointIndex]
              : '',
          sira: i,
        ));
      }

      // Optimum sıra
      final optimumSira =
          result.waypointOrder.map((i) => i.toString()).toList();

      // Rota modeli oluştur
      final rota = RotaModel(
        servisId: event.servisId,
        duraklar: duraklar,
        optimumSira: optimumSira,
        tahminiSure: result.totalDurationMinutes,
        polyline: result.encodedPolyline,
      );

      // Firestore'a kaydet
      final savedRota = await _rotaRepository.rotaKaydet(rota);

      // Eski rotaları temizle
      await _rotaRepository.eskiRotalariSil(event.servisId);

      emit(RotaLoaded(savedRota));
    } catch (e) {
      emit(RotaError('Rota optimizasyonu başarısız: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _rotaSubscription?.cancel();
    return super.close();
  }
}
