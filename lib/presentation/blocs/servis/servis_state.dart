import 'package:equatable/equatable.dart';
import '../../../data/models/servis_model.dart';

abstract class ServisState extends Equatable {
  const ServisState();

  @override
  List<Object?> get props => [];
}

class ServisInitial extends ServisState {
  const ServisInitial();
}

class ServisLoading extends ServisState {
  const ServisLoading();
}

class ServisLoaded extends ServisState {
  final List<ServisModel> servisler;

  const ServisLoaded(this.servisler);

  @override
  List<Object?> get props => [servisler];
}

class ServisOperationSuccess extends ServisState {
  final String message;

  const ServisOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ServisError extends ServisState {
  final String message;

  const ServisError(this.message);

  @override
  List<Object?> get props => [message];
}
