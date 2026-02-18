import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final personel = await _authRepository.getCurrentPersonel();
      if (personel != null) {
        emit(AuthAuthenticated(personel: personel));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final personel = await _authRepository.girisYap(
        email: event.email,
        sifre: event.sifre,
      );
      emit(AuthAuthenticated(personel: personel));
    } catch (e) {
      emit(AuthError(message: _parseAuthError(e.toString())));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final personel = await _authRepository.kayitOl(
        email: event.email,
        sifre: event.sifre,
        adSoyad: event.adSoyad,
        rol: event.rol,
      );
      emit(AuthAuthenticated(personel: personel));
    } catch (e) {
      emit(AuthError(message: _parseAuthError(e.toString())));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.cikisYap();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sifreSifirla(event.email);
      emit(const AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(message: _parseAuthError(e.toString())));
    }
  }

  String _parseAuthError(String error) {
    if (error.contains('user-not-found')) {
      return 'Kullanıcı bulunamadı.';
    } else if (error.contains('wrong-password')) {
      return 'Hatalı şifre.';
    } else if (error.contains('email-already-in-use')) {
      return 'Bu e-posta adresi zaten kullanımda.';
    } else if (error.contains('weak-password')) {
      return 'Şifre çok zayıf. En az 6 karakter olmalıdır.';
    } else if (error.contains('invalid-email')) {
      return 'Geçersiz e-posta adresi.';
    } else if (error.contains('too-many-requests')) {
      return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
    }
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
