import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/servis_repository.dart';
import '../data/repositories/personel_repository.dart';
import '../data/repositories/rota_repository.dart';
import '../data/repositories/konum_repository.dart';
import '../data/repositories/directions_repository.dart';
import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/auth/auth_event.dart';
import '../presentation/blocs/auth/auth_state.dart';
import '../presentation/blocs/servis/servis_bloc.dart';
import '../presentation/blocs/servis/servis_event.dart';
import '../presentation/blocs/personel/personel_bloc.dart';
import '../presentation/blocs/rota/rota_bloc.dart';
import '../presentation/blocs/konum/konum_bloc.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/admin/admin_home_screen.dart';
import '../presentation/screens/driver/driver_home_screen.dart';
import '../presentation/screens/personnel/personnel_home_screen.dart';

class ServisTakipApp extends StatelessWidget {
  const ServisTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Repository'leri oluştur
    final authRepository = AuthRepository();
    final servisRepository = ServisRepository();
    final personelRepository = PersonelRepository();
    final rotaRepository = RotaRepository();
    final konumRepository = KonumRepository();
    final directionsRepository = DirectionsRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: servisRepository),
        RepositoryProvider.value(value: personelRepository),
        RepositoryProvider.value(value: rotaRepository),
        RepositoryProvider.value(value: konumRepository),
        RepositoryProvider.value(value: directionsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: authRepository)
              ..add(const AuthCheckRequested()),
          ),
          BlocProvider(
            create: (_) =>
                ServisBloc(servisRepository: servisRepository)
                  ..add(const ServislerYuklendi()),
          ),
          BlocProvider(
            create: (_) => PersonelBloc(
              personelRepository: personelRepository,
              servisRepository: servisRepository,
            ),
          ),
          BlocProvider(
            create: (_) => RotaBloc(
              rotaRepository: rotaRepository,
              directionsRepository: directionsRepository,
            ),
          ),
          BlocProvider(
            create: (_) => KonumBloc(
              konumRepository: konumRepository,
              directionsRepository: directionsRepository,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Servis Takip',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading || state is AuthInitial) {
                return const _SplashScreen();
              }

              if (state is AuthAuthenticated) {
                final personel = state.personel;

                // Role göre ekran yönlendirme
                if (personel.isAdmin) {
                  return AdminHomeScreen(admin: personel);
                } else if (personel.isSofor) {
                  return DriverHomeScreen(sofor: personel);
                } else {
                  return PersonnelHomeScreen(personel: personel);
                }
              }

              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus,
              size: 80,
              color: Color(0xFF1565C0),
            ),
            SizedBox(height: 24),
            Text(
              'Servis Takip',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
