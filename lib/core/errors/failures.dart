import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class DirectionsApiFailure extends Failure {
  const DirectionsApiFailure(super.message);
}
