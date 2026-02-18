import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String sifre;

  const AuthLoginRequested({required this.email, required this.sifre});

  @override
  List<Object?> get props => [email, sifre];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String sifre;
  final String adSoyad;
  final String rol;

  const AuthRegisterRequested({
    required this.email,
    required this.sifre,
    required this.adSoyad,
    required this.rol,
  });

  @override
  List<Object?> get props => [email, sifre, adSoyad, rol];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
