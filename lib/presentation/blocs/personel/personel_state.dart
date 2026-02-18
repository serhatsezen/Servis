import 'package:equatable/equatable.dart';
import '../../../data/models/personel_model.dart';

abstract class PersonelState extends Equatable {
  const PersonelState();

  @override
  List<Object?> get props => [];
}

class PersonelInitial extends PersonelState {
  const PersonelInitial();
}

class PersonelLoading extends PersonelState {
  const PersonelLoading();
}

class PersonelLoaded extends PersonelState {
  final List<PersonelModel> personeller;

  const PersonelLoaded(this.personeller);

  @override
  List<Object?> get props => [personeller];
}

class PersonelOperationSuccess extends PersonelState {
  final String message;

  const PersonelOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PersonelError extends PersonelState {
  final String message;

  const PersonelError(this.message);

  @override
  List<Object?> get props => [message];
}
