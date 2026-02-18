import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:servis_takip/data/models/personel_model.dart';
import 'package:servis_takip/data/repositories/auth_repository.dart';
import 'package:servis_takip/presentation/blocs/auth/auth_bloc.dart';
import 'package:servis_takip/presentation/blocs/auth/auth_event.dart';
import 'package:servis_takip/presentation/blocs/auth/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('AuthBloc', () {
    const testPersonel = PersonelModel(
      id: 'test-id',
      adSoyad: 'Test Kullanıcı',
      katilimDurumu: true,
      email: 'test@test.com',
      rol: 'personel',
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login is successful',
      build: () {
        when(() => mockAuthRepository.girisYap(
              email: any(named: 'email'),
              sifre: any(named: 'sifre'),
            )).thenAnswer((_) async => testPersonel);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 'test@test.com', sifre: '123456'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthAuthenticated(personel: testPersonel),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockAuthRepository.girisYap(
              email: any(named: 'email'),
              sifre: any(named: 'sifre'),
            )).thenThrow(Exception('user-not-found'));
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
            email: 'wrong@test.com', sifre: 'wrong'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Kullanıcı bulunamadı.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when check finds user',
      build: () {
        when(() => mockAuthRepository.getCurrentPersonel())
            .thenAnswer((_) async => testPersonel);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthAuthenticated(personel: testPersonel),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when logout is requested',
      build: () {
        when(() => mockAuthRepository.cikisYap())
            .thenAnswer((_) async {});
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when registration succeeds',
      build: () {
        when(() => mockAuthRepository.kayitOl(
              email: any(named: 'email'),
              sifre: any(named: 'sifre'),
              adSoyad: any(named: 'adSoyad'),
              rol: any(named: 'rol'),
            )).thenAnswer((_) async => testPersonel);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          email: 'test@test.com',
          sifre: '123456',
          adSoyad: 'Test Kullanıcı',
          rol: 'personel',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthAuthenticated(personel: testPersonel),
      ],
    );
  });
}
