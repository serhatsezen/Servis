import 'package:equatable/equatable.dart';
import '../../../data/models/rota_model.dart';

abstract class RotaState extends Equatable {
  const RotaState();

  @override
  List<Object?> get props => [];
}

class RotaInitial extends RotaState {
  const RotaInitial();
}

class RotaLoading extends RotaState {
  const RotaLoading();
}

class RotaLoaded extends RotaState {
  final RotaModel rota;

  const RotaLoaded(this.rota);

  @override
  List<Object?> get props => [rota];
}

class RotaEmpty extends RotaState {
  const RotaEmpty();
}

class RotaError extends RotaState {
  final String message;

  const RotaError(this.message);

  @override
  List<Object?> get props => [message];
}
